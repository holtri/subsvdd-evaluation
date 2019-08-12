using StatsBase

function random_subspaces(n_subspaces, min_dim = 1, max_dim = 2; min_ss_size = 2, max_ss_size=2)
    @assert min_dim < max_dim && min_dim >= 1
    @assert min_ss_size <= max_ss_size && min_ss_size >=2
    @assert max_ss_size <= max_dim - min_dim + 1

    max_possible_subspaces = sum([binomial(max_dim - min_dim + 1, k) for k in min_ss_size:max_ss_size])
    n_subspaces > max_possible_subspaces && error("Maximum number subspaces within the specification (min/max dim and ss_size) is $max_possible_subspaces,
        but method is called with n_subspaces = $n_subspaces.")
    subspaces = Set{Vector{Int}}()
    while length(subspaces) < n_subspaces
        subspace_size = rand(min_ss_size:max_ss_size)
        push!(subspaces, sort(sample(min_dim:max_dim, subspace_size; replace=false), rev=false))
    end
    return [s for s in subspaces]
end

function generate_randsub_from_data(n::Int; kwargs...)
    (data::Array{Float64, 2}) -> random_subspaces(n, 1, size(data, 1); kwargs...)
end
