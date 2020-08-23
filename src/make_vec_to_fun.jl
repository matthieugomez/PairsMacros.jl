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
    if (e.head === :$)
        length(e.args) == 1 || throw("Malformed Expression")
        addkey!(membernames, e.args[1])
    elseif (e.head == :.)
        length(e.args) == 2 || throw("Malformed Expression")
        Expr(:., e.args[1], parse_columns!(membernames, e.args[2]))
    elseif e.head === :call
        if e.args[1] == :^
            length(e.args) == 2 || throw("Malformed Expression")
            e.args[2]
        elseif length(e.args) > 1
            Expr(e.head, e.args[1], (parse_columns!(membernames, x) for x in e.args[2:end])...)
        else
            e
        end
    else
        Expr(e.head, (parse_columns!(membernames, x) for x in e.args)...)
    end
end

isterminal(e) = false
isterminal(e::Symbol) = true
isterminal(e::Expr) = e.head === :$

function iscomposition(e::Expr)
    if e.head === :call && (e.args[1] !== :^)
        if length(e.args) == 1
            # f()
            return true
        elseif length(e.args) == 2
            if isterminal(e.args[2])
                # f(x)
                return true
            else
                # f(g(...))
                return iscomposition(e.args[2])
            end
        end
    end
    false
end

function make_composition(e::Expr)
    if length(e.args) == 1
        # f()
        e.args[1]
    elseif isterminal(e.args[2])
        e.args[1]
    else
        Expr(:call, Base.:∘, e.args[1], make_composition(e.args[2]))
    end
end

function make_vec_to_fun(e::Expr; byrow = false)
    funname = gensym()
    membernames = Dict{Any, Symbol}()

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

    # construct the function f
    if isterminal(e_right)
        # e.g. x
        f = identity
    elseif (e_right isa Expr) && (e_right.head === :call) && (length(e_right.args) > 1) && all(x -> x isa Symbol, e_right.args[2:end])
        # e.g. corr(x, y)
        f = e_right.args[1]
    elseif (e_right isa Expr) && iscomposition(e_right)
        # e.g. mean(skipmissing(x))
        f = make_composition(e_right)
    else
        f = quote
                function $funname($(values(membernames)...))
                    $e_right_parsed
                end
            end
    end
    if byrow
        f = quote ByRow($f) end
    end
    source = Expr(:vect, keys(membernames)...)
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

