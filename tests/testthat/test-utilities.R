b <- budget(income = 100, px = 2, py = 5)

# Every closed form is checked against the generic numeric path by rebuilding
# the same function without its class.
strip_class <- function(u) {
  f <- function(x, y) u(x, y)
  f
}

on_budget <- function(opt, b) expect_equal(b$px * opt$x + b$py * opt$y, b$income)

## CES -----------------------------------------------------------------------

test_that("ces() validates its parameters", {
  expect_error(ces(rho = 2), "no greater than 1")
  expect_error(ces(rho = 0), "Cobb-Douglas limit")
  expect_error(ces(rho = 0.5, alpha = 1), "between 0 and 1")
  expect_error(ces(rho = 0.5, alpha = 0), "between 0 and 1")
  expect_error(ces(rho = 0.5, A = -1), "positive")
  expect_error(ces(rho = 0.5, kind = "leisure"))
})

test_that("ces() evaluates the formula and records sigma", {
  u <- ces(rho = 0.5, alpha = 0.4, A = 2)
  expect_equal(u(4, 9), 2 * (0.4 * 2 + 0.6 * 3)^2)
  expect_equal(attr(u, "sigma"), 2)
  expect_output(print(u), "sigma = 2")
})

test_that("CES contours are exact for positive and negative rho", {
  for (rho in c(0.5, -1, -3)) {
    u <- ces(rho = rho, alpha = 0.4)
    x <- c(0.5, 1, 2, 5)
    curve <- indifference_curve(u, level = 3, x = x)
    ok <- !is.na(curve$y)
    expect_true(any(ok))
    expect_equal(u(curve$x[ok], curve$y[ok]), rep(3, sum(ok)))
    expect_equal(curve$y[ok], indifference_curve(strip_class(u), level = 3, x = x[ok])$y,
                 tolerance = 1e-6)
  }
})

test_that("CES contours give NA where the level is unattainable", {
  # With rho > 0 the contour meets the x-axis at a finite x; beyond it, no y.
  u <- ces(rho = 0.5, alpha = 0.5)
  curve <- indifference_curve(u, level = 1, x = c(1, 100))
  expect_false(is.na(curve$y[1]))
  expect_true(is.na(curve$y[2]))
  expect_true(all(is.na(indifference_curve(u, level = -1, x = 1:3)$y)))
})

test_that("CES demand satisfies the budget and the tangency condition", {
  u <- ces(rho = -1, alpha = 0.3)
  opt <- optimal_bundle(u, b)
  on_budget(opt, b)
  expect_equal(mrs(u, opt$x, opt$y), b$px / b$py)
  expect_equal(opt$x, optimal_bundle(strip_class(u), b)$x, tolerance = 1e-5)
})

test_that("CES nests Cobb-Douglas as rho -> 0", {
  expect_equal(optimal_bundle(ces(rho = 1e-5, alpha = 0.3), b)$x,
               optimal_bundle(cobb_douglas(0.3), b)$x, tolerance = 1e-3)
})

test_that("CES nests perfect substitutes at rho = 1", {
  u <- ces(rho = 1, alpha = 0.7)
  s <- perfect_substitutes(a = 0.7, b = 0.3)
  expect_equal(optimal_bundle(u, b)$x, optimal_bundle(s, b)$x)
  expect_equal(mrs(u, 2, 3), mrs(s, 2, 3))
})

test_that("CES approaches Leontief as rho -> -Inf", {
  # Convergence is slow: y/x = (px/py)^sigma with sigma = 1/(1 - rho), so
  # rho = -40 is still ~2% off the ray and rho = -200 about 0.3%.
  near <- optimal_bundle(ces(rho = -200, alpha = 0.5), b)$x
  far <- optimal_bundle(ces(rho = -40, alpha = 0.5), b)$x
  target <- optimal_bundle(leontief(1, 1), b)$x
  expect_equal(near, target, tolerance = 5e-3)
  expect_true(abs(near - target) < abs(far - target))
})

## Leontief ------------------------------------------------------------------

test_that("leontief() builds the min function", {
  u <- leontief(a = 1, b = 2, A = 3)
  expect_equal(u(3, 6), 9)
  expect_equal(u(c(1, 5), c(6, 6)), c(3, 9))
  expect_error(leontief(a = 0), "positive")
  expect_output(print(u), "min\\(x / 1, y / 2\\)")
})

