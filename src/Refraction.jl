module Refraction

@doc let
    path = pkgdir(@__MODULE__, "README.md")
    include_dependency(path)
    read(path, String)
end Refraction

using JLD2
using Pkg.Artifacts
using YAML: load_file
using DelimitedFiles: readdlm

import Base: show

const RI_DATA_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_data.jld2")
const RI_LIBRARY_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_library.jld2")
const RI_DATABASE_VERSION = "refractiveindex.info-database-2024-08-14"
const RI_DATABASE_PATH = joinpath(artifact"refractiveindex.info", RI_DATABASE_VERSION, "database")

include("materialdata.jl")

include("constant.jl")
include("formula.jl")
include("table.jl")

include("material.jl")

export Material, findmaterial
export NULL_MATERIAL, isnullmaterial
export dispersion, extinction, transmittance

include("init_cache.jl")

function __init__()
    (ispath(RI_DATA_PATH) && ispath(RI_LIBRARY_PATH)) && return
    init_cache()
end

end
