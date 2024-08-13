abstract type MaterialData end

abstract type Dispersion end
abstract type Constant <: Dispersion end

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
(mc::MaterialConstant{C})(wavelength::Real) where {C<:Constant} = C(mc.consts, ConstantIndex_N, wavelength)
function extinction(mc::MaterialConstant{C}, wavelength::Real; default::Float64=0.0) where {C<:Constant}
    try
        return C(mc.consts, ConstantIndex_K, wavelength)
    catch e
        @warn "$(e.msg). Return $default."
        return default
    end
end

show(io::IO, mc::MaterialConstant{C}) where {C<:Constant} = print(io, "$(C)(consts = $(mc.consts))")

function ConstantNK(consts::Tuple{Float64,Float64}, constantindex::ConstantIndex, ::Real)
    consts[Int(constantindex)]
end

function ConstantN(consts::Tuple{Float64,Float64}, constantindex::ConstantIndex, ::Real)
    constantindex === ConstantIndex_K && throw(ArgumentError("ConstantN does not contain information about the extinction coefficient"))
    consts[Int(constantindex)]
end

function ConstantK(consts::Tuple{Float64,Float64}, constantindex::ConstantIndex, ::Real)
    constantindex === ConstantIndex_N && throw(ArgumentError("ConstantK does not contain information about the refractive index"))
    consts[Int(constantindex)]
end

abstract type Formula <: Dispersion end

struct Sellmeier <: Formula end
struct Sellmeier2 <: Formula end
struct Polynomial <: Formula end
struct RIInfo <: Formula end
struct Cauchy <: Formula end
struct Gases <: Formula end
struct Herzberger <: Formula end
struct Retro <: Formula end
struct Exotic <: Formula end

struct MaterialFormula{N,F<:Formula} <: MaterialData
    coeffs::NTuple{N,Float64}
end

MaterialData(F::Type{<:Formula}, coeffs::NTuple{N,Float64}) where {N} = MaterialFormula{N,F}(coeffs)

(mf::MaterialFormula{N,F})(wavelength::Real) where {N,F<:Formula} = F(mf.coeffs, wavelength)
function extinction(::MaterialFormula{N,F}, wavelength::Real; default::Float64=0.0) where {N,F<:Formula}
    @warn "MaterialFormula does not contain information about the extinction coefficient. Returning $default."
    default
end
show(io::IO, mf::MaterialFormula{N,F}) where {N,F<:Formula} = print(io, "$(F)(coeffs = $(mf.coeffs))")

function Sellmeier(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * wavelength^2 / (wavelength^2 - c[i+1]^2)
    end
    return sqrt(rhs + 1)
end

function Sellmeier2(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * wavelength^2 / (wavelength^2 - c[i+1])
    end
    return sqrt(rhs + 1)
end

function Polynomial(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * wavelength^c[i+1]
    end
    return sqrt(rhs)
end

function RIInfo(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    for i = 2:4:min(N, 9)
        rhs += (c[i] * wavelength^c[i+1]) / (wavelength^2 - c[i+2]^c[i+3])
    end
    for i = 10:2:N
        rhs += c[i] * wavelength^c[i+1]
    end
    return sqrt(rhs)
end

function Cauchy(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] * wavelength^c[i+1]
    end
    return rhs
end

function Gases(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    for i = 2:2:N
        rhs += c[i] / (c[i+1] - 1 / wavelength^2)
    end
    return rhs + 1
end

function Herzberger(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1]
    rhs += c[2] / (wavelength^2 - 0.028)
    rhs += c[3] * (1 / (wavelength^2 - 0.028))^2
    for i = 4:N
        pow = 2 * (i - 3)
        rhs += c[i] * wavelength^pow
    end
    return rhs
end

function Retro(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1] + c[2] * wavelength^2 / (wavelength^2 - c[3]) + c[4] * wavelength^2
    return sqrt((-2rhs - 1) / (rhs - 1))
end

function Exotic(c::NTuple{N,Float64}, wavelength::Real) where {N}
    rhs = c[1] + c[2] / (wavelength^2 - c[3]) + c[4] * (wavelength - c[5]) / ((wavelength - c[5])^2 + c[6])
    return sqrt(rhs)
end

abstract type Table <: Dispersion end

function fix_table_sorting(table::Matrix{Float64})
    table = issorted(@views table[:, 1]) ? table : sortslices(table, dims=1, by=first)
    isone(size(table, 1)) && return [table; table]
    return table
end

@enum TableIndex begin
    TableIndex_N = 2
    TableIndex_K = 3
end

struct TableN <: Table end
struct TableK <: Table end
struct TableNK <: Table end

struct MaterialTable{T<:Table} <: MaterialData
    table::Matrix{Float64}
    MaterialTable{T}(table::Matrix{Float64}) where {T<:Table} = new{T}(fix_table_sorting(table))
end

MaterialData(T::Type{<:Table}, table::Matrix{Float64}) = MaterialTable{T}(table)

(mt::MaterialTable{T})(wavelength::Real) where {T<:Table} = T(mt.table, TableIndex_N, wavelength)
function extinction(mt::MaterialTable{T}, wavelength::Real; default::Float64=0.0) where {T<:Table}
    try
        return T(mt.table, TableIndex_K, wavelength)
    catch e
        @warn "$(e.msg). Returning $default."
        return default
    end
end
show(io::IO, mt::MaterialTable{T}) where {T} = print(io, "$(T)(size = $(size(mt.table)))")

function interpolate(wavelength_column::W, interpolation_column::I, wavelength::Float64) where {W<:AbstractArray,I<:AbstractArray}
    wavelength == first(wavelength_column) && return first(interpolation_column)
    wavelength == last(wavelength_column) && return last(interpolation_column)

    upper_index = searchsortedfirst(wavelength_column, wavelength)
    lower_index = upper_index - 1

    @inbounds wl_upper = wavelength_column[upper_index]
    @inbounds wl_lower = wavelength_column[lower_index]
    @inbounds int_upper = interpolation_column[upper_index]
    @inbounds int_lower = interpolation_column[lower_index]

    (wavelength - wl_lower) * (int_upper - int_lower) / (wl_upper - wl_lower) + int_lower
end

function TableNK(table::Matrix{Float64}, tableindex::TableIndex, wavelength::Real)
    interpolate((@view table[:, 1]), (@view table[:, Int(tableindex)]), wavelength)
end

function TableN(table::Matrix{Float64}, tableindex::TableIndex, wavelength::Real)
    (tableindex === TableIndex_K) && throw(ArgumentError("TableN does not contain information about the extinction coefficient"))
    interpolate((@view table[:, 1]), (@view table[:, Int(tableindex)]), wavelength)
end

function TableK(table::Matrix{Float64}, tableindex::TableIndex, wavelength::Real)
    (tableindex === TableIndex_N) && throw(ArgumentError("TableK does not contain information about the refractive index"))
    interpolate((@view table[:, 1]), (@view table[:, Int(tableindex)]), wavelength)
end
