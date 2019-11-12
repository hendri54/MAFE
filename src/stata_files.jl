# Stata Files

## ----------  File reading

function stata_dir(ctry :: Country)
    return joinpath(baseDir, "MAFE_data/$(ctry.name)/Stata");
end

function stata_file_name(ctry:: Country, area :: String)
    return "$(area).dta"
end

function stata_file_path(ctry :: Country, area :: String)
    return joinpath(stata_dir(ctry), stata_file_name(ctry, area))
end

function read_stata_file(ctry :: Country, area :: String)
    return DataFrame(load(stata_file_path(ctry, area)))
end


"""
    $(SIGNATURES)

Read person (general) file and rename variables.
"""
function read_person_file(ctry :: Country)
    # This is one row per person
    df = read_stata_file(ctry, "general");
    rename!(df, :q1 => :sex, :q1a => :birthYear);   
    println("No of persons: $(length(df.ident))");

    # Filter
    validV = (df.birthYear .>= birthYearMin) .& (df.birthYear .<= birthYearMax);
    println("N after age filter: $(sum(validV .== true))")
    vIdxV = findall(validV);
    println("Final N: $(length(vIdxV))");

    return df[vIdxV, [:ident, :sex, :birthYear]]
end


"""
	$(SIGNATURES)

Given a file with spells, clean up and sort.
"""
function clean_spells(df :: DataFrame)
    # Ongoing spells. Use future year as end year
    df.endYear = coalesce.(df.endYear,  2020);

    dropmissing!(df, [:startYear, :endYear],  disallowmissing = true);

    # Types of years are sometimes strange in the Stata files
    df.startYear = convert(Vector{Int}, df.startYear);
    df.endYear = convert(Vector{Int}, df.endYear);

    # Fix a typo for Congo
    df.endYear[df.endYear .== 1695] .= 1965;

    validV = (df.startYear .> 1900)  .&  (df.endYear .< 2050);
    dfOut = df[findall(validV .== true),  :];

    # Sort by start year of spell (for each ident)
    sort!(dfOut, [:ident, :startYear, :endYear]);
    return dfOut
end


"""
	$(SIGNATURES)

Validate start and end years in a DataFrame
"""
function validate_start_end_years(df :: DataFrame)
    isValid = true;
    if !all(df.endYear .>= df.startYear)
        @warn "End years before start years"
        isValid = false;
    end

    nRows = size(df, 1);
    for i1 = 2 : nRows
        currId = df.ident[i1];
        if currId == df.ident[i1-1]
            if df.startYear[i1] < df.endYear[i1-1]
                @warn "$currId: Start year before previous end year"
                isValid = false;
            end                
            if df.startYear[i1] < df.startYear[i1-1]
                @warn "$currId: Start years not increasing"
                isValid = false;
            end                
            if df.endYear[i1] < df.endYear[i1-1]
                @warn "$currId: End years not increasing"
                isValid = false;
            end                
        end
    end

    return isValid
end


"""
	$(SIGNATURES)

Read activity file. Rename variables.
Replace missing end years with interview year.
Missing startYear should indicate a person without any spells.
Activity spells are not consecutive.
"""
function read_activity_file(ctry; skipValidation :: Bool = false)
    df = read_stata_file(ctry, "activity");
    rename!(df, :q401d => :startYear, 
        :q401f => :endYear, 
        :q1a => :birthYear,
        :q408 => :income, 
        :q408_dev => :currency);

    dfOut = clean_spells(df);

    dropmissing!(dfOut, [:income, :currency],  disallowmissing = true);

    validV = (dfOut.income .> 0.0);
    dfOut = dfOut[findall(validV .== true),  :];
    nRows = size(dfOut, 1);
    println("No of valid rows: $nRows")

    if skipValidation
        @assert validate_start_end_years(dfOut)  "Invalid activity file"
    end
    
    return dfOut
end


