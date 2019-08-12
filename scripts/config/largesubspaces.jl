include(joinpath(@__DIR__, "config.jl"))
include(joinpath(@__DIR__, "..", "subspace_util.jl"))

using OneClassActiveLearning, SVDD, JuMP, Gurobi, MLKernels

solver = with_optimizer(Gurobi.Optimizer; OutputFlag=0, Threads=1)

data_dirs = ["HeartDisease", "Stamps", "Pima", "Cardiotocography", "SpamBase", "Annthyroid", "PageBlocks"]
data_info = "02-subsvdd-largesubspaces"

classify_precision = SVDD.OPT_PRECISION

### learning scenario ###
initial_pool_strategy = [("Pu", Dict())]
split_strategy = [("Sf", Dict())]

#### models ####
models = [Dict(:type => :SubSVDD,
               :param => Dict{Symbol, Any}(:weight_update_strategy => SVDD.FixedWeightStrategy(10.0, 0.01)))]

init_strategies = [SimpleSubspaceStrategy(SVDD.WangGammaStrategy(solver), FixedCStrategy(0.45), gamma_scope=Val(:Subspace))]

subspace_generators = [generate_randsub_from_data(10; min_ss_size=5, max_ss_size=8),
                       generate_randsub_from_data(20; min_ss_size=5, max_ss_size=8)]

#### oracle ####
oracle_param = Dict{Symbol, Any}(
    :type => PoolOracle,
    :param => Dict{Symbol, Any}()
)

#### query strategies ####
query_strategies = [
    Dict(:type => SubspaceQs{DecisionBoundaryPQs},
           :param => Dict{Symbol, Any}(:scale_fct => min_max_normalize,
                                       :combination_fct => + )),
   Dict(:type => SubspaceQs{HighConfidencePQs},
        :param => Dict{Symbol, Any}(:scale_fct => min_max_normalize,
                                      :combination_fct => + )),
   Dict(:type => SubspaceQs{RandomOutlierPQs},
         :param => Dict{Symbol, Any}(:scale_fct => min_max_normalize,
                                     :combination_fct => + ))]

num_al_iterations = 50
num_resamples_initial_pool = 1
num_resamples_subspaces = 3
data_output_root = joinpath(data_root, "output", "evaluation-part1")
