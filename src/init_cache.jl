const DATA_TYPES = Dict(
    "formula 1" => Sellmeier,
    "formula 2" => Sellmeier2,
    "formula 3" => Polynomial,
    "formula 4" => RIInfo,
    "formula 5" => Cauchy,
    "formula 6" => Gases,
    "formula 7" => Herzberger,
    "formula 8" => Retro,
    "formula 9" => Exotic,
    "tabulated nk" => TableNK,
    "tabulated n" => TableN,
    "tabulated k" => TableK,
)

function str2tuple(str::String)
    arr = [parse(Float64, substr) for substr in split(str)]
    ntuple(i -> arr[i], length(arr))
end

function init_cache()
    mkpath(dirname(RI_DATA_PATH))
    mkpath(dirname(RI_LIBRARY_PATH))
    create_library()
    create_data()
    return
end

function create_library()
    catalog = load_file(joinpath(RI_DATABASE_PATH, "catalog-nk.yml"), dicttype=Dict{String,Any})
    paths = Dict{String,String}()
    for shelf in catalog
        shelfname = shelf["SHELF"]
        for book in shelf["content"]
            haskey(book, "DIVIDER") && continue
            bookname = book["BOOK"]
            for page in book["content"]
                haskey(page, "DIVIDER") && continue
                pagename = string(page["PAGE"])
                name = string(shelfname, "/", bookname, "/", pagename)
                paths[name] = page["data"]
            end
        end
    end
    jldsave(RI_LIBRARY_PATH; paths)
end

function create_data()
    jldopen(RI_DATA_PATH, "w") do RI_DATA_FILE
        paths = load(RI_LIBRARY_PATH, "paths")
        for (name, path) in paths
            database_data = load_file(joinpath(RI_DATABASE_PATH, "data-nk", path), dicttype=Dict{Symbol,Any})
            data_vector = get(database_data, :DATA, Dict{Symbol,String}[])
            for (key, raw_data) in enumerate(data_vector)
                dict_string = Dict{Symbol,String}(raw_data)
                data_type = DATA_TYPES[raw_data[:type]]
                data, wavelength_range = parsedata(data_type, dict_string)

                data_path = string(name, "/", key)
                RI_DATA_FILE[string(data_path, "/type")] = data_type
                RI_DATA_FILE[string(data_path, "/data")] = data
                RI_DATA_FILE[string(data_path, "/wavelength_range")] = wavelength_range
            end
        end
    end
end

function parsedata(::Type{<:Formula}, raw_data::Dict{Symbol,String})
    str2tuple(raw_data[:coefficients]), str2tuple(raw_data[:wavelength_range])
end

function parsedata(::Type{<:Table}, raw_data::Dict{Symbol,String})
    table = readdlm(IOBuffer(raw_data[:data]), Float64)
    table, extrema(@view table[:, 1])
end
