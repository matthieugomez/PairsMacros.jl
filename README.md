[![Build status](https://github.com/matthieugomez/PairsMacros.jl/workflows/CI/badge.svg)](https://github.com/matthieugomez/PairsMacros.jl/actions)

PairsMacros.jl
=============

This package exports two macros, `@cols` and `@rows` that make it easier to construct calls of the form `source => function => target`.

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

Use `^` to denote variables that do not refer to columns
```julia
u = [0.25, 0.75]
@cols z = quantile(y, ^(u))
#> [:y] => (x -> quantile(x, u)) => :z
@cols z = map(^(cos), y)
#> [:y] => (x -> map(cos, x)) => :z
@rows z = tryparse(^(Float64), y)
#> [:y] => ByRow(x -> tryparse(Float64, x)) => :z
```

## Details
All symbols are assumed to refer to columns, with the exception of:
- symbol `missing`
- first `args` of a `:call` or `:.` expression (e.g. function calls)
- arguments inside of a splicing/interpolation expression `$()`
- arguments inside  `^()`

## Goals
This package is a minimal alternative to [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl). Its goal is to makes it easier construct Pairs for [`DataFrames.jl`](https://github.com/JuliaData/DataFrames.jl) `transform`/`combine`/`select`, e.g.:
```julia
using DataFrames, PairsMacros
df = DataFrame(x = [1, 2], y = [3, 4])
transform(df, @cols z = sum(x))
```

In the context of a `transform`, `combine` or `select` calls, one can add multiple transformations:
```julia
transform(df, @cols sum(x) first(x))
```