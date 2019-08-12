remove_and_overwrite = true
validate_package_version = true

JULIA_ENV = joinpath(@__DIR__, "..", "..")
data_root = joinpath(@__DIR__, "..", "..", "data")
data_input_root = joinpath(data_root, "input", "processed", "noise")
data_output_root = joinpath(data_root, "output")

worker_list = [("localhost", 1)]

exeflags = `--project="$JULIA_ENV"`
sshflags= `-i ~/.ssh/julia-key`

fmt_string = "[{name} | {date} | {level}]: {msg}"
loglevel = "debug"
