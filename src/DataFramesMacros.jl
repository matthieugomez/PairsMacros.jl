module DataFramesMacros

using DataFrames
##############################################################################
##
## Code based on https://github.com/JuliaData/DataFramesMeta.jl/pull/152
##
##############################################################################

function addkey!(membernames, nam)
    if !haskey(membernames, nam)
        membernames[nam] = gensym()
    end
    membernames[nam]
end

replace_syms!(x, membernames) = x
function replace_syms!(q::Symbol, membernames)
    addkey!(membernames, QuoteNode(q))
end
function replace_syms!(e::Expr, membernames)
    if e.head === :$
        addkey!(membernames, e.args[1])
    elseif e.head === :call
        if e.args[1] == :^
            e.args[2]         
        elseif length(e.args) > 1
            Expr(e.head, e.args[1], map(x -> replace_syms!(x, membernames), e.args[2:end])...)
        else
            e
        end
    else
        Expr(e.head, map(x -> replace_syms!(x, membernames), e.args)...)
    end
end

function make_vec_to_fun(kw::Expr; byrow = false)
    funname = gensym()
    membernames = Dict{Any, Symbol}()
    if kw.head == :(=) || kw.head == :kw
        output = kw.args[1]
        if output isa Symbol
            output = QuoteNode(output)
        elseif output.head === :$
            output = output.args[1]
        end
        body = replace_syms!(kw.args[2], membernames)
    else
        body = replace_syms!(kw, membernames)
    end
    f = quote
            function $funname($(values(membernames)...))
                $body 
            end
        end
    if byrow
        f = quote ByRow($f) end
    end
    if kw.head == :(=) || kw.head == :kw
        quote
            $(Expr(:vect, keys(membernames)...)) => $f => $output
        end
    else
        quote
            $(Expr(:vect, keys(membernames)...)) => $f
        end
    end
end


function make_vec_to_fun(kw::QuoteNode; byrow = false)
    return kw
end

##############################################################################
##
## Define Macro
##
##############################################################################

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

##############################################################################
##
## Export
##
##############################################################################
export @rows, @cols, ByRow

end

