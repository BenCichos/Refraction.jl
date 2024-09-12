struct ConstantN <: Constant end
struct ConstantNK <: Constant end
struct ConstantK <: Constant end

@enum ConstantIndex begin
    ConstantIndex_N = 1
    ConstantIndex_K = 2
end

struct MaterialConstant{C<:Constant} <: MaterialData
    consts::Tuple{Float64,Float64}
end

MaterialData(C::Type{<:Constant}, consts::Tuple{Float64,Float64}) = MaterialConstant{C}(consts)
function (mc::MaterialConstant{C})(wavelength::Real, default::Real) where {C<:Constant}
    value = C(mc.consts, ConstantIndex_N, wavelength)
    isnan(value) && return default
    return value
end

function extinction(mc::MaterialConstant{C}, wavelength::Real, default::Real) where {C<:Constant}
    value = C(mc.consts, ConstantIndex_K, wavelength)
    isnan(value) && return default
    return value
end

show(io::IO, mc::MaterialConstant{C}) where {C<:Constant} = print(io, "$(C)(consts = $(mc.consts))")

function ConstantNK(consts::Tuple{Float64,Float64}, constantindex::ConstantIndex, ::Real)
    consts[Int(constantindex)]
end

function ConstantN(consts::Tuple{Float64,Float64}, constantindex::ConstantIndex, ::Real)
    constantindex === ConstantIndex_K && return NaN
    consts[Int(constantindex)]
end

function ConstantK(consts::Tuple{Float64,Float64}, constantindex::ConstantIndex, ::Real)
    constantindex === ConstantIndex_N && return NaN
    consts[Int(constantindex)]
end
