# Material

## Material
```@docs
Material
Material(path::String)
Material(shelf::String, book::String, page::String)
Material(n::Real, name::String)
Material(n::Real, k::Real, name::String)
Material(; k::Real, name::String)
```

## Finding Materials
```@docs
findmaterial
```

## Null Material
```@docs
NULL_MATERIAL
isnullmaterial
```

## Refractive Index
```@docs
Material(wavelength::Real; default::Real)
dispersion
```

## Extinction Coefficient
```@docs
extinction
transmittance
```
