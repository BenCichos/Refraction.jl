module Refractive
using JLD2
using BasicInterpolators
using ZipFile
using YAML: load_file
using DelimitedFiles: readdlm

import Base: getindex, show

const RI_DATA_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_data.jld2")
const RI_LIBRARY_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_library.jld2")
const RI_DATABASE_PATH = pkgdir(@__MODULE__, "database")
const RI_DATABASE_DOWNLOAD_PATH = pkgdir(@__MODULE__, "database.zip")

include("dispersionformula.jl")
export DispersionFormula

include("material.jl")
export Material, dispersion

include("create_cache.jl")

end
