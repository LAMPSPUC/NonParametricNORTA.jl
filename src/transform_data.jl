"""
    get_discretenonparametric_distribution(observations::Vector{Fl}) where Fl

    Returns the non parametric distribution of the observations.

    # Arguments
    - `observations::Vector{Fl}`: Vector of data.

    # Returns
    - `non_parametric_distribution`: Non parametric distribution of the observations.

"""
function get_discretenonparametric_distribution(observations::Vector{Fl}) where Fl
    
    observation_count_dict = countmap(observations)
    unique_values = collect(keys(observation_count_dict))
    observation_count = collect(values(observation_count_dict))

    return DiscreteNonParametric(unique_values, observation_count./(sum(observation_count)))
end

"""
    get_transformed_observations(non_parametric_distribution::DiscreteNonParametric, observations::Vector{Fl}) where Fl

    Returns the NORTA transformed observations.

    # Arguments
    - `non_parametric_distribution::DiscreteNonParametric`: Non parametric distribution of the observations.
    - `observations::Vector{Fl}`: Vector of data.

    # Returns
    - `quantile.(Normal(0,1), empirical_cumulative_dist)`: NORTA transformed observations.

"""
function get_transformed_observations(non_parametric_distribution::DiscreteNonParametric, observations::Vector{Fl}) where Fl

    empirical_cumulative_dist = cdf.(non_parametric_distribution, observations)

    #This avoid numerical problems
    empirical_cumulative_dist[findall(i -> i >= 1.0, empirical_cumulative_dist)] .= 1 - ROBUST_ROUND
    empirical_cumulative_dist[findall(i -> i <= 0.0, empirical_cumulative_dist)] .= ROBUST_ROUND
    
    return quantile.(Normal(0,1), empirical_cumulative_dist)
end

"""
    get_normal_cdf(scenarios::Union{Vector{Fl}, Matrix{Fl}}) where Fl

    Returns the normal cumulative distribution of the scenarios.

    # Arguments
    - `scenarios::Union{Vector{Fl}, Matrix{Fl}}`: Scenarios data.

    # Returns
    - `round.(cdf.(Normal(0,1), scenarios), digits = Int64(-floor(log10(abs(ROBUST_ROUND)))))`: normal cumulative distribution of the scenarios.

"""
function get_normal_cdf(scenarios::Union{Vector{Fl}, Matrix{Fl}}) where Fl
    return round.(cdf.(Normal(0,1), scenarios), digits = Int64(-floor(log10(abs(ROBUST_ROUND))))) #round to avoid numerical problems 
end

"""
    get_interpolation_function(normal_cumulative_value::Union{Vector{Fl}, Matrix{Fl}}, non_parametric_distribution::DiscreteNonParametric) where Fl

    Returns the interpolation function of the normal cumulative distribution of the scenarios.

    # Arguments
    - `normal_cumulative_value::Union{Vector{Fl}, Matrix{Fl}}`: Normal cumulative distribution of the scenarios.
    - `non_parametric_distribution::DiscreteNonParametric`: Non parametric distribution of the observations.

    # Returns
    - `linear_interpolation(cdf_range, quantile_range) `: interpolation function of the normal cumulative distribution of the scenarios.

"""
function get_interpolation_function(normal_cumulative_value::Union{Vector{Fl}, Matrix{Fl}}, non_parametric_distribution::DiscreteNonParametric) where Fl
    
    cdf_range = vcat(collect(minimum(normal_cumulative_value):ROBUST_ROUND:maximum(normal_cumulative_value)), [maximum(normal_cumulative_value)])
 
    quantile_range = [quantile(non_parametric_distribution, t) for t in cdf_range]

    Interpolations.deduplicate_knots!(cdf_range)
    Interpolations.deduplicate_knots!(quantile_range)
    return linear_interpolation(cdf_range, quantile_range) 
end

"""
    reverse_data(interpolation::Interpolations.Extrapolation, normal_cumulative_value::Union{Vector{Fl}, Matrix{Fl}}, non_parametric_distribution::DiscreteNonParametric) where Fl

    Returns scenarios data in the original scale.

    # Arguments
    - `interpolation::Interpolations.Extrapolation`: Interpolation function of the normal cumulative distribution of the scenarios.
    - `normal_cumulative_value::Union{Vector{Fl}, Matrix{Fl}}`: Normal cumulative distribution of the scenarios.
    - `non_parametric_distribution::DiscreteNonParametric`: Non parametric distribution of the observations.

    # Returns
    - `reverse_data`: Scenarios data in the original scale.

"""
function reverse_data(interpolation::Interpolations.Extrapolation, normal_cumulative_value::Union{Vector{Fl}, Matrix{Fl}}, non_parametric_distribution::DiscreteNonParametric) where Fl

    reverse_data = zeros(size(normal_cumulative_value))

    valid_indexes  = findall(i -> i > ROBUST_ROUND && i < (1 - ROBUST_ROUND), normal_cumulative_value)

    reverse_data[findall(i -> i >= (1 - ROBUST_ROUND), normal_cumulative_value)]  .= maximum(non_parametric_distribution.support)
    reverse_data[findall(i -> i <= ROBUST_ROUND, normal_cumulative_value)] .= minimum(non_parametric_distribution.support)

    #this is important for the case where there is a number in the scenarios vector that also exist in the original vector returns the original value
    round_cum_probabilities = round.([sum(non_parametric_distribution.p[1:i]) for i in eachindex(non_parametric_distribution.p)], digits=Int64(-floor(log10(abs(ROBUST_ROUND)))))
    round_normal_cumulative = round.(normal_cumulative_value, digits=Int64(-floor(log10(abs(ROBUST_ROUND)))))
    #################################################

    @inbounds for t in valid_indexes
        support_idx = findfirst(i -> i == round_normal_cumulative[t], round_cum_probabilities)
        if !isnothing(support_idx)
            reverse_data[t] = non_parametric_distribution.support[support_idx]
        else
            reverse_data[t] = interpolation(normal_cumulative_value[t])
        end
    end
    
    return reverse_data
end