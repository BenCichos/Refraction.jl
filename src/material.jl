struct Material{MD<:MaterialData}
    name::String
    materialdata::MD
    wavelength_range::Tuple{Float64,Float64}
end

function Material(path::String)
    material = jldopen(RI_DATA_PATH) do data_file
        haskey(data_file, path) || throw(ArgumentError("Material not found"))
        page = data_file[path]
        page_keys = keys(page)
        if isone(length(page_keys))
            MD_TYPE = page["1/type"]
            data = page["1/data"]
            wavelength_range = page["1/wavelength_range"]
            material_data = MaterialData(MD_TYPE, data)
            return Material(path, material_data, wavelength_range)
        else
            materials = Material[]
            for page_key in page_keys
                MD_TYPE = page["$page_key/type"]
                data = page["$page_key/data"]
                wavelength_range = page["$page_key/wavelength_range"]
                material_data = MaterialData(MD_TYPE, data)
                push!(materials, Material(path, material_data, wavelength_range))
            end
            return materials
        end
    end
    return material
end

function findmaterial(name::Union{String,Regex})
    file = jldopen(RI_LIBRARY_PATH, "r")
    matches = findall(path -> startswith(path, name), file["paths"])
    close(file)
    matches
end

findmaterial(shelf::String, book::String, page::String) = findmaterial(string(shelf, "/", book, "/", page))

Material(shelf, book, page) = Material("$shelf/$book/$page")
Material(n::Real) = Material("unnamed", MaterialData(ConstantN, (n, NaN)), (-Inf, Inf))
Material(n::Real, k::Real) = Material("unnamed", MaterialData(ConstantNK, (n, k)), (-Inf, Inf))
Material(name::String, n::Real) = Material(name, MaterialData(ConstantN, (n, NaN)), (-Inf, Inf))
Material(name::String, n::Real, k::Real) = Material(name, MaterialData(ConstantNK, (n, k)), (-Inf, Inf))
Material(; name::String="unnamed", k::Real) = Material(name, MaterialData(ConstantK, (NaN, k)), (-Inf, Inf))

const NULL_MATERIAL = Material(NaN)
isnullmaterial(::Material) = false
isnullmaterial(m::Material{MaterialConstant{C}}) where {C<:Constant} = isnan(m(Inf))
show(io::IO, m::Material) = print(io, "Material($(m.name), $(m.materialdata), wavelength range = $(m.wavelength_range))")

(m::Material)(wavelength::Real) = dispersion(m, wavelength)
function dispersion(m::Material, wavelength::Real)
    wavelength_range = m.wavelength_range
    wavelength_range[1] <= wavelength <= wavelength_range[2] || @warn "Wavelength out of range. Clamping to $(wavelength_range)"
    wavelength = clamp(wavelength, wavelength_range...)
    return m.materialdata(wavelength)
end

function extinction(m::Material, wavelength::Real; default::Float64=0.0)
    wavelength_range = m.wavelength_range
    wavelength_range[1] <= wavelength <= wavelength_range[2] || @warn "Wavelength out of range. Clamping to $(wavelength_range)"
    wavelength = clamp(wavelength, wavelength_range...)
    return extinction(m.materialdata, wavelength, default=default)
end
