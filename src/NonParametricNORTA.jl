module NonParametricNORTA

const ROBUST_ROUND = 1e-5

using Distributions, Interpolations, KernelDensity, Statistics, StatsBase

include("transform_data.jl")

export convert_data, reverse_data

"""
convert_data(observations::Vector{Fl}) where Fl

    Returns the NORTA transformed observations and the non parametric distribution of the observations.

    # Arguments
    - `observations::Vector{Fl}`: Vector of data.

    # Returns
    - `get_transformed_observations(non_parametric_distribution, observations)`: NORTA transformed observations.
    - `non_parametric_distribution`: Non parametric distribution of the observations.
"""
function convert_data(observations::Vector{Fl}) where Fl
    all(x -> isa(x, Int), observations) ? observations = convert(Vector{Float64}, observations) : nothing
    non_parametric_distribution = get_discretenonparametric_distribution(observations)
    return get_transformed_observations(non_parametric_distribution, observations), non_parametric_distribution
end

"""
    reverse_data(scenarios::Union{Vector{Fl}, Matrix{Fl}}, non_parametric_distribution::DiscreteNonParametric) where Fl

    Returns the reverse NORTA transformed scenarios.

    # Arguments
    - `scenarios::Union{Vector{Fl}, Matrix{Fl}}`: Scenarios data.
    - `non_parametric_distribution::DiscreteNonParametric`: Non parametric distribution of the observations.

    # Returns
    - `reverse_data(interpolation, normal_cumulative_value, non_parametric_distribution)`: Scenarios data in the original scale.
"""
function reverse_data(scenarios::Union{Vector{Fl}, Matrix{Fl}}, non_parametric_distribution::DiscreteNonParametric) where Fl
    normal_cumulative_value = get_normal_cdf(scenarios)
    interpolation = get_interpolation_function(normal_cumulative_value, non_parametric_distribution)
    return reverse_data(interpolation, normal_cumulative_value, non_parametric_distribution)
end

end # module NORTA
