DataFramesMacros.jl
=============

This package exports two macros, `@cols` and `@rows` that make it easier to construct calls of the form `args => function => name`.

```julia
using DataFramesMacros
@cols(z = mean(x))
#> :x => mean => :z
@rows(z = x + y)
#> [:x, :y] => ByRow(+) => :z
```

Use `$` to substitute the name of certain columns by symbols
```julia
u = :y
@cols(z = sum($u))
#> [:y] => sum => :z)
@cols($u = sum(x))
#> [:x] => sum => :y)
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
See [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl) for an alternative approach that define different macros for `transform`/`combine`/`select`/`filter` etc.



