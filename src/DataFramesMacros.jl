module DataFramesMacros

using DataFrames

include("make_vec_to_fun.jl")

macro cols(args...)
    esc(make_vec_to_fun(args...))
end

macro rows(args...)
    esc(make_vec_to_fun(args...; byrow = true))
end

# https://sodocumentation.net/julia-lang/topic/5817/string-macros for string macros
# this allows to pass strings instead of expressoins
macro cols_str(str)
	e = gensym()
    quote
        $e = Meta.parse($(esc(Meta.parse("\"$(escape_string(str))\""))))
        @eval(@cols($(Expr(:$, e))))
    end
end

macro rows_str(str)
	e = gensym()
    quote
        $e = Meta.parse($(esc(Meta.parse("\"$(escape_string(str))\""))))
        @eval(@rows($(Expr(:$, e))))
    end
end

export @rows, @cols, @cols_str, @rows_str, ByRow

end
