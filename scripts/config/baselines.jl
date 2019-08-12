include(joinpath(@__DIR__, "config.jl"))
include(joinpath(@__DIR__, "..", "subspace_util.jl"))

using OneClassActiveLearning, SVDD, JuMP, Gurobi, MLKernels

solver = with_optimizer(Gurobi.Optimizer; OutputFlag=0, Threads=1)

data_dirs = ["HeartDisease", "Stamps", "Pima", "Cardiotocography", "SpamBase", "Annthyroid", "PageBlocks"]
data_info = "03-baselines"

### learning scenario ###
initial_pool_strategy = [("Pu", Dict())]
split_strategy = [("Sf", Dict())]
classify_precision = SVDD.OPT_PRECISION

#### models ####

models = [Dict(:type => :SSAD, :param => Dict{Symbol, Any}(:κ => 0.1)),
          Dict(:type => :SVDDneg, :param => Dict{Symbol, Any}())]

init_strategies = [SimpleCombinedStrategy(SVDD.WangGammaStrategy(solver), BoundedTaxErrorEstimate(0.05, 0.02, 0.98))]

subspace_generators = [1]

#### oracle ####
oracle_param = Dict{Symbol, Any}(
    :type => PoolOracle,
    :param => Dict{Symbol, Any}()
)

#### query strategies ####

query_strategies = [
    Dict(:type => :RandomOutlierPQs, :param => Dict{Symbol, Any}()),
    Dict(:type => :HighConfidencePQs, :param => Dict{Symbol, Any}()),
    Dict(:type => :DecisionBoundaryPQs, :param => Dict{Symbol, Any}())]

num_al_iterations = 50
num_resamples_initial_pool = 1
num_resamples_subspaces = 1
data_output_root = joinpath(data_root, "output", "evaluation-part1")
