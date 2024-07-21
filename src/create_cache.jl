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
    "tabulated nk" => TabulatedNK,
    "tabulated n" => TabulatedN,
    "tabulated k" => TabulatedK,
)

function str2tuple(str)
    arr = parse.(Float64, split(str))
    ntuple(i -> arr[i], length(arr))
end

function create_library()
    lib = load_file(pkgdir(@__MODULE__, "database", "catalog-nk.yml"), dicttype=Dict{String,Any})

    jldopen(RI_LIBRARY_PATH, "w") do file
        for shelf in lib
            shelfname = shelf["SHELF"]
            for book in shelf["content"]
                haskey(book, "DIVIDER") && continue
                bookname = book["BOOK"]
                for page in book["content"]
                    haskey(page, "DIVIDER") && continue
                    pagename = string(page["PAGE"])
                    path = "$shelfname/$bookname/$pagename"
                    haskey(file, path) && continue
                    file[path] = (name=page["name"], path=page["data"])
                end
            end
        end
    end
end

function create_data()
    jldopen(RI_LIBRARY_PATH, "r") do library_file
        jldopen(RI_DATA_PATH, "w") do data_file
            for shelf in keys(library_file)
                shelf_group = library_file[shelf]
                for book in keys(shelf_group)
                    book_group = shelf_group[book]
                    for page in keys(book_group)
                        page_data = book_group[page]
                        path = page_data.path
                        yaml = load_file(joinpath("./database/data-nk/", path), dicttype=Dict{Symbol,Any})
                        data = get(yaml, :DATA, Dict{Symbol,String}[]) |> first
                        group_path = "$shelf/$book/$page"

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
end
