module DataFramesMacros

using DataFrames

include("make_vec_to_fun.jl")

macro cols(arg)
    esc(make_vec_to_fun(arg))
end

macro cols(args...)
    esc(Expr(:..., Expr(:tuple, (make_vec_to_fun(arg) for arg in args)...)))
end

macro rows(arg)
    esc(make_vec_to_fun(arg; byrow = true))
end

macro rows(args...)
    esc(Expr(:..., Expr(:tuple, (make_vec_to_fun(arg; byrow = true) for arg in args)...)))
end

export @rows, @cols, ByRow

end