test_that("Leontief contours are the horizontal arm from the kink", {
  u <- leontief(a = 1, b = 2)
  curve <- indifference_curve(u, level = 3, x = c(1, 2.9, 3, 4, 10))
  expect_true(all(is.na(curve$y[1:2])))
  expect_equal(curve$y[3:5], c(6, 6, 6))
  expect_true(all(is.na(indifference_curve(u, level = 0, x = 1:3)$y)))
  # Agrees with the smallest-y bisection.
  expect_equal(curve$y[3:5], indifference_curve(strip_class(u), level = 3, x = c(3, 4, 10))$y,
               tolerance = 1e-6)
})

test_that("Leontief optimum sits on the ray and the budget", {
  u <- leontief(a = 1, b = 2)
  opt <- optimal_bundle(u, b)
  on_budget(opt, b)
  expect_equal(opt$x / 1, opt$y / 2)
  expect_equal(opt$x, optimal_bundle(strip_class(u), b)$x, tolerance = 1e-5)
  # Prices change the level, never the proportion.
  opt2 <- optimal_bundle(u, budget(100, 10, 1))
  expect_equal(opt2$x / 1, opt2$y / 2)
})

test_that("Leontief MRS is Inf below the ray, 0 above, NA on it", {
  u <- leontief(a = 1, b = 2)
  expect_identical(mrs(u, c(1, 3, 5), 6), c(Inf, NA_real_, 0))
})

## Perfect substitutes -------------------------------------------------------

test_that("perfect_substitutes() is linear with constant MRS", {
  u <- perfect_substitutes(a = 1, b = 2, A = 2)
  expect_equal(u(3, 4), 22)
  expect_equal(mrs(u, 1:3, 7), rep(0.5, 3))
  expect_output(print(u), "constant MRS = 0.5")
})

test_that("perfect-substitutes contours are lines clipped to the orthant", {
  u <- perfect_substitutes(a = 1, b = 2)
  curve <- indifference_curve(u, level = 4, x = c(0, 2, 4, 5))
  expect_equal(curve$y, c(2, 1, 0, NA))
  # The closed form can place a point exactly on the x-axis (y = 0); the
  # numeric bisection searches y > 0 and so cannot, which is why x = 4 is
  # left out of the agreement check.
  expect_equal(curve$y[1:2], indifference_curve(strip_class(u), level = 4, x = c(0, 2))$y,
               tolerance = 1e-6)
})

test_that("perfect substitutes pick the corner with more utility per dollar", {
  u <- perfect_substitutes(a = 1, b = 2)
  all_y <- optimal_bundle(u, budget(100, 1, 1))
  expect_equal(c(all_y$x, all_y$y), c(0, 100))
  all_x <- optimal_bundle(u, budget(100, 1, 3))
  expect_equal(c(all_x$x, all_x$y), c(100, 0))
  expect_false(attr(all_x, "indeterminate"))
  expect_equal(all_y$x, optimal_bundle(strip_class(u), budget(100, 1, 1))$x, tolerance = 1e-6)
})

test_that("perfect substitutes flag the knife-edge case and return the midpoint", {
  u <- perfect_substitutes(a = 1, b = 2)
  tie <- optimal_bundle(u, budget(100, 1, 2))
  expect_true(attr(tie, "indeterminate"))
  expect_equal(c(tie$x, tie$y), c(50, 25))
  on_budget(tie, budget(100, 1, 2))
})

## Quasi-linear --------------------------------------------------------------

test_that("quasilinear() validates and builds f(x) + y", {
  expect_error(quasilinear("log"), "function")
  expect_error(quasilinear(log, f_prime = 1), "function")
  u <- quasilinear(log, f_prime = function(x) 1 / x)
  expect_equal(u(exp(1), 2), 3)
  expect_output(print(u), "no income effect")
})

test_that("quasi-linear contours are y = level - f(x)", {
  u <- quasilinear(sqrt)
  curve <- indifference_curve(u, level = 5, x = c(0, 4, 9, 36))
  expect_equal(curve$y, c(5, 3, 2, NA))
  # log(0) = -Inf makes y = Inf, which is not a point on the curve.
  expect_true(is.na(indifference_curve(quasilinear(log), level = 1, x = 0)$y))
})

