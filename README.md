# Refraction.jl

This package provides a simple interface to the refractiveindex.info
database. The database is downloaded and stored in the data folder locally
in a JLD2 file format. This allows for storage of julia data types which
increases the performance of accessing a specific material in the database
faster.

**The package is very largely based on the RefractiveIndex.jl package and offers similar functionality with some extensions.**

## Usage

## Initialisation

When using the package for the first time the package will download the latest
version of the database and create a local cache, in the data folder of the
package directory. The database is only downloaded when the data folder
does not contain the necessary files for the package to work correctly.

### Create Material

You can load a given material from the database using the `Material` function.
The function takes a *shelf*, *book*, and *page* as parameters.
```julia
using Refractive
sio2 = Material("main", "SiO2", "Malitson")
```
This constructs an instance of `Material`, which contains the name of the
material, the wavelength range, and the dispersion formula to calculate
the refractive index of the material for a given wavelength.

You can also speficy the *shelf*, *book* and *page* as a path
```julia
using Refractive
sio2 = Material("main/SiO2/Malitson")
```
The package also allows you to define materials that have a constant
refractive index over all wavelengths, which is convenient for definings
materials such as vaccuum. We extend the dispersion formulae from the
database with the the dispersion formula `ConstantN`. You can create a
material with a constant refractive index using the `Material` function
by passing a *name* and a *refractive index* as parameters.
```julia
vacuum = Material("vacuum", 1.0)
```
If you want you can omit the name of the material and the material will
be saved as "unnamed".

## Find Material

Since it can be difficult to remember the exact names of the materials in
the database, we provide a function `findmaterial` that allows you to
search for a material by providing a partial path or a regex pattern.
```julia
findmaterial("main/SiO2")
```
This function returns a list of paths that match the search pattern. You can
then use the `Material` function to load the material you want.

## Compute Refractive Index

Once you have an instance of `Material` you can call it as a functor with
a specific wavelength to compute its refractive index. **Note that the
wavelengths must be given in $\mu m$**. We will use the SiO2 material from
above as an example.
```julia
wavelength = 0.5 # Wavelength in μm
n = sio2(wavelength)
```
When calling the material as a functor, this is actually just syntactic
sugar for calling
```julia
n = dispersion(sio2, λ)
```
When the given wavelength is outside of the wavelength range, we will issue
a warning that the wavelength is outside of the range and that we are calling
the `clamp` function to return a refractive index at the closest wavelength in
the range.

## Update local database
The package also allows you the local version of the refractiveindex.info
database by calling the `update_cache` function with the url of the database.
By writing the following
```julia
Refractive.update_cache(<url>)
```
the package will download the specified database and replace the previous
version of the database that is stored locally.
