# e.g. mean(skipmissing(x)) becomes skipmissing ∘ mean
# this avoids anonymous function to avoid compilation

is_circ(e, set) = false
function is_circ(e::Expr, set)
    if e.head === :call
        if length(e.args) == 1 || ((length(e.args) == 2) && (e.args[2] ∈ set))
            # f() or f(x)
            return true
        elseif length(e.args) == 2
            # f(g(...))
            return is_circ(e.args[2], set)
        end
    end
    return false
end

function make_circ(e::Expr, set)
    if e.head === :call
        if length(e.args) == 1 || ((length(e.args) == 2) && (e.args[2] ∈ set))
            return e.args[1]
        elseif length(e.args) == 2
            return Expr(:call, :(Base.:∘), e.args[1], make_circ(e.args[2], set))
        end
    end
end
