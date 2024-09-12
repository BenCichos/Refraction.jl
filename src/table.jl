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

function (mt::MaterialTable{T})(wavelength::Real, default::Real) where {T<:Table}
    value = T(mt.table, TableIndex_N, wavelength)
    isnan(value) && return default
    return value
end

function extinction(mt::MaterialTable{T}, wavelength::Real, default::Real) where {T<:Table}
    value = T(mt.table, TableIndex_K, wavelength)
    isnan(value) && return default
    return value
end
show(io::IO, mt::MaterialTable{T}) where {T} = print(io, "$(T)(size = $(size(mt.table)))")

function interpolate(wavelength_column::W, interpolation_column::I, wavelength::Float64) where {W<:AbstractArray,I<:AbstractArray}
    wavelength == first(wavelength_column) && return first(interpolation_column)
    wavelength == last(wavelength_column) && return last(interpolation_column)

    upper_index = searchsortedfirst((@view wavelength_column[:]), wavelength)
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
    (tableindex === TableIndex_K) && return NaN
    interpolate((@view table[:, 1]), (@view table[:, Int(tableindex)]), wavelength)
end

function TableK(table::Matrix{Float64}, tableindex::TableIndex, wavelength::Real)
    (tableindex === TableIndex_N) && return NaN
    interpolate((@view table[:, 1]), (@view table[:, Int(tableindex)]), wavelength)
end
