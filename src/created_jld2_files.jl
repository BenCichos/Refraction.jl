# using JLD2
# using YAML: load_file

# function create_cache()
#     lib = load_file(joinpath("./data/", "catalog-nk.yml"), dicttype=Dict{String,Any})

#     jldopen("nk_library.jld2", "w") do file
#         for shelf in lib
#             shelfname = shelf["SHELF"]
#             for book in shelf["content"]
#                 haskey(book, "DIVIDER") && continue
#                 bookname = book["BOOK"]
#                 for page in book["content"]
#                     haskey(page, "DIVIDER") && continue
#                     pagename = string(page["PAGE"])
#                     path = "$shelfname/$bookname/$pagename"
#                     haskey(file, path) && continue
#                     file[path] = (name=page["name"], path=page["data"])
#                 end
#             end
#         end
#     end
# end

# function create_data_jld2_file()
#     jldopen("./nk_library.jld2", "r") do library_file
#         jldopen("./nk_data.jld2", "w") do data_file
#             for shelf in keys(library_file)
#                 shelf_group = library_file[shelf]
#                 for book in keys(shelf_group)
#                     book_group = shelf_group[book]
#                     for page in keys(book_group)
#                         page_data = book_group[page]
#                         path = page_data.path
#                         yaml = load_file(joinpath("./data/data-nk/", path), dicttype=Dict{Symbol,Any})
#                         data = get(yaml, :DATA, Dict{Symbol,String}[]) |> first
#                         group_path = "$shelf/$book/$page"

#                         data_file["$group_path/type"] = DISPERSIONFORMULAE[data[:type]]
#                         if haskey(data, :coefficients)
#                             wavelength_range = str2tuple(data[:wavelength_range])
#                             data_file["$group_path/data"] = str2tuple(data[:coefficients])
#                             data_file["$group_path/wavelength_range"] = wavelength_range
#                         else
#                             raw_data = readdlm(IOBuffer(data[:data]), Float64)
#                             wavelength_range = extrema(@view raw_data[:, 1])
#                             data_file["$group_path/data"] = raw_data
#                             data_file["$group_path/wavelength_range"] = wavelength_range
#                         end
#                     end
#                 end
#             end
#         end
#     end


# end

# create_cache()
# create_data_jld2_file()
