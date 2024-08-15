# Refraction.jl

```@setup refraction
using Refraction
```

### Initialisation

When using the package for the first time the package will download the latest
version of the database and create a local cache, in the data folder of the
package directory. The database is only downloaded when the data folder
does not contain the necessary files for the package to work correctly.

### Creating Materials

You can load a given material from the database using the `Material` function.
The function takes a *shelf*, *book*, and *page* as parameters.

```@example refraction
sio2 = Material("main", "SiO2", "Malitson")
```
This constructs an instance of `Material`, which contains the name of the
material, the wavelength range, and the dispersion formula to calculate
the refractive index of the material for a given wavelength.

You can also speficy the *shelf*, *book* and *page* as a path
```@example refraction
sio2 = Material("main/SiO2/Malitson")
```
The package also allows you to define materials that have a constant
refractive index over all wavelengths, which is convenient for definings
materials such as vaccuum. You can create a material with a constant refractive
index using the `Material` function by passing a *name* and a *refractive index* as parameters.
```@example refraction
vacuum_n = Material(1.0, "vacuum")
```
If you want you can omit the name of the material and the material will
be saved as "unnamed". You can similarly create a material with a constant
extinction coefficient
```@example refraction
dampner = Material(; k=0.1, name="dampner")
```
or constant refractive index and extinction coefficient
```@example refraction
vacuum = Material(1.0, 0.0, "vacuum")
```

## Finding Materials

Since it can be difficult to remember the exact paths to the materials in
the database, we provide a function `findmaterial` that allows you to
search for a material by providing a partial path string or a regex pattern. The
search for the material is case-insensitive. You can either write the path using
slashes
```@example refraction
findmaterial("main/SiO2")
```
or with spaces in between the shelf, book, and page
```@example refraction
findmaterial("main SiO2")
```
This function returns a list of paths that start with the search pattern. You can
then use the `Material` function to load the material you want.

## Computing Refractive Index

Once you have an instance of `Material` you can call it as a functor with
a specific wavelength to compute its refractive index. **Note that the
wavelengths must be given in $\mu m$**. We will use the SiO2 material from
above as an example.
```@example refraction
n = sio2(0.5)
```
When calling the material as a functor, this is actually just syntactic
sugar for calling
```@example refraction
n = dispersion(sio2, 0.5)
```
When the given wavelength is outside of the wavelength range, we will issue
a warning that the wavelength is outside of the range and that we are calling
the `clamp` function to return a refractive index at the closest wavelength in
the range.
```@example refraction
n = sio2(0.1)
println(n) # hide
```

However, if you try to compute the refractive index of a material for a given
wavelength that does not contain data on the refractive indices the function will
return a default value which is 1.0 by default.
```@example refraction
n = dampner(0.1)
println(n) # hide
```
You can also change the default value by passing a keyword argument to the function.
```@example refraction
n = dampner(0.1, default=0.0)
println(n) # hide
```

### Computing Extinction Coefficient

You can also compute the extinction coefficient of a material for a given
wavelength by calling the `extinction` function with the material and the
wavelength as parameters. **Note that the wavelengths must be given in $\mu m$**.
```@example refraction
au = Material("main", "Au", "Johnson")
k = extinction(au, 0.5)
```
This function will return the extinction coefficient of the material at the
given wavelength. Similar to the refractive index, if the given wavelength is
outside of the wavelength range, we will issue a warning that the wavelength is
outside of the range and that we are calling the `clamp` function to return an
extinction coefficient at the closest wavelength in the range.
```@example refraction
k = extinction(au, 0.1)
println(k) # hide
```

If the material does not contain data on the extinction coefficients the function
will return a default value which is 0.0 by default.
```@example refraction
k = extinction(vacuum_n,0.1)
println(k) # hide
```
You can also change the default value by passing a keyword argument to the function.
```@example refraction
k = extinction(vacuum_n,0.1, default=1.0)
println(k) # hide
```

## Update local database
The package also allows you the local version of the refractiveindex.info
database by calling the `update_cache` function with the url of the database.
By writing the following
```julia
Refractive.update_cache(<url>)
```
where the url is the link to the zip file of the database on [refractiveindex.info](https://refractiveindex.info/about).
The package will download the specified database and replace the previous version of the database that is stored locally.
