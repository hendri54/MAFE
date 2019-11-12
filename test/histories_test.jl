module HistoryTest

using MAFE
using Test
using DataFrames

@testset "Migration Histories" begin
    ctry = Ghana;
    df = read_migration_file(ctry);

    id = "G0003001";
    mh = make_migration_history(id, df);
    @test n_spells(mh) == 0

    id = "G0016001";
    mh = make_migration_history(id, df);
    @test n_spells(mh) == 2
    mig1 = get_spell(mh, 1);
    @test mig1.startYear == 1981
    @test mig1.endYear == 1984
    @test mig1.ctry == 99338

    @test find_country(mh, mig1.startYear, mig1.endYear) == mig1.ctry
    @test find_country(mh, 1940, 1950) == MAFE.homeCountry
    @test find_country(mh, 2000, 2005) == MAFE.homeCountry
    @test find_country(mh, 1980, 1984) == MAFE.unknownCountry
end

@testset "Job histories" begin
    ctry = Ghana;
    df = read_activity_file(ctry);

    id = "G0003001";
    jh = make_job_history(id, df);
    @test n_spells(jh) == 1
    job1 = get_spell(jh, 1);
    @test job1.startYear == 2008

    # Person with multiple spells
    id = "G0008001";
    jh = make_job_history(id, df);
    @test n_spells(jh) == 2
    job1 = get_spell(jh, 2);
    @test job1.startYear == 2003
end

end