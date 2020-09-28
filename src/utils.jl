##############################################################################
##
## Code based on https://github.com/JuliaData/DataFramesMeta.jl/pull/152
##
##############################################################################

function addkey!(membernames::Dict, nam)
    if !haskey(membernames, nam)
        membernames[nam] = gensym()
    end
    membernames[nam]
end

parse_columns!(membernames::Dict, x) = x
function parse_columns!(membernames::Dict, q::Symbol)
    addkey!(membernames, QuoteNode(q))
end
function parse_columns!(membernames::Dict, e::Expr)
    if e.head === :$
        length(e.args) == 1 || throw("Malformed Expression")
        addkey!(membernames, e.args[1])
    elseif (e.head === :call) && (e.args[1] == :^)
        length(e.args) == 2 || throw("Malformed Expression")
        e.args[2]
    elseif e.head === :.
        length(e.args) == 2 || throw("Malformed Expression")
        Expr(:., e.args[1], parse_columns!(membernames, e.args[2]))
    elseif (e.head === :call) && length(e.args) > 1
        Expr(e.head, e.args[1], (parse_columns!(membernames, x) for x in e.args[2:end])...)
    elseif (e.head === :call) && length(e.args) == 1
        e
    else
        Expr(e.head, (parse_columns!(membernames, x) for x in e.args)...)
    end
end

iscomposition(e, set::Set) = false
function iscomposition(e::Expr, set::Set)
    if e.head === :call
        if length(e.args) == 1 || ((length(e.args) == 2) && (e.args[2] ∈ set))
            # f() or f(x)
            return true
        elseif length(e.args) == 2
            # f(g(...))
            return iscomposition(e.args[2], set)
        end
    end
    return false
end

function make_composition(e::Expr, set::Set)
    if e.head === :call
        if length(e.args) == 1 || ((length(e.args) == 2) && (e.args[2] ∈ set))
            return e.args[1]
        elseif length(e.args) == 2
            return Expr(:call, :(Base.:∘), e.args[1], make_composition(e.args[2], set))
        end
    end
end
