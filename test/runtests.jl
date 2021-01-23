using Test

using HalfSpaceTrees

@testset "basic" begin
    x = [Dict("x" => e, "y" => e, "z" => e) for e in [0.5, 0.45, 0.43, 0.44, 0.445, 0.45, 0.0]]
    hst = HalfSpaceTree(ntrees=10, height=3, windowsize=3)
    for e in x[1:3]
        learn!(hst, e)
    end
    @test score(hst, x[end - 1]) < 0.5
    @test score(hst, x[end]) > 0.5
    @test score(hst, Dict("x" => 0.0, "y" => 0.0)) > 0.5
    @test score(hst, Dict("a" => 0.0, "b" => 0.0)) > 0.5
end

@testset "edge cases" begin
    @test_throws ArgumentError HalfSpaceTree(ntrees=0)
    @test_throws ArgumentError HalfSpaceTree(height=0)
    @test_throws ArgumentError HalfSpaceTree(windowsize=0)
end