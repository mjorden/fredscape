# fredscape 0.7.0

Market structure (#13): the demand side, and the equilibria that put it
together with the cost side.

* Demand objects: `linear_demand(intercept, slope)` and `demand_fn()` for
  any inverse demand; `price_at()`, `quantity_at()`, `marginal_revenue()`,
  `elasticity()`, `consumer_surplus()`, closed-form for linear.
* Cost objects: `quadratic_cost(fixed, a, b)` and `production_cost()` built
  on `expenditure()`; `total_cost()`, `variable_cost()`, `marginal_cost()`,
  `average_cost()`, `min_average_cost()`.
* `monopoly()`, `cournot(n)` and `perfect_competition(n)` (short run with a
  shutdown check; long run with free entry when `n` is omitted) all return a
  `market_outcome`: price, industry and per-firm quantity, profit, consumer
  and producer surplus, deadweight loss against the `P = MC` benchmark,
  Lerner index and demand elasticity at the outcome.
* `plot_market()` draws demand, marginal revenue and marginal cost with the
  surplus and deadweight-loss areas shaded; `compare_structures()` tabulates
  how price and welfare move as the number of firms grows.

# fredscape 0.6.0

Producer theory (#8), on the same machinery as the consumer side:

* `expansion_path()` -- cost-minimising input bundles as outlay grows.
* `conditional_demand()` -- the cheapest bundle for each output, and its cost.
* `cost_curves()` -- total, average and marginal cost; marginal cost is
  closed-form for Cobb-Douglas and a numerical derivative of `expenditure()`
  otherwise. A `fixed` cost gives average cost its U shape.
* `plot_cost_curves()` for the AC / MC pair, and `plot_producer_choice()`,
  which draws isoquants and an isocost line for any production function.

Also: `check_positive()`'s `zero_ok` argument, flagged as dead code in #4,
now has a caller (`fixed = 0` is a valid cost). #4 is closed by this
release.

# fredscape 0.5.0

The substitution / income decomposition of a price change (#7):

* `price_change()`, with `hicks()` and `slutsky()` shorthands, returns the
  original, compensated and final bundles, the three budgets, and the
  substitution / income / total effects on both goods.
* `expenditure()` -- the expenditure function -- underlies Hicksian
  compensation, with closed forms for every constructor and a `uniroot()`
  fallback. It is also the total-cost function of producer theory, which the
  next release builds on.
* `plot_price_change()` draws the diagram: both budget lines, the dashed
  compensated line, the indifference curves through the bundles, and
  bracketed arrows along the axis for each effect.

# fredscape 0.4.0

Curves traced by the optimal bundle (#6):

* `demand_curve()` and `engel_curve()` evaluate `optimal_bundle()` across a
  vector of prices or incomes and return tidy `(price, quantity)` /
  `(income, quantity)` frames; `price_consumption_path()` and
  `income_consumption_path()` keep the whole bundle.
* `geom_demand()` draws price against quantity the textbook way round;
  `geom_engel()` and `geom_consumption_path()` draw the other two.
* `geom_budget()` accepts a list of budgets and draws one line each, with
  `colour` / `linetype` recycled across the family.

# fredscape 0.3.0

Four more utility (and production) function constructors, each with the same
closed-form `indifference_curve()`, `optimal_bundle()` and `mrs()` methods
that `cobb_douglas()` has (#5):

* `ces(rho, alpha, A)` -- constant elasticity of substitution. Nests
  Cobb-Douglas (rho near 0), perfect substitutes (rho = 1) and Leontief
  (rho to minus infinity); the nesting is tested.
* `leontief(a, b, A)` -- perfect complements. L-shaped contours, the optimum
  always at the kink; `mrs()` returns `Inf` below the ray, `0` above it and
  `NA` on it; `geom_indifference()` draws the vertical arm.
* `perfect_substitutes(a, b, A)` -- linear. Corner solutions, with the
  knife-edge tie returning the midpoint of the budget line and an
  `indeterminate` attribute.
* `quasilinear(f, f_prime)` -- `f(x) + y`. Demand for `x` is independent of
  income; corners are checked; `f_prime` is approximated numerically when not
  supplied.

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

Fixes from the pre-release adversarial review:

* The finite-difference fallback in `mrs()` now scales its step to the
  coordinate and never evaluates the utility on a negative quantity, so it is
  finite near the axes and accurate at large magnitudes instead of silently
  returning `NaN` or a degraded number (#2).
* `indifference_curve()` for Cobb-Douglas returns the documented `NA` at
  `x <= 0` and `level <= 0` rather than `Inf`/`NaN`, matching the numeric
  method (#3).

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
