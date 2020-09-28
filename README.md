[![Build Status](https://travis-ci.com/matthieugomez/PairsMacros.jl.svg?branch=master)](https://travis-ci.com/matthieugomez/PairsMacros.jl)
[![Coverage Status](https://coveralls.io/repos/matthieugomez/PairsMacros.jl/badge.svg?branch=master)](https://coveralls.io/r/matthieugomez/PairsMacros.jl?branch=master)

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
## Goals

These macros make it easier to construct Pairs for  [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) `transform`/`combine`/`select`, e.g.:
```julia
using DataFrames, PairsMacros
df = DataFrame(x = [1, 2], y = [3, 4])
transform(df, @cols z = sum(x))
```
This package is a minimal alternative to [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl).
