module Refractive
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

include("dispersion.jl")

include("material.jl")
export Material, dispersion, findmaterial

include("update_cache.jl")

function __init__()
    (ispath(RI_DATA_PATH) && ispath(RI_LIBRARY_PATH)) && return
    @info "The local cache does not exist. Commencing initialisation of local cache..."
    update_cache("https://refractiveindex.info/download/database/rii-database-2023-10-04.zip")
    return
end

end
