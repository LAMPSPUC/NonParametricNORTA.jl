@testset "Function: get_discretenonparametric_distribution" begin
    observations = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    expected = NORTA.get_discretenonparametric_distribution(observations)
    @test expected.support == observations
    @test expected.p == ones(10)./10

    observations = [1, 1, 1, 1, 1, 3, 2, 2, 2, 2]
    expected = NORTA.get_discretenonparametric_distribution(observations)
    @test expected.support == [1, 2, 3]
    @test expected.p == [0.5, 0.4, 0.1]
end

@testset "Function: get_transformed_observations" begin
    observations = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    non_parametric_distribution = NORTA.get_discretenonparametric_distribution(observations)
    expected = NORTA.get_transformed_observations(non_parametric_distribution, observations)
    @test trunc.(expected, digits = 3) == [-1.281, -0.841, -0.524, -0.253, 0.0, 0.253, 0.524, 0.841, 1.281, 4.264]
end

@testset "Function: get_normal_cdf" begin
    scenarios = [-1.281, -0.841, -0.524, -0.253, 0.0, 0.253, 0.524, 0.841, 1.281, 5.612]
    expected = NORTA.get_normal_cdf(scenarios)
    @test round.(expected, digits = 1) == collect(0.1:0.1:1.0)

    scenarios = [1 2 3; 4 5 6]
    expected = NORTA.get_normal_cdf(scenarios)
    @test round.(expected, digits = 3) == [0.841  0.977  0.999; 1.0 1.0 1.0]
end

@testset "Function: get_interpolation_function" begin
    normal_cumulative_value = NORTA.get_normal_cdf([-1.281, -0.841, -0.524, -0.253, 0.0, 0.253, 0.524, 0.841, 1.281, 5.612])
    observations = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    non_parametric_distribution = NORTA.get_discretenonparametric_distribution(observations)
    expected = NORTA.get_interpolation_function(normal_cumulative_value, non_parametric_distribution)
    @test isa(expected, NORTA.Interpolations.Extrapolation)
end

@testset "Function: reverse_data" begin
    observations = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    non_parametric_distribution = NORTA.get_discretenonparametric_distribution(observations)
    transformed_obs = NORTA.get_transformed_observations(non_parametric_distribution, observations)
    normal_cumulative_value = round.(NORTA.get_normal_cdf(transformed_obs), digits = 8)
    interpolation = NORTA.get_interpolation_function(normal_cumulative_value, non_parametric_distribution)
    expected = NORTA.reverse_data(interpolation, normal_cumulative_value, non_parametric_distribution)
    @test trunc.(expected, digits = 3) == observations

    observations = [1, 1, 1, 1, 1, 3, 2, 2, 2, 2]
    non_parametric_distribution = NORTA.get_discretenonparametric_distribution(observations)
    transformed_obs = NORTA.get_transformed_observations(non_parametric_distribution, observations)
    normal_cumulative_value = round.(NORTA.get_normal_cdf(transformed_obs), digits = 8)
    interpolation = NORTA.get_interpolation_function(normal_cumulative_value, non_parametric_distribution)
    expected = NORTA.reverse_data(interpolation, normal_cumulative_value, non_parametric_distribution)
    @test trunc.(expected, digits = 3) == observations
end