isatomic(e, set::Set) = false

function isatomic(e::Expr, set::Set)
    if e.head === :call
        if length(e.args) == 1 || ((length(e.args) == 2) && (e.args[2] ∈ set))
            # f() or f(x)
            return true
        elseif length(e.args) == 2
            # f(g(...))
            return isatomic(e.args[2], set)
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
