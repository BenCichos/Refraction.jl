module Refraction

@doc let
    path = pkgdir(@__MODULE__, "README.md")
    include_dependency(path)
    read(path, String)
end Refraction

using JLD2
using ZipFile
using YAML: load_file
using Downloads: download
using DelimitedFiles: readdlm

import Base: show

const RI_DATA_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_data.jld2")
const RI_LIBRARY_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_library.jld2")
const RI_DATABASE_PATH = pkgdir(@__MODULE__, "database")
const RI_DATABASE_DOWNLOAD_PATH = pkgdir(@__MODULE__, "database.zip")
const CURRENT_DATABASE_URL = "https://refractiveindex.info/download/database/rii-database-2023-10-04.zip"

include("materialdata.jl")

include("constant.jl")
include("formula.jl")
include("table.jl")

include("material.jl")
include("update_cache.jl")
include_dependency(RI_DATA_PATH)
include_dependency(RI_LIBRARY_PATH)

export Material, findmaterial
export NULL_MATERIAL, isnullmaterial
export dispersion, extinction, transmittance

function __init__()
    ccall(:jl_generating_output, Cint, ()) == 1 && return nothing
    (ispath(RI_DATA_PATH) && ispath(RI_LIBRARY_PATH)) && return
    @info "Downloading refractive index info database and initializing cache..."
    update_cache(CURRENT_DATABASE_URL)
    return
end

end