"""
	$(SIGNATURES)

Read migration file. Rename variables.
Replace missing end years with interview year.
"""
function read_migration_file(ctry; skipValidation :: Bool = false)
    df = read_stata_file(ctry, "migration");
    rename!(df, :q601d => :startYear,  
        :q601f => :endYear,  
        :q1a => :birthYear,
        :q602 => :countryCode,  
        :q606 => :kindOfStay);

    dropmissing!(df, [:kindOfStay, :countryCode],  disallowmissing = true);

    dfOut = clean_spells(df);        

    # Delete <= 1 year spells where kindOfStay != 3 (vactations, transit)
    # This is a little risky, but needed to avoid stays within longer stays
    dfOut.duration = dfOut.endYear .- dfOut.startYear;
    # validV = findall((dfOut.duration .> 1) .| (dfOut.kindOfStay .= 3));
    dropV = (dfOut.duration .< 2) .& (dfOut.kindOfStay .!= 3);

    # This person claims to stay in two places at the same time (invalid history)
    dropV[dfOut.ident .== "N013000"] .= true;

    deleterows!(dfOut, findall(dropV .== true));

    if skipValidation
        @assert validate_start_end_years(dfOut)  "Invalid migration file"
    end

    return dfOut
end


## -----------  Make job histories


"""
    $(SIGNATURES)

Make job histories for all persons. Also collects fixed info, such as schooling.

test this +++++
"""
function make_job_histories(ctry :: Country)
    println("Making job histories for $(ctry.name)");

    dfInd = read_person_file(ctry);
    dfAct = read_activity_file(ctry);
    dfMig = read_migration_file(ctry);

    nInd = length(dfInd.ident);
    println("Number of persons: $nInd")
    phV = Vector{PersonHistory}(undef, nInd);
    for i1 = 1 : nInd
        p = make_person_entry(ctry, i1, dfInd);
        # Make a country history for this person
        mh = make_migration_history(dfInd.ident[i1], dfMig);
        jh = make_job_history(dfInd.ident[i1], dfAct);
        # Merge migration info into job history
        merge_countries_to_jobs!(jh, mh);
        phV[i1] = PersonHistory(p, jh.spellV);
    end

    return phV
end


"""
	$(SIGNATURES)

Make entry for one person from individual (general) file
"""
function make_person_entry(ctry :: Country, 
    i1 :: Int, dfInd :: DataFrame)

    return Person(dfInd.ident[i1],  
        make_gender(dfInd.sex[i1]),
        dfInd.birthYear[i1],
        ctry)
end


"""
	$(SIGNATURES)

Make migration history for one person. Person may not be in the migration file.
Then return empty migration history.
"""
function make_migration_history(ident :: String, dfMig :: DataFrame)
    iMigV = findall(dfMig.ident .== ident);
    nMig = length(iMigV);
    migV = Vector{Migration}(undef, nMig);
    if !isempty(iMigV)
        for i1 = 1 : nMig
            ir = iMigV[i1];
            migV[i1] = Migration(dfMig.startYear[ir], dfMig.endYear[ir], Int(dfMig.countryCode[ir]));
        end
    end
    mh = MigrationHistory(migV);
    return mh
end



"""
	$(SIGNATURES)

Make one person's job history.
Contains each job with its country. Country is still unknown.
All persons have at least one spell in the original files, but not in the filtered ones returned by `read_activity_file`.
"""
function make_job_history(ident :: String, dfAct :: DataFrame)
    # Rows in activity file
    iActV = findall(dfAct.ident .== ident);

    nSpells = length(iActV);
    jobV = Vector{Job}(undef, nSpells);
    if nSpells >= 1
        for j = 1 : nSpells
            iRow = iActV[j];
            jobV[j] = Job(dfAct.startYear[iRow], dfAct.endYear[iRow],  
                -1, dfAct.income[iRow]);

            @assert jobV[j].endYear >= jobV[j].startYear
        end
    end
    return JobHistory(jobV)
end


"""
	$(SIGNATURES)

Find country where a person was in a given year.
Returns MAFE country code for foreign country or 0 for home country.
Return negative for years that span spells.
"""
function find_country(mh :: MigrationHistory, startYear :: Int, endYear :: Int)
    nMig = n_spells(mh);
    if nMig == 0
        return homeCountry
    elseif endYear <= start_year(mh, 1)
        return homeCountry
    elseif startYear >= end_year(mh, nMig)
        return homeCountry
    else
        idx = spell_from_year_range(mh, startYear, endYear);
        if idx < 0
            return unknownCountry;
        else
            return mh.spellV[idx].ctry
        end
    end
end


"""
	$(SIGNATURES)

Merge countries from migration histories into job histories

test this +++++
"""
function merge_countries_to_jobs!(jh :: JobHistory, mh :: MigrationHistory)
    nJobs = n_spells(jh);
    if nJobs > 0
        for iJob = 1 : nJobs
            job = get_spell(jh, iJob);
            job.ctry = find_country(mh, job.startYear, job.endYear);
        end
    end
    return nothing
end

# -------------