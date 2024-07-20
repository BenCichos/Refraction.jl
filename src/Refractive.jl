module Refractive
using JLD2: jldopen
using BasicInterpolators

import Base: getindex

include("dispersionformula.jl")
export DispersionFormula
include("material.jl")
export Material, dispersion

end
