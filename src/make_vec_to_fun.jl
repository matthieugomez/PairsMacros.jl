##############################################################################
##
## Code based on https://github.com/JuliaData/DataFramesMeta.jl/pull/152
##
##############################################################################

function addkey!(membernames::OrderedDict, nam)
    if !haskey(membernames, nam)
        membernames[nam] = gensym()
    end
    membernames[nam]
end

parse_columns!(membernames::OrderedDict, x) = x
function parse_columns!(membernames::OrderedDict, q::Symbol)
    addkey!(membernames, QuoteNode(q))
end
function parse_columns!(membernames::OrderedDict, e::Expr)
    if (e.head === :$)
        length(e.args) == 1 || throw("Malformed Expression")
        addkey!(membernames, e.args[1])
    elseif (e.head === :call) && (e.args[1] == :^)
        length(e.args) == 2 || throw("Malformed Expression")
        e.args[2]
    elseif (e.head == :.)
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
        if length(e.args) == 1
            # f() 
            return true
        elseif all(x ∈ set for x ∈ e.args[2:end])
            # f(x) or f(x, y)
            return true
        elseif length(e.args) == 2
            # f(g(...))
            return iscomposition(e.args[2], set)
        end
    end
    false
end

function make_composition(e::Expr, set::Set)
    if e.head === :call
        if length(e.args) == 1
            return e.args[1]
        elseif all(x ∈ set for x ∈ e.args[2:end])
            return e.args[1]
        elseif length(e.args) == 2
            Expr(:call, :(Base.:∘), e.args[1], make_composition(e.args[2], set))
        end
    end
end

function make_vec_to_fun(e::Expr; byrow = false)
    membernames = OrderedDict{Any, Symbol}()
    # deal with the left hand side
    if e.head == :(=) || e.head == :kw
        # e.g. y = mean(x)
        e_left = e.args[1]
        if e_left isa Symbol
            target = QuoteNode(e_left)
        elseif e_left.head === :$
            target = e_left.args[1]
        end
        e_right = e.args[2]
    else
        # e.g. mean(x)
        e_right = e
    end

    # parse the right hand side
    e_right_parsed = parse_columns!(membernames, e_right)
    source = Expr(:vect, keys(membernames)...)
    set = Set(values(membernames))
    # construct the function f
    if e_right_parsed ∈ set
        # e.g. x
        f = Base.identity
    elseif iscomposition(e_right_parsed, set)
        # e.g. mean(skipmissing(x)) or corr(x, y)
        f = make_composition(e_right_parsed, set)
    else
        f = Expr(:->, Expr(:tuple, values(membernames)...), e_right_parsed)
    end

    if byrow
        f = Expr(:call, :(DataFramesMacros.ByRow), f)
    end
    
    # put everything together
    if e.head == :(=) || e.head == :kw
        quote
            $source => $f => $target
        end
    else
        quote
            $source => $f
        end
    end
end

function make_vec_to_fun(e::QuoteNode; byrow = false)
    return e
end

function make_vec_to_fun(args...; byrow = false)
    Expr(:..., Expr(:tuple, (make_vec_to_fun(arg; byrow = byrow) for arg in args)...))
end

