function Base.show(io::IO, cms::Array{T, 1}) where T <: ConfusionMatrix
    for i in eachindex(cms)
        cm = cms[i]
        println(io, "$i --> TP: $(cm.tp) FP: $(cm.fp) TN: $(cm.tn) FN $(cm.fn) [P = :$(cm.pos_class), N = :$(cm.neg_class)]")
    end
end

function listfiles(path) 
    files = readdir(path)
    res = []
    for f in joinpath.(path, files)
        if isfile(f)
            endswith(f, ".json") && push!(res, f)
        else
            res = vcat(res, listfiles(f))
        end
    end
    return res    
end

findResultFile(path, hash) = filter(x -> occursin(hash, x), listfiles(path))[1]

getResultFromFile(path, hash) = Unmarshal.unmarshal(OneClassActiveLearning.Result, JSON.parsefile(findResultFile(path, hash)))
    
function load(res::Result, iteration::Int; solver = with_optimizer(Gurobi.Optimizer, OutputFlag = 0)) 
    data_file = res.experiment[:data_file]
    data, labels = load_data(data_file)
    
    queries = res.al_history[:query_history].values[1:iteration]
    
    pools = Symbol.(res.experiment[:param][:initial_pools])
    pools[queries] = ifelse.(labels[queries] .== :inlier, :Lin, :Lout)
    
    kernels = eval.(Meta.parse.(res.experiment[:model][:fitted][:kernel]))
    gamma_strategy = FixedGammaStrategy(kernels)
    C_strategy = FixedCStrategy(res.experiment[:model][:fitted][:model_params][:C])
    init_strategy = SVDD.SimpleSubspaceStrategy(gamma_strategy, C_strategy, gamma_scope=Val(:Subspace))

    subspaces = convert.(Vector{Int}, res.experiment[:model][:param][:subspaces])
    
    model = SubSVDD(data, subspaces, pools)
    model.adjust_K = res.experiment[:param][:adjust_K]
        
    v_Lin = res.experiment[:model][:fitted][:model_params][:weight_update_strategy][:v_Lin]
    v_Lout = res.experiment[:model][:fitted][:model_params][:weight_update_strategy][:v_Lout]
        
    model.v[queries] = ifelse.(labels[queries] .== :inlier, v_Lin, v_Lout)
    
    SVDD.initialize!(model, init_strategy) 
    return data, labels, model
end
    
    
#### Subspace Analysis
    
function n_outlying_subspaces(predictions; sorted=true)
    tmp = map(x -> ifelse.(SVDD.classify.(x) .== :outlier, 1, 0), predictions)
    subspace_outliers = foldl((x,y) -> x .+ y, tmp)
    sort(collect(zip(eachindex(subspace_outliers), subspace_outliers)), by = x -> x[2], rev=true)
end
    
function outlying_subspaces(observation_id, predictions, subspaces)
    classifications = SVDD.classify(predictions, Val(:Subspace))
    subspaces[map(x-> x[observation_id], classifications).==:outlier]
end
    
    
### Publication plotting
COLORS = (inlier = :lightblue, outlier = :red)
SHAPES = (inlier = (inlier = :circle, outlier = :pentagon), outlier = (inlier = :cross, outlier = :+))   
    
@recipe function plot_svdd(m::SVDD.SVDDClassifier, labels::Vector{Symbol}; grid_resolution = 100, axis_overhang = 0.2, db_color=:black)
    grid_range, grid_data = OCALPlots.get_grid(extrema(m.data)..., grid_resolution, axis_overhang)
    grid_scores = reshape(SVDD.predict(m, grid_data), grid_resolution, grid_resolution)
    data_class = SVDD.classify.(SVDD.predict(m, m.data))
    title := "Decision Boundary"
    @series begin
        seriestype := :contourf
        seriescolor --> :greens
        levels := range(0, maximum(grid_scores), length=10)
        grid_range, grid_range, grid_scores
    end    

    markeralpha --> 0.8
    markersize --> 5

    for l in [:inlier, :outlier]
        markercolor := COLORS[l]
        for dc in [:inlier, :outlier]
            markershape := SHAPES[dc][l]
            @series begin
                seriestype := :scatter
                label := OCALPlots.get_legend_text(l, dc)
                OCALPlots.split_2d_array(m.data, (labels.==l) .& (data_class .== dc))
            end
       end
    end

    @series begin
        seriestype := :contour
        levels := [0]
        linewidth := 3
        seriescolor := [db_color]
        cbar:= false
        grid_range, grid_range, grid_scores
    end
end
    
    
@recipe function plot_svdd(m::SVDD.SubSVDD, labels::Vector{Symbol}, subspace_idx; grid_resolution = 100, axis_overhang = 0.2, db_color=:black)
    data = m.data[m.subspaces[subspace_idx], :]
    grid_range, grid_data = OCALPlots.get_grid(extrema(data)..., grid_resolution, axis_overhang)
    grid_scores = reshape(SVDD.predict(m, grid_data, subspace_idx), grid_resolution, grid_resolution)
    data_class = SVDD.classify.(SVDD.predict(m, data, subspace_idx))

    title --> "Subspace $(m.subspaces[subspace_idx])"
    @series begin
        seriestype := :contourf
        seriescolor --> :greens
        levels := range(0, maximum(grid_scores), length=10)
        grid_range, grid_range, grid_scores
    end
        
    markeralpha --> 0.8
    markersize --> 5

    for l in [:inlier, :outlier]
        markercolor := COLORS[l]
        for dc in [:inlier, :outlier]
            markershape := SHAPES[dc][l]
            @series begin
                seriestype := :scatter
                label := OCALPlots.get_legend_text(l, dc)
                OCALPlots.split_2d_array(data, (labels.==l) .& (data_class .== dc))
            end
       end
    end

    @series begin
        seriestype := :contour
        levels := [0]
        linewidth := 3
        seriescolor := [db_color]
        cbar:= false
        grid_range, grid_range, grid_scores
    end
end