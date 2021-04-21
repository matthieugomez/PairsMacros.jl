[![Build status](https://github.com/matthieugomez/PairsMacros.jl/workflows/CI/badge.svg)](https://github.com/matthieugomez/PairsMacros.jl/actions)

PairsMacros.jl
=============

This package exports two macros, `@cols` and `@rows` that make it easier to construct calls of the form `source => function => target`. This is a minimal alternative to [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl).



## Syntax
```julia
using PairsMacros
@cols z = sum(x)
#> [:x] => sum => :z
@rows z = x + y
#> [:x, :y] => ByRow(+) => :z
```

Use `$` to substitute the name of certain columns by symbols
```julia
u = :y
@cols z = sum($u)
#> [:y] => sum => :z
@cols $u = sum(x)
#> [:x] => sum => :y
u = "my variable name"
@cols z = sum($u)
"my variable name" => sum => :z
```

Use `esc` to denote variables that do not refer to columns
```julia
u = [0.25, 0.75]
@cols z = quantile(y, esc(u))
#> [:y] => (x -> quantile(x, u)) => :z
@cols z = map(esc(cos), y)
#> [:y] => (x -> map(cos, x)) => :z
@rows z = tryparse(esc(Float64), y)
#> [:y] => ByRow(x -> tryparse(Float64, x)) => :z
```

## Details
All symbols are assumed to refer to columns, with the exception of:
- symbol `missing`
- first `args` of a `:call` or `:.` expression (e.g. function calls)
- arguments inside of a splicing/interpolation expression `$()`
- arguments inside  `esc()`

## DataFrames
The macros can be used as arguemnts in `transform`, `select`, `subset`, etc 
```julia
using DataFrames, PairsMacros
df = DataFrame(x = [1, 2], y = [3, 4])
transform(df, @cols z = sum(x))
```