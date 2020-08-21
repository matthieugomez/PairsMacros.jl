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
        length(e.args) == 1 || throw("This should not happen. Please file an issue Github")
        addkey!(membernames, e.args[1])
    elseif (e.head == :.)
        length(e.args) == 2 || throw("This should not happen. Please file an issue Github")
        Expr(:., e.args[1], parse_columns!(membernames, e.args[2]))
    elseif e.head === :call
        if e.args[1] == :^
            length(e.args) == 2 || throw("This should not happen. Please file an issue Github")
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
        e.args
    elseif isterminal(e.args[2])
        e.args[1]
    else
        Expr(:call, Base.:∘, e.args[1], make_composition(e.args[2]))
    end
end

function make_vec_to_fun(kw::Expr; byrow = false)
    funname = gensym()
    membernames = Dict{Any, Symbol}()

    # deal with the left hand side
    if kw.head == :(=) || kw.head == :kw
        # e.g. y = mean(x)
        left = kw.args[1]
        if left isa Symbol
            newcol = QuoteNode(left)
        elseif left.head === :$
            newcol = left.args[1]
        end
        right = kw.args[2]
    else
        # e.g. mean(x)
        right = kw
    end

    # parse the right hand side
    body = parse_columns!(membernames, right)
    # construct the function f
   if (right isa Expr) && (right.head === :call) && (length(right.args) > 1) && all(x -> x isa Symbol, right.args[2:end])
        # e.g. corr(x, y)
        f = right.args[1]
    elseif (right isa Expr) && iscomposition(right)
        # e.g. mean(skipmissing(x))
        f = make_composition(right)
    elseif isterminal(right)
        # e.g. x
        f = identity
    else
        f = quote
                function $funname($(values(membernames)...))
                    $body 
                end
            end
    end
    if byrow
        f = quote ByRow($f) end
    end

    cols = Expr(:vect, keys(membernames)...)

    # put everything together
        if kw.head == :(=) || kw.head == :kw
            quote
                $cols => $f => $newcol
            end
        else
            quote
                $cols => $f
            end
        end

end


function make_vec_to_fun(kw::QuoteNode; byrow = false)
    return kw
end


function make_vec_to_fun(args...; byrow = false)
    Expr(:..., Expr(:tuple, (make_vec_to_fun(arg; byrow = byrow) for arg in args)...))
end

