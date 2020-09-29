[![Build Status](https://travis-ci.com/matthieugomez/PairsMacros.jl.svg?branch=master)](https://travis-ci.com/matthieugomez/PairsMacros.jl)
[![Coverage Status](https://coveralls.io/repos/matthieugomez/PairsMacros.jl/badge.svg?branch=master)](https://coveralls.io/r/matthieugomez/PairsMacros.jl?branch=master)

PairsMacros.jl
=============

This package exports two macros, `@cols` and `@rows` that make it easier to construct calls of the form `source => function => target` for use in [`DataFrames.jl`](https://github.com/JuliaData/DataFrames.jl)

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
- first `args` to a function `:call` or `:.` expression
- symbol `missing`
- arguments inside of a splicing/interpolation expression `$()`
- symbols inside  `^()`

## Goals
This package is a minimal alternative to [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl). It makes it easier to work with  [`DataFrames.jl`](https://github.com/JuliaData/DataFrames.jl) `transform`/`combine`/`select`, e.g.:
```julia
using DataFrames, PairsMacros
df = DataFrame(x = [1, 2], y = [3, 4])
transform(df, @cols z = sum(x))
```
