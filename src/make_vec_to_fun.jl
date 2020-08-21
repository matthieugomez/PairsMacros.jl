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
    elseif e.head == :.
        Expr(:., e.args[1], replace_syms!(e.args[2], membernames))
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


isterminal(e) = false
isterminal(e::Symbol) = true
isterminal(e::Expr) = e.head === :$

function iscomposition(e::Expr)
    if e.head === :call && (e.args[1] !== :^)
        if length(e.args) == 1
            true
        elseif length(e.args) == 2
            if isterminal(e.args[2])
                true
            else
                iscomposition(e.args[2])
            end
        else
            false
        end
    else
        false
    end
end

function make_composition(e::Expr)
    if length(e.args) == 1
        e.args
    elseif isterminal(e.args[2])
        e.args[1]
    else
        Expr(:call, :∘, e.args[1], make_composition(e.args[2]))
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
        input = kw.args[2]
    else
        input = kw
    end
    body = replace_syms!(input, membernames)
    if (input isa Expr) && (input.head === :call) && (length(input.args) > 1) && all(isterminal, input.args[2:end])
        # like corr(x, y)
        f = input.args[1]
    elseif (input isa Expr) && iscomposition(input)
        # like mean(skipmissing(x))
        f = make_composition(input)
    elseif isterminal(input)
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


