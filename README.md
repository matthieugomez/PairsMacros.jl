DataFramesMacros.jl
=============

This package exports two macros, `@cols` and `@rows` that construct calls of the form `args => function => name`.

```julia
using DataFramesMacros
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
```

These macros are intended to be used within `transform`/`combine`/`select`/`filter` from  [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl), e.g.

```julia
using DataFrames, DataFramesMacros
df = DataFrame(x = [1, 2], y = [3, 4])
combine(df, @cols(x_sum = sum(x), y_sum = sum(y)))
#> combine(df, :x => sum => :x_sum, :y => sum => :y_sum)
transform(df, @rows(z = x + y))
#> transform(df, [:x, :y] => ByRow(+) => :z)
filter(@cols(x > 1), df)
#> filter(:x => >(1), df)
```

This package builds on the code from [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl). However, the approach is different: the same macro can be used for `transform`/`combine`/`select`/`filter` etc. 



