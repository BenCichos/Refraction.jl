struct Material{DF<:DispersionFormula}
    name::String
    dispersion::DF
    wavelength_range::Tuple{Float64,Float64}
end

function Material(shelf, book, page)
    jldopen("nk_data.jld2") do data_file
        group_path = "$shelf/$book/$page"
        DF = data_file["$group_path/type"]
        data = data_file["$group_path/data"]
        wavelength_range = data_file["$group_path/wavelength_range"]
        return Material(
            string("$shelf/$book/$page"),
            DF(data),
            wavelength_range
        )
    end
    throw(ArgumentError("Material not found"))
end

Material(n::Real; name::String="unnamed") = Material(name, ConstantN(n), (-Inf, Inf))

(m::Material)(λ::Float64) = dispersion(m, λ)
dispersion(m::Material, λ::Float64) = m.dispersion(λ)
dispersion(m::Material{T}, λ::Float64) where {T<:Union{TabulatedN,TabulatedNK}} = m.dispersion.n(λ)
dispersion(m::Material{ConstantN}, ::Float64) = m.dispersion.n
dispersion(::Material{TabulatedK}, ::Float64) = throw(ArgumentError("Material does not have refractive index data"))
