using Test

@testset "MAFE" begin
    include("types_test.jl")
    include("stata_files.jl")
    include("histories_test.jl")
end

# --------------