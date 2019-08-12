isabspath(ARGS[1]) || error("Please use an absolute path to the config file.")
include(ARGS[1])

using Distributed

@info "Checking packages for $([h for (h,_) in worker_list])."

addprocs([(w, 1) for (w,cpu) in worker_list], sshflags=sshflags, exeflags=exeflags)
@everywhere using Pkg

@everywhere global CUSTOM_PACKAGES = [PackageSpec(url="https://github.com/JuliaOpt/JuMP.jl", rev="v0.19-beta"),
                                      PackageSpec(url="https://github.com/englhardt/SVDD.jl", rev=("subsvdd-update")),
                                      PackageSpec(url="https://github.com/englhardt/OneClassActiveLearning.jl", rev="subsvdd-update"),
                                      PackageSpec(url="https://github.com/holtri/OCALPlots.jl", rev="master")]

@everywhere function update_or_install_custom_packages()
    for spec in CUSTOM_PACKAGES
        @info "Installing $(spec.repo.url) on revision $(spec.repo.rev) on $(gethostname())."
        Pkg.add(spec)
    end
end


@info "Bringing packages up to date..."
@info "instantiate"
# @everywhere update_or_install_custom_packages()
# @everywhere Pkg.instantiate()
for wid in workers()
    # remotecall_fetch(update_or_install_custom_packages, wid)
    remotecall_fetch(Pkg.instantiate, wid)
end
@info "Trigger precompile."
@everywhere using SVDD, OneClassActiveLearning, JuMP
if foldl(==, remotecall_fetch.(Pkg.installed, workers()))
    @error "Package update did not work."
else
    @info "All hosts are up to date."
end
