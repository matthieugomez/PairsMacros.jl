module PairsMacros

const SUBSTITUTE = :$
const LEAVEALONE = :^

include("utils.jl")

macro cols(arg)
    esc(rewrite(arg, false))
end

macro rows(arg)
    esc(rewrite(arg, true))
end

function rewrite(e, byrow)
    if isa(e, Expr) && (e.head === :(=))
        # e.g. y = mean(x)
        lhs = e.args[1]
        if lhs isa Symbol
            target = QuoteNode(lhs)
        elseif lhs.head === SUBSTITUTE
            target = lhs.args[1]
        end
        source, fn, has_fn = rewrite_rhs(e.args[2], byrow)
        if has_fn
            out = quote $source => $fn => $target end
        else
            out = quote $source => $target end
        end
    else
        # e.g. mean(x)
        source, fn, has_fn = rewrite_rhs(e, byrow)
        if has_fn
            out = quote $source => $fn end
        else
            out = source
        end
    end
    return out
end

function rewrite_rhs(rhs, byrow)
    membernames = Dict{Any, Symbol}()
    body = parse_columns!(membernames, rhs)
    k, v = keys(membernames), values(membernames)
    if length(k) == 1
        source = first(k)
    else
        source = Expr(:vect, k...)
    end
    if is_circ(body, v)
        # e.g. mean(skipmissing(x))
        # in this case, use mean ∘ skipmissing
        # this avoids precompilation + allows fast path
        fn = make_circ(body, v)
    else
        # in this case, use anonymous function
        fn = quote $(Expr(:tuple, v...)) -> $body end
    end
    if byrow
        fn = quote DataFrames.ByRow($fn) end
    end
    return source, fn, body ∉ v
end

parse_columns!(membernames::Dict, x) = x
function parse_columns!(membernames::Dict, x::Symbol)
    if x === :missing
        x
    else
        addkey!(membernames, QuoteNode(x))
    end
end
function parse_columns!(membernames::Dict, e::Expr)
    if e.head === SUBSTITUTE
        # e.g. $(x)
        addkey!(membernames, e.args[1])
    elseif (e.head === :call) && (e.args[1] == LEAVEALONE)
        # e.g. ^(x)
        e.args[2]
    elseif (e.head === :.) | (e.head === :call)
        # e.g. f(x) or f.(x)
        Expr(e.head, e.args[1], 
            (parse_columns!(membernames, x) for x in Iterators.drop(e.args, 1))...)
    else
        Expr(e.head, 
            (parse_columns!(membernames, x) for x in e.args)...)
    end
end

function addkey!(membernames::Dict, nam)
    if !haskey(membernames, nam)
        membernames[nam] = gensym()
    end
    membernames[nam]
end

# when Cols() implemented in DataFrames.jl, 
# @cols(f, r".*") could be used to return Cols(r".*") .=> f
export @rows, @cols

end