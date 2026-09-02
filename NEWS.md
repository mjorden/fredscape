# fredscape 0.2.0

Consumer and producer theory, drawn in the house style.

* `cobb_douglas()` builds a callable utility or production function that
  remembers its parameters; `print()` reports returns to scale.
* `budget()` and `budget_line()` describe a budget constraint or isocost.
* `indifference_curve()` returns contours: closed form for Cobb-Douglas, a
  `uniroot()` fallback for any other function of two goods (Leontief, CES,
  quasi-linear, ...).
* `optimal_bundle()` solves the consumer's problem: Cobb-Douglas share rule in
  closed form, `optimize()` along the budget line otherwise, with the corners
  checked so perfect substitutes land on the right axis.
* `mrs()` gives the marginal rate of substitution, closed form or finite
  difference.
* `geom_indifference()`, `geom_budget()` and `geom_optimum()` add each piece
  to a ggplot; `plot_consumer_choice()` composes the whole chart with the
  curves labelled by level.

# fredscape 0.1.0

First release.

* FRED client: `fred_series()`, `fred_series_info()`, `fred_search()` and
  `fred_recessions()`, all returning plain data frames. Missing observations
  (`"."` in the API) become `NA` without a coercion warning.
* Key handling via the `FRED_API_KEY` environment variable, with local shape
  validation and scrubbing of anything key-shaped out of API error messages.
* `theme_econ()`, with `"blue"`, `"white"` and `"dark"` panel styles.
* Colour scales over the Economist data palette, plus sequential and diverging
  ramps: `scale_colour_econ()`, `scale_fill_econ()`, `scale_colour_econ_c()`,
  `scale_fill_econ_c()`, `econ_pal()`, `econ_colours()`.
* `labs_econ()` for title, subtitle and a formatted source line;
  `scale_y_econ()` and `scale_x_econ_date()` for the axis conventions.
* `econ_masthead()` for the red block above the title.
* `annotate_recessions()` and the bundled `nber_recessions` table, covering
  every NBER-dated US contraction from 1857 to 2020.
