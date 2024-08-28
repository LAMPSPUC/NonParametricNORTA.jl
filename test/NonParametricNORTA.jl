@testset "Function: convert_data" begin
    observations = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    expected = NonParametricNORTA.convert_data(observations)
    @test trunc.(expected[1], digits = 3) == [-1.281, -0.841, -0.524, -0.253, 0.0, 0.253, 0.524, 0.841, 1.281, 4.264]
    @test expected[2].support == observations
    @test expected[2].p == ones(10)./10

    observations = [1, 1, 1, 1, 1, 3, 2, 2, 2, 2]
    expected = NonParametricNORTA.convert_data(observations)
    @test trunc.(expected[1], digits = 3) == [0, 0, 0, 0, 0, 4.264, 1.281, 1.281, 1.281, 1.281]
    @test expected[2].support == [1, 2, 3]
    @test expected[2].p == [0.5, 0.4, 0.1]
end

@testset "Function: reverse_data" begin
    observations = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    transformed_y, non_parametric_distribution = NonParametricNORTA.convert_data(observations)
    expected = NonParametricNORTA.reverse_data(transformed_y, non_parametric_distribution)
    @test trunc.(expected, digits = 3) == observations

    observations = collect(-1000:100:1000)
    transformed_y, non_parametric_distribution = NonParametricNORTA.convert_data(observations)
    expected = NonParametricNORTA.reverse_data(transformed_y, non_parametric_distribution)
    @test trunc.(expected, digits = 3) == observations
end