module Refraction
using Downloads: download
using JLD2
using BasicInterpolators: LinearInterpolator, NoBoundaries
using ZipFile
using YAML: load_file
using DelimitedFiles: readdlm

import Base: getindex, show

const RI_DATA_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_data.jld2")
const RI_LIBRARY_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_library.jld2")
const RI_DATABASE_PATH = pkgdir(@__MODULE__, "database")
const RI_DATABASE_DOWNLOAD_PATH = pkgdir(@__MODULE__, "database.zip")

include("materialdata.jl")
include("material.jl")
include("update_cache.jl")

export Material, findmaterial, NULL_MATERIAL, isnullmaterial, dispersion

function __init__()
    (ispath(RI_DATA_PATH) && ispath(RI_LIBRARY_PATH)) && return
    @info "The local cache does not exist. Commencing creation of local cache..."
    update_cache("https://refractiveindex.info/download/database/rii-database-2023-10-04.zip")
    return
end

end
