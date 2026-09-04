# Axis scales that follow the house conventions

`scale_y_econ()` puts the y labels on the right, where The Economist
prints them, and removes the padding under the baseline so a series that
touches zero sits on the axis.

## Usage

``` r
scale_y_econ(
  ...,
  position = "right",
  expand = ggplot2::expansion(mult = c(0, 0.05))
)

scale_x_econ_date(..., expand = ggplot2::expansion(mult = c(0, 0)))
```

## Arguments

- ...:

  Passed to
  [`ggplot2::scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
  or
  [`ggplot2::scale_x_date()`](https://ggplot2.tidyverse.org/reference/scale_date.html).

- position:

  Axis side. Defaults to `"right"`.

- expand:

  Expansion, see
  [`ggplot2::expansion()`](https://ggplot2.tidyverse.org/reference/expansion.html).

## Value

A ggplot2 scale.

## Details

`scale_x_econ_date()` drops the horizontal padding so a time series runs
the full width of the panel.

## Examples

``` r
library(ggplot2)
ggplot(economics, aes(date, psavert)) +
  geom_line(colour = econ_colours("blue")) +
  scale_x_econ_date() +
  scale_y_econ() +
  theme_econ()
```
