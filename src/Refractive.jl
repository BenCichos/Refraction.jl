module Refractive
using JLD2
using BasicInterpolators

import Base: getindex

const RI_DATA_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_data.jld2")
const RI_LIBRARY_PATH = pkgdir(@__MODULE__, "data", "refractive_indices_library.jld2")

include("dispersionformula.jl")
export DispersionFormula

include("material.jl")
export Material, dispersion

#include("create_cache.jl")

end
