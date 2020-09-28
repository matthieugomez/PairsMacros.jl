[![Build Status](https://travis-ci.com/matthieugomez/PairsMacros.jl.svg?branch=master)](https://travis-ci.com/matthieugomez/PairsMacros.jl)
[![Coverage Status](https://coveralls.io/repos/matthieugomez/PairsMacros.jl/badge.svg?branch=master)](https://coveralls.io/r/matthieugomez/PairsMacros.jl?branch=master)


PairsMacros.jl
=============

This package exports two macros, `@cols` and `@rows` that make it easier to construct calls of the form `args => function => name`.

```julia
using PairsMacros
@cols(z = sum(x))
#> :x => sum => :z
@rows(z = x + y)
#> [:x, :y] => ByRow(+) => :z
```

Use `$` to substitute the name of certain columns by symbols
```julia
u = :y
@cols(z = sum($u))
#> [:y] => sum => :z
@cols($u = sum(x))
#> [:x] => sum => :y
```

Use `^` to denote variables that do not refer to columns
```julia
u = [0.25, 0.75]
@cols(z = quantile(y, ^(u)))
#> [:y] => x -> quantile(x, u) => :z
@cols(z = map(^(cos), y)
#> [:y] => x -> map(cos, x) => :z
@rows(z = tryparse(^(Float64), y)
#> [:y] => x -> tryparse(Float64, x) => :z
```

These macros are intended to be used within `transform`/`combine`/`select` from  [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl). 

Compared to [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl), the approach is minimal in the sense that it only exports two macros `@cols` and `@rows`. The syntax is also slightly different: refer to variable names using `x` instead of `:x`.
