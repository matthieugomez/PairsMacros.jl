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

function make_vec_to_fun(e; byrow = false)
    membernames = Dict{Any, Symbol}()
    # deal with the lhs hand side
    if isa(e, Expr) && (e.head === :(=))
        # e.g. y = mean(x)
        lhs = e.args[1]
        if lhs isa Symbol
            target = QuoteNode(lhs)
        elseif lhs.head === :$
            length(lhs.args) == 1 || throw("Malformed Expression")
            target = lhs.args[1]
        else
            throw("Malformed Expression")
        end
        rhs = e.args[2]
    else
        # e.g. mean(x)
        rhs = e
    end

    # parse the rhs hand side
    rhs = parse_columns!(membernames, rhs)
    if length(keys(membernames)) == 1
        source = first(keys(membernames))
    else
        source = Expr(:vect, keys(membernames)...)
    end
    set = Set(values(membernames))
    # construct the function f, avoiding anonymous function if possible (avoid compilation)
    if iscomposition(rhs, set)
        # e.g. mean(skipmissing(x))
        # Would be nice to also handle x + x but hard (i) order matters (x-y) (ii) duplication matters (x+x)
        f = make_composition(rhs, set)
    else
        f = quote $(Expr(:tuple, values(membernames)...)) ->  $rhs end
    end

    if byrow
        f = quote DataFrames.ByRow($f) end
    end
    
    # put everything together
    if rhs ∈ set
        # e.g. x
        if isa(e, Expr) && (e.head === :(=))
            return quote Base.:(=>)($source, $target) end
        else
            return source
        end
    else
        if isa(e, Expr) && (e.head === :(=))
            return quote Base.:(=>)($source, Base.:(=>)($f, $target)) end
        else
            return quote Base.:(=>)($source, $f) end
        end
    end
end
