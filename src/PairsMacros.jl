module PairsMacros
using DataFrames

include("make_vec_to_fun.jl")

macro cols(arg)
    esc(make_vec_to_fun(arg))
end

macro rows(arg)
    esc(make_vec_to_fun(arg; byrow = true))
end

# when Cols() implemented in DataFrames.jl, 
# @cols(f, r".*") could be used to return Cols(r".*") .=> f
export @rows, @cols

end