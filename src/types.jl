# Types

"""
Gender
"""
@enum Gender male=1 female=2

function make_gender(g :: T) where T <: Integer
    if g == 1
        return male
    elseif g == 2
        return female
    else
        error("Invalid g: $g");
    end
end


"""
Country
"""
abstract type Country end

struct SourceCountry <: Country
    name :: String
    prefix :: String
end

const Congo = SourceCountry("Congo", "rdc");
const Senegal = SourceCountry("Senegal", "sn");
const Ghana = SourceCountry("Ghana", "gh");
# Congo=1 Ghana=2 Senegal=3 Netherlands=4 UK=5

# function is_source_country(ctry :: Country)
#     return Int(ctry) <= 3
# end

# function is_host_country(ctry :: Country)
#     return !is_source_country(ctry)
# end


"""
Person
"""
mutable struct Person
    id :: String
    sex :: Gender
    birthYear :: Int
    birthCountry :: Country
end


# --------------  Spell History

abstract type Spell end
abstract type SpellHistory end

function n_spells(jh :: SpellHistory)
    return length(jh.spellV)
end

function get_spell(mh :: SpellHistory, idx :: T) where T <: Integer
    return mh.spellV[idx]
end

function start_year(mh :: SpellHistory, idx :: Int)
    return mh.spellV[idx].startYear
end

function end_year(mh :: SpellHistory, idx :: Int)
    return mh.spellV[idx].endYear
end

function spell_years(jh :: SpellHistory)
    ns = n_spells(jh);
    syV = Vector{Int}(undef, ns);
    eyV = Vector{Int}(undef, ns);
    if ns > 0
        for i1 = 1 : ns
            syV[i1] = jh.spellV[i1].startYear;
            eyV[i1] = jh.spellV[i1].endYear;
        end
    end
    return syV, eyV
end

"""
	$(SIGNATURES)

Return Migration index that matches a year range.
0 if before first spell. (n+1) if after last spell.
If a spell does not contain the year range: return negative.
"""
function spell_from_year_range(mh :: SpellHistory, year1 :: T, year2 :: T) where T <: Integer
    syV, eyV = spell_years(mh);
    nMig = length(syV);
    if nMig < 1
        return 0
    elseif year1 >= eyV[nMig]
        return nMig + 1
    elseif year2 <= syV[1]
        return 0
    else
        # Interior
        idxV = findall((year1 .>= syV)  .&  (year2 .<= eyV));
        if isempty(idxV) 
            return -1
        else
            @assert length(idxV) == 1  "idxV: $idxV"
            return idxV[1]
        end
    end
end


# -------------  Job history

"""
Job
"""
mutable struct Job <: Spell
    startYear :: Int
    endYear :: Int
    ctry :: Int 
    income :: Float64
    # currency +++++
end


"""
Job history
"""
mutable struct JobHistory <: SpellHistory
    spellV :: Vector{Job}
end




# --------------------  Migration histories

"""
	$(SIGNATURES)

Migration event.
Country code is the Int code from the Migration file.
"""
mutable struct Migration <: Spell
    startYear :: Int
    endYear :: Int
    ctry :: Int
end


"""
	$(SIGNATURES)

Migration history
"""
mutable struct MigrationHistory <: SpellHistory
    spellV :: Vector{Migration}
end


# function n_migrations(mh :: MigrationHistory)
#     return length(mh.migV)
# end


"""
	$(SIGNATURES)

Person histories: Fixed info and spells with jobs
"""
mutable struct PersonHistory <: SpellHistory
    p :: Person
    spellV :: Vector{Job}
end


# --------