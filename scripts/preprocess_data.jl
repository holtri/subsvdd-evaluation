!isempty(ARGS) || error("No config supplied.")
isfile(ARGS[1]) || error("Cannot read '$(ARGS[1])'")
isabspath(ARGS[1]) || error("Please use an absolute path for the config.")
println("Config supplied: '$(ARGS[1])'")
config_file = ARGS[1]
include(config_file)

using MLDataUtils
using Random
using DelimitedFiles
using Distributions

function process_file(input_file, output_file)
    raw = readdlm(input_file, ',')
    num_attributes = length(findall(x -> occursin("@ATTRIBUTE", string(x)), raw[:, 1])) - 2
    id_column = findfirst(x -> occursin("@ATTRIBUTE 'id'", string(x)), raw[:, 1]) - 1
    data_start_row = findlast(x -> x == "@DATA", raw[:, 1]) + 1
    raw[:, end] = map(x -> x == "'yes'" ? :outlier : :inlier, raw[:, end])
    data, labels = raw[data_start_row:end, 1:end .!= id_column], raw[data_start_row:end, end]

    @assert size(data, 2) - 1 == num_attributes
    @assert size(data, 1) == length(labels)
    if length(labels) > MAX_VALUES
        @info "Downsampling from $(length(labels)) to $MAX_VALUES observations."
        p = MAX_VALUES / length(labels)
        (data, labels), _ = stratifiedobs((data, labels), p=p, obsdim=1)
    end
    if ADD_NOISE
        data[:, 1:end-1] += rand(NOISE_DIST, size(data,1), size(data, 2) -1)
        fn, ext = splitext(output_file)
        output_file = "$(fn)_nnoise-mu=$(NOISE_DIST.μ)_s=$(NOISE_DIST.σ)_$(ext)"
    end
    writedlm(output_file, data, ',')
end

Random.seed!(0)
MAX_VALUES = 1000
NOISE_DIST = Normal(0, 0.01)
ADD_NOISE = true

target_versions = r"withoutdupl_norm_05_v0[1-3]"

dataset_dir = normpath(joinpath(data_root, "input", "raw"))
output_path = normpath(joinpath(data_root, "input", "processed"))

if ADD_NOISE
    output_path = joinpath(output_path, "noise")
    @info "Adding noise $(NOISE_DIST)"
else
    output_path = joinpath(output_path, "plain")
end
mkpath(output_path)
@info "Saving processed files to $output_path."

for d in data_dirs
    target_files = filter(x -> occursin(target_versions, x), readdir(joinpath(dataset_dir, d)))
    @assert length(target_files) == 3
    @info "[$(d)] Found $(length(target_files)) files."
    outdir = joinpath(output_path, d)
    isdir(outdir) || mkpath(outdir)
    for f in target_files
        process_file(joinpath(dataset_dir, d, f), joinpath(outdir, f[1:end-5] * ".csv"))
    end
end
