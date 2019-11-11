module TypesTest

using MAFE, Test

function make_test_history(nMig)
    if nMig == 0
        return MigrationHistory(Vector{Int}());
    else
        migV = Vector{Migration}(undef, nMig);
        sy = 1970;
        ey = 1973;
        for i1 = 1 : nMig
            migV[i1] = Migration(sy, ey, 90394 + i1);
            sy = ey + 4;
            ey = sy + 3;
        end
        return MigrationHistory(migV)
    end
end


@testset "Types" begin
    mh = make_test_history(0);
    @test n_spells(mh) == 0
    syV, eyV = spell_years(mh);
    @test isempty(syV)
    @test isempty(eyV)
    @test spell_from_year_range(mh, 1970, 1980) == 0

    nMig = 4;
    mh = make_test_history(nMig);
    @test n_spells(mh) == 4
    syV, eyV = spell_years(mh);
    @test length(syV) == length(eyV) == nMig
    @test start_year(mh, 2) == syV[2]
    @test end_year(mh, 1) == eyV[1]

    @test spell_from_year_range(mh, 1940, 1950) == 0
    @test spell_from_year_range(mh, eyV[nMig], eyV[nMig]+2) == nMig + 1
    @test spell_from_year_range(mh, syV[2], eyV[2]) == 2
    @test spell_from_year_range(mh, syV[2] - 1, eyV[2]) < 0
    @test spell_from_year_range(mh, syV[2], eyV[2] + 1) < 0
end

end