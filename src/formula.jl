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

(mf::MaterialFormula{N,F})(wavelength::Real, ::Real) where {N,F<:Formula} = F(mf.coeffs, wavelength)
extinction(::MaterialFormula{N,F}, wavelength::Real, default::Real) where {N,F<:Formula} = return default
Base.show(io::IO, mf::MaterialFormula{N,F}) where {N,F<:Formula} = print(io, "$(F)(coeffs = $(mf.coeffs))")

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
