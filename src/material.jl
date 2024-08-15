"""
```
struct Material{MD<:MaterialData}
    name::String
    materialdata::MD
    wavelength_range::Tuple{Float64,Float64}
end
```

A material stores:
- ```name::String``` : The name of the material, which is the path to the material in the database or a custom name when creating your own materials
- ```materialdata::{<:MaterialData}``` : The material data, i.e the refractive index data and extinction coefficient data
- ```wavelength::Tuple{Float64, Float64}``` : The wavelength range of the material data

!!! info
    Not every material in the database contains refractive indices and extinction coefficients. Some materials only contain refractive indices, while others only contain extinction coefficients.

The material object acts as a functor to compute the refractive index of the material for a given wavelength

```
(m::Material)(wavelength::Real; [, default::Real=0.0])
```

More information about the Functor method can be found here [`Material(wavelength::Real; default::Real)`](@ref)
"""
struct Material{MD<:MaterialData}
    name::String
    materialdata::MD
    wavelength_range::Tuple{Float64,Float64}
end


"""
```
Material(path::String) -> Union{Material, Vector{Material}
```

Creates a material from the given path in the refractive index database. This method will throw an ```ArgumentError``` if the given path does not correspond to a material in the database.

# Arguments

- ```path::String``` : The path to the material given in the format "<shelf>/<book>/<page>"

# Returns
- ```Union{Material, Vector{Material}``` : The material object(s) created from the given path. The method returns a vector of material objects if the page at the given path contains multiple material datasets.
"""
function Material(path::String)
    material = jldopen(RI_DATA_PATH) do RI_DATA_FILE
        haskey(RI_DATA_FILE, path) || throw(ArgumentError("Material not found in database. "))
        page = RI_DATA_FILE[path]
        map(key -> Material(path, MaterialData(page["$key/type"], page["$key/data"]), page["$key/wavelength_range"]), keys(page))
    end
    isone(length(material)) ? only(material) : material
end

"""
```
Material(shelf, book, page) -> Union{Material, Vector{Material}}
```
Provide the _shelf_, _book_ and _page_ of the material separately. This
method then calls ```Material(\"\$shelf/\$book/\$page\")```.

# Arguments
- ```shelf::String``` : The shelf of the material
- ```book::String``` : The book of the material
- ```page::String``` : The page of the material
"""
Material(shelf, book, page) = Material("$shelf/$book/$page")

"""
```
Material(n::Real [,name::String="unnamed"]) -> Material
```

Construct a material with a constant index of refraction over the entire wavelength range.
By default the material will be given the name "unnamed".
"""
function Material(n::Real, name::String="unnamed")
    Material(name, MaterialData(ConstantN, (n, NaN)), (-Inf, Inf))
end

"""
```
Material(n::Real, k::Real [, name::String="unnamed"]) -> Material
```

Construct a material with a constant index of refraction and extinction coefficient over the entire wavelength range.
By default the material will be given the name "unnamed".
"""
function Material(n::Real, k::Real, name::String="unnamed")
    Material(name, MaterialData(ConstantNK, (n, k)), (-Inf, Inf))
end

"""
```
Material(; k::Real [, name::String="unnamed"]) -> Material
```

Construct a material with a constant index of refraction and extinction coefficient over the entire wavelength range.
By default the material will be given the name "unnamed".
"""
function Material(; k::Real, name::String="unnamed")
    Material(name, MaterialData(ConstantK, (NaN, k)), (-Inf, Inf))
end

"""
```
findmaterial(name::Regex) -> Vector{String}
```

Search for materials in the database that match the given regular expression.
The method returns a vector of paths to the materials that startswith the regular expression.
The search is case-insensitive.

# Arguments
- ```name::Regex``` : The regular expression that the method will match to the start of the material paths.
"""
function findmaterial(name::Regex)
    paths = load(RI_LIBRARY_PATH, "paths")
    findall(path -> startswith(lowercase(path), name), paths)
end


"""
```
findmaterial(name::String) -> Vector{String}
```

# Arguments
- ```name::String``` : The name of the material to search for in the database. The name can be written in the format "<shelf>/<book>/<page>" or using spaces instead of forward slashes.
"""
function findmaterial(name::String)
    name = replace(name, " " => "/")
    paths = load(RI_LIBRARY_PATH, "paths")
    findall(path -> startswith(lowercase(path), lowercase(name)), paths)
