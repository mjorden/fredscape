# Coordinates of a budget line

Coordinates of a budget line

## Usage

``` r
budget_line(b, n = 2L)
```

## Arguments

- b:

  A
  [`budget()`](https://mjorden.github.io/fredscape/reference/budget.md).

- n:

  Number of points. Two is enough for a straight line; more is useful if
  you want to attach a colour or size aesthetic along it.

## Value

A data frame with `x` and `y` columns running from the `y` intercept to
the `x` intercept.

## Examples

``` r
budget_line(budget(100, 2, 5))
#>    x  y
#> 1  0 20
#> 2 50  0
```
