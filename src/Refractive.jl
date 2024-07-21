module Refractive
using JLD2: jldopen
using BasicInterpolators

import Base: getindex

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

include("dispersionformula.jl")
export DispersionFormula, ConstantN, Sellmeier, Sellmeier2, Polynomial, RIInfo, Cauchy, Gases, Herzberger, Retro, Exotic, TabulatedNK, TabulatedN, TabulatedK

include("material.jl")
export Material, dispersion

end
