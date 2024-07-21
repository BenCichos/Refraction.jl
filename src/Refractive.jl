module Refractive
using JLD2: jldopen
using BasicInterpolators

import Base: getindex

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

include("dispersionformula.jl")
export DispersionFormula
include("material.jl")
export Material, dispersion

end
