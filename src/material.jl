struct Material{DF<:DispersionFormula}
    name::String
    dispersion::DF
    wavelength_range::Tuple{Float64,Float64}
end

function Material(path::String)
    material = jldopen(RI_DATA_PATH) do data_file
        haskey(data_file, path) || throw(ArgumentError("Material not found"))
        page = data_file[path]
        page_keys = keys(page)
        if isone(length(page_keys))
            DF = page["1/type"]
            data = page["1/data"]
            wavelength_range = page["1/wavelength_range"]
            return Material(path, DF(data), wavelength_range)
        else
            materials = Material[]
            for page_key in page_keys
                DF = page["$page_key/type"]
                data = page["$page_key/data"]
                wavelength_range = page["$page_key/wavelength_range"]
                push!(materials, Material(path, DF(data), wavelength_range))
            end
            return materials
        end
    end
    return material
end

Material(shelf, book, page) = Material("$shelf/$book/$page")
Material(n::Real) = Material("unnamed", ConstantN(n), (-Inf, Inf))
Material(name::String, n::Real) = Material(name, ConstantN(n), (-Inf, Inf))

show(io::IO, m::Material) = print(io, "Material($(m.name), $(typeof(m.dispersion)), $(m.wavelength_range))")

(m::Material)(wavelength::Float64) = dispersion(m, wavelength)
function dispersion(m::Material, wavelength::Float64)
    wavelength_range = m.wavelength_range
    wavelength_range[1] <= wavelength <= wavelength_range[2] || @warn "Wavelength out of range. Clamping to $(wavelength_range)"
    wavelength = clamp(wavelength, wavelength_range...)
    return m.dispersion(wavelength)
end
dispersion(m::Material{ConstantN}, ::Float64) = m.dispersion.n
dispersion(::Material{TabulatedK}, ::Float64) = throw(ArgumentError("Material does not have refractive index data"))
