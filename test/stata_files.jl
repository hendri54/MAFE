module StataTest

using MAFE
using Test
using DataFrames

@testset "Stata files" begin 
    ctry = Ghana;
    @test isdir(MAFE.baseDir)
    @test isdir(MAFE.stata_dir(ctry))
    @test isfile(MAFE.stata_file_path(ctry, "general"))

    df = read_stata_file(ctry, "general");
    @test isa(df, DataFrame)

    df2 = read_person_file(ctry);
    @test isa(df, DataFrame)
    @test all(df2.birthYear .>= MAFE.birthYearMin)

    i1 = 10;
    p = MAFE.make_person_entry(ctry, i1, df2);
    @test p.id == df2.ident[i1]
    @test (df2.sex[i1] == 1) || (p.sex == MAFE.female)

    df3 = read_activity_file(ctry);
    @test length(df3.ident) > 1000
    @test all(df3.endYear .>= df3.startYear)
    id = "G0003001";
    idxV = findall(df3.ident .== id);
    @test length(idxV) == 1

    df4 = read_migration_file(ctry);
    @test length(df4.ident) > 500
    @test all(df4.endYear .>= df4.startYear)
end

end # module
# ----------