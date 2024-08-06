const DISPERSIONFORMULAE = Dict(
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

function str2tuple(str)
    arr = parse.(Float64, split(str))
    ntuple(i -> arr[i], length(arr))
end

function update_cache(url)
    @info "Downloading refractiveindex.info database..."
    download(url, RI_DATABASE_DOWNLOAD_PATH)
    @info "Extracting refractiveindex.info database..."
    zarchive = ZipFile.Reader(RI_DATABASE_DOWNLOAD_PATH)
    mkpath(RI_DATABASE_PATH)
    for file in zarchive.files
        isdirpath(file.name) ? mkpath(file.name) : write(file.name, read(file))
    end
    close(zarchive)

    @info "Creating cache..."
    mkpath(dirname(RI_DATA_PATH))
    mkpath(dirname(RI_LIBRARY_PATH))
    create_library()
    create_data()
    @info "Cache created."

    @info "Cleaning up..."
    rm(RI_DATABASE_DOWNLOAD_PATH)
    rm(RI_DATABASE_PATH, recursive=true)
    @info "Done."
    return
end

function create_library()
    lib = load_file(joinpath(RI_DATABASE_PATH, "catalog-nk.yml"), dicttype=Dict{String,Any})
    paths = Dict{String,String}()
    for shelf in lib
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
    return
end

function create_data()
    jldopen(RI_LIBRARY_PATH, "r+") do library_file
        paths = library_file["paths"]
        jldopen(RI_DATA_PATH, "w") do data_file
            for (name, path) in paths
                yaml = load_file(joinpath(RI_DATABASE_PATH, "data-nk", path), dicttype=Dict{Symbol,Any})
                data_vec = get(yaml, :DATA, Dict{Symbol,String}[])
                if isone(length(data_vec))
                    group_path = string(name, "/", 1)
                    data = only(data_vec)
                    data_file["$group_path/type"] = DISPERSIONFORMULAE[data[:type]]
                    if haskey(data, :coefficients)
                        wavelength_range = str2tuple(data[:wavelength_range])
                        data_file["$group_path/data"] = str2tuple(data[:coefficients])
                        data_file["$group_path/wavelength_range"] = wavelength_range
                    else
                        table = readdlm(IOBuffer(data[:data]), Float64)
                        wavelength_range = extrema(@view table[:, 1])
                        data_file["$group_path/data"] = table
                        data_file["$group_path/wavelength_range"] = wavelength_range
                    end
                else
                    for (i, data) in enumerate(data_vec)
                        group_path = string(name, "/", i)
                        data_file["$group_path/type"] = DISPERSIONFORMULAE[data[:type]]
                        if haskey(data, :coefficients)
                            wavelength_range = str2tuple(data[:wavelength_range])
                            data_file["$group_path/data"] = str2tuple(data[:coefficients])
                            data_file["$group_path/wavelength_range"] = wavelength_range
                        else
                            raw_data = readdlm(IOBuffer(data[:data]), Float64)
                            wavelength_range = extrema(@view raw_data[:, 1])
                            data_file["$group_path/data"] = raw_data
                            data_file["$group_path/wavelength_range"] = wavelength_range
                        end
                    end
                end
            end
        end
    end
    return
end