end


"""
```
const NULL_MATERIAL = Material(NaN, "null")
```

Material object that defines the null material. The null material is defined as a material with name "null" and a constant refractive index of NaN over the entire wavelength range.
"""
const NULL_MATERIAL = Material(NaN, "null")

"""
```
isnullmaterial(m::Material) -> Bool
```

Check if the given material is the null material. The method returns true if the material is the null material, otherwise it returns false.
"""
isnullmaterial(::Material) = false
isnullmaterial(m::Material{MaterialConstant{C}}) where {C<:Constant} = isnan(m(Inf))

Base.show(io::IO, m::Material) = print(io, "Material($(m.name), $(m.materialdata), wavelength range = $(m.wavelength_range))")

"""
```
(m::Material)(wavelength::Real; [default::Real=1.0]) -> Real
```

Functor method to compute the refractive index of the material for a given wavelength. If the wavelength
is outside the wavelength range of the material the method will clamp the wavelength to the range. In the
case that the material does not contain data on the refractive indices of the material the method will
return the default value. The functor method calls the ```dispersion``` method.

# Arguments
- ```m::Material``` : The material object for which the refractive index is to be computed.
- ```wavelength::Real``` : The wavelength at which the refractive index is to be computed given in ``\\mu m``.
- ```default::Real=1.0``` : The default value to return if the material does not contain data on refractive indices
"""
(m::Material)(wavelength::Real; default::Real=1.0) = dispersion(m, wavelength, default=default)


"""
```
dispersion(m::Material, wavelength::Real; [default::Real=1.0]) -> Real
```

Compute the refractive index of the material for a given wavelength. If the wavelength
is outside the wavelength range of the material the method will clamp the wavelength to the range. In the
case that the material does not contain data on the refractive indices of the material the method will
return the default value.

# Arguments
- ```m::Material``` : The material object for which the refractive index is to be computed.
- ```wavelength::Real``` : The wavelength at which the refractive index is to be computed given in ``\\mu m``.
- ```default::Real=1.0``` : The default value to return if the material does not contain data on refractive indices

"""
function dispersion(m::Material, wavelength::Real; default::Real=1.0)
    wavelength_range = m.wavelength_range
    wavelength_range[1] <= wavelength <= wavelength_range[2] || @warn "Wavelength out of range. Clamping to $(wavelength_range)"
    wavelength = clamp(wavelength, wavelength_range...)
    return m.materialdata(wavelength, default)
end

"""
```
extinction(m::Material, wavelength::Real; [default::Float64=0.0]) -> Real
```

Compute the extinction coefficient of the material for a given wavelength. If the wavelength
is outside the wavelength range of the material the method will clamp the wavelength to the range. In the
case that the material does not contain data on the extinction coefficient of the material the method will
return the default value.

# Arguments
- ```m::Material``` : The material object for which the extinction coefficient is to be computed.
- ```wavelength::Real``` : The wavelength at which the extinction coefficient is to be computed given in ``\\mu m``.
- ```default::Float64=0.0``` : The default value to return if the material does not contain data on extinction coefficients
"""
function extinction(m::Material, wavelength::Real; default::Float64=0.0)
    wavelength_range = m.wavelength_range
    wavelength_range[1] <= wavelength <= wavelength_range[2] || @warn "Wavelength out of range. Clamping to $(wavelength_range)"
    wavelength = clamp(wavelength, wavelength_range...)
    return extinction(m.materialdata, wavelength, default)
end

"""
```
transmittance(m::Material, wavelength::Real, distance::Real; [default::Real=0.0]) -> Real
```

Compute the transmittance of the material for a given wavelength and distance

# Arguments
- ```m::Material``` : The material object
- ```wavelength::Real``` : The wavelength at which the transmittance is to be computed given in ``\\mu m``.
- ```distance::Real``` : The distance over which the transmittance is to be computed given in ``\\mu m``.
- ```default::Real=0.0``` : The default value to return for the extinction coefficient if the material does not contain data on extinction coefficients
"""
transmittance(m::Material, wavelength::Real, distance::Real; default::Real=0.0) = exp(-4 * pi * extinction(m, wavelength, default=default) * distance / wavelength)