test_that("quasi-linear demand for x has no income effect", {
  u <- quasilinear(log, f_prime = function(x) 1 / x)
  poor <- optimal_bundle(u, budget(100, 2, 5))
  rich <- optimal_bundle(u, budget(500, 2, 5))
  expect_equal(poor$x, 2.5)   # f'(x) = 1/x = px/py = 0.4
  expect_equal(rich$x, 2.5)
  on_budget(poor, budget(100, 2, 5))
  expect_equal(mrs(u, poor$x, poor$y), 0.4)
})

test_that("quasi-linear demand matches the numeric derivative and line search", {
  exact <- quasilinear(log, f_prime = function(x) 1 / x)
  approx <- quasilinear(log)
  expect_equal(optimal_bundle(approx, b)$x, optimal_bundle(exact, b)$x, tolerance = 1e-5)
  expect_equal(optimal_bundle(strip_class(exact), b)$x, optimal_bundle(exact, b)$x, tolerance = 1e-5)
  expect_equal(mrs(approx, 4, 1), 0.25, tolerance = 1e-6)
})

test_that("quasi-linear demand hits the corners", {
  # sqrt: f'(x) = 1/(2 sqrt x) -> only x if the last unit is still worth it.
  u <- quasilinear(sqrt, f_prime = function(x) 0.5 / sqrt(x))
  only_x <- optimal_bundle(u, budget(1, 1, 100))
  expect_equal(c(only_x$x, only_x$y), c(1, 0))
  # A function whose marginal utility starts below the price ratio.
  flat <- quasilinear(function(x) 0.1 * x, f_prime = function(x) rep(0.1, length(x)))
  none <- optimal_bundle(flat, budget(100, 1, 1))
  expect_equal(c(none$x, none$y), c(0, 100))
})

## Plotting ------------------------------------------------------------------

test_that("geom_indifference() draws the vertical arm for Leontief", {
  u <- leontief(1, 2)
  layers <- geom_indifference(u, levels = c(2, 4), xlim = c(0, 10))
  expect_length(layers, 2L)
  p <- ggplot2::ggplot() + layers
  d <- ggplot2::ggplot_build(p)$data
  expect_equal(d[[2]]$x, c(2, 4))
  expect_equal(d[[2]]$y, c(4, 8))
  expect_true(all(is.infinite(d[[2]]$yend)))
})

test_that("plot_consumer_choice() builds for every constructor", {
  us <- list(ces(-1, 0.4), leontief(1, 2), perfect_substitutes(1, 2),
             quasilinear(log, function(x) 1 / x))
  for (u in us) {
    expect_s3_class(ggplot2::ggplot_build(plot_consumer_choice(u, b)), "ggplot_built")
  }
})

## Review follow-ups ---------------------------------------------------------

test_that("CES at rho = 1 is perfect substitutes on the full bundle, at both corners", {
  u <- ces(rho = 1, alpha = 0.4)
  s <- perfect_substitutes(a = 0.4, b = 0.6)
  # y wins the corner here (k would be Inf, and Inf * 0 gave NaN before).
  y_wins <- budget(100, 3, 2)
  expect_equal(optimal_bundle(u, y_wins)[, c("x", "y", "utility")],
               optimal_bundle(s, y_wins)[, c("x", "y", "utility")])
  expect_true(all(is.finite(unlist(optimal_bundle(u, y_wins)))))
  x_wins <- budget(100, 1, 5)
  expect_equal(optimal_bundle(u, x_wins)[, c("x", "y", "utility")],
               optimal_bundle(s, x_wins)[, c("x", "y", "utility")])
  # Expenditure too: min(px / a, py / b) per unit of utility.
  expect_equal(expenditure(u, 3, 2, 30), 30 * min(3 / 0.4, 2 / 0.6))
  expect_equal(expenditure(u, 3, 2, 30), expenditure(s, 3, 2, 30))
  # And the tie carries its flag through.
  expect_true(attr(optimal_bundle(u, budget(100, 0.4, 0.6)), "indeterminate"))
  # Hicks decomposition no longer produces NaN.
  pc <- hicks(u, budget(100, 0.4, 0.6), new_px = 3)
  expect_true(all(is.finite(unlist(pc$bundles[, c("x", "y")]))))
})
