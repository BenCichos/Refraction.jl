struct Material{DF<:DispersionFormula}
    name::String
    dispersion::DF
    wavelength_range::Tuple{Float64,Float64}
end

function Material(shelf, book, page)
    material = jldopen(RI_DATA_PATH) do data_file
        group_path = "$shelf/$book/$page"
        haskey(data_file, group_path) || throw(ArgumentError("Material not found"))
        DF = data_file["$group_path/type"]
        println(DF)
        data = data_file["$group_path/data"]
        wavelength_range = data_file["$group_path/wavelength_range"]
        return Material(group_path, DF(data), wavelength_range)
    end
    return material
end



Material(n::Real; name::String="unnamed") = Material(name, ConstantN(n), (-Inf, Inf))

(m::Material)(wavelength::Float64) = dispersion(m, wavelength)
function dispersion(m::Material, wavelength::Float64)
    wavelength_range = m.wavelength_range
    wavelength_range[1] <= wavelength <= wavelength_range[2] || @warn "Wavelength out of range. Clamping to $(wavelength_range)"
    wavelength = clamp(wavelength, wavelength_range...)
    return m.dispersion(wavelength)
end
dispersion(m::Material{ConstantN}, ::Float64) = m.dispersion.n
dispersion(::Material{TabulatedK}, ::Float64) = throw(ArgumentError("Material does not have refractive index data"))
