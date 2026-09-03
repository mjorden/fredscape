u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

## expenditure() -------------------------------------------------------------

test_that("expenditure() inverts the indirect utility at the original prices", {
  for (f in list(cobb_douglas(0.3), ces(-1, 0.4), leontief(1, 2),
                 perfect_substitutes(1, 2),
                 quasilinear(log, f_prime = function(x) 1 / x))) {
    lv <- optimal_bundle(f, b)$utility
    expect_equal(expenditure(f, b$px, b$py, lv), b$income, tolerance = 1e-6)
  }
})

test_that("closed-form expenditure agrees with the numeric default", {
  strip <- function(f) function(x, y) f(x, y)
  for (f in list(cobb_douglas(0.3, 0.5, A = 2), ces(0.5, 0.3), ces(-2, 0.6, A = 3),
                 leontief(1, 2, A = 2), perfect_substitutes(1, 2, A = 0.5))) {
    expect_equal(expenditure(f, 2, 5, c(3, 7)),
                 expenditure(strip(f), 2, 5, c(3, 7)), tolerance = 1e-5)
  }
})

test_that("expenditure() is homogeneous of degree one in prices and zero at level 0", {
  f <- cobb_douglas(0.3)
  expect_equal(expenditure(f, 4, 10, 5), 2 * expenditure(f, 2, 5, 5))
  expect_equal(expenditure(f, 2, 5, 0), 0)
  expect_equal(expenditure(leontief(1, 1), 2, 5, 0), 0)
})

test_that("expenditure() validates its inputs", {
  expect_error(expenditure("u", 1, 1, 1), "function")
  expect_error(expenditure(u, -1, 1, 1), "positive")
  expect_error(expenditure(u, 1, 1, NA), "finite")
})

## price_change() ------------------------------------------------------------

test_that("price_change() requires exactly one new price", {
  expect_error(price_change(u, b), "exactly one")
  expect_error(price_change(u, b, new_px = 1, new_py = 1), "exactly one")
  expect_error(price_change(u, b, new_px = 0), "positive")
  expect_error(price_change(u, list(), new_px = 1), "budget")
  expect_error(price_change("u", b, new_px = 1), "function")
})

test_that("Hicks compensation keeps the original utility", {
  pc <- hicks(u, b, new_px = 6)
  expect_s3_class(pc, "price_change")
  expect_identical(pc$method, "hicks")
  expect_identical(pc$good, "x")
  bd <- pc$bundles
  expect_identical(bd$stage, c("original", "compensated", "final"))
  expect_equal(bd$utility[2], bd$utility[1])
  expect_equal(bd$income[1], 120)
  expect_equal(bd$income[3], 120)
  expect_true(bd$income[2] > 120)   # a price rise needs more money
})

test_that("Slutsky compensation makes the original bundle just affordable", {
  pc <- slutsky(u, b, new_px = 6)
  bd <- pc$bundles
  expect_equal(bd$income[2], 6 * bd$x[1] + 4 * bd$y[1])
  expect_true(bd$utility[2] >= bd$utility[1])   # can afford A, chooses at least as well
})

test_that("the effects add up and obey the law of compensated demand", {
  for (method in c("hicks", "slutsky")) {
    pc <- price_change(u, b, new_px = 6, method = method)
    e <- pc$effects
    expect_identical(e$effect, c("substitution", "income", "total"))
    expect_equal(e$dx[1] + e$dx[2], e$dx[3])
    expect_equal(e$dy[1] + e$dy[2], e$dy[3])
    expect_true(e$dx[1] < 0)   # dearer x: substitute away from it
    expect_true(e$dx[2] < 0)   # normal good: poorer, buy less
    expect_equal(pc$bundles$x[3], 0.4 * 120 / 6)
  }
})

test_that("a price fall reverses the signs", {
  e <- hicks(u, b, new_px = 1.5)$effects
  expect_true(e$dx[1] > 0)
  expect_true(e$dx[2] > 0)
})

test_that("changing the price of y works symmetrically", {
  pc <- hicks(u, b, new_py = 8)
  expect_identical(pc$good, "y")
  expect_equal(pc$old_price, 4)
  expect_equal(pc$budgets$final$py, 8)
  expect_true(pc$effects$dy[1] < 0)
})

test_that("quasi-linear preferences have no income effect on x", {
  q <- quasilinear(log, f_prime = function(x) 1 / x)
  for (method in c("hicks", "slutsky")) {
    e <- price_change(q, b, new_px = 6, method = method)$effects
    expect_equal(e$dx[2], 0, tolerance = 1e-6)
    expect_equal(e$dx[3], e$dx[1], tolerance = 1e-6)
  }
})

test_that("Leontief preferences have no substitution effect", {
  l <- leontief(1, 2)
  e <- hicks(l, b, new_px = 6)$effects
  expect_equal(e$dx[1], 0)
  expect_equal(e$dy[1], 0)
  expect_equal(e$dx[3], e$dx[2])
})

test_that("Hicks and Slutsky agree on the final bundle but not the compensated one", {
  h <- hicks(u, b, new_px = 6)$bundles
  s <- slutsky(u, b, new_px = 6)$bundles
  expect_equal(h[3, c("x", "y")], s[3, c("x", "y")])
  expect_false(isTRUE(all.equal(h$x[2], s$x[2])))
})

test_that("print.price_change() summarises the move", {
  expect_output(print(hicks(u, b, new_px = 6)), "Hicksian")
  expect_output(print(slutsky(u, b, new_px = 6)), "substitution")
})

## plot_price_change() -------------------------------------------------------

test_that("plot_price_change() builds for both methods and both goods", {
  for (method in c("hicks", "slutsky")) {
    p <- plot_price_change(u, b, new_px = 6, method = method)
    expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
    expect_match(p$labels$title, "rise")
  }
  py <- plot_price_change(u, b, new_py = 2)
  expect_match(py$labels$title, "fall")
  expect_s3_class(ggplot2::ggplot_build(py), "ggplot_built")
})

test_that("plot_price_change() draws two solid budgets and one dashed", {
  p <- plot_price_change(u, b, new_px = 6)
  d <- ggplot2::ggplot_build(p)$data
  expect_identical(nrow(d[[1]]), 2L)
  expect_identical(nrow(d[[2]]), 1L)
  expect_identical(unique(d[[2]]$linetype), "dashed")
  expect_error(plot_price_change(u, b, new_px = 6, goods = "x"), "two labels")
})

test_that("plot_price_change() omits a bracket for a zero-length effect", {
  # Leontief: no substitution effect, so only the income bracket is drawn.
  l <- leontief(1, 2)
  p <- plot_price_change(l, b, new_px = 6)
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  n_text <- sum(vapply(p$layers, function(ly) inherits(ly$geom, "GeomText"), logical(1)))
  expect_identical(n_text, 2L)   # A/B/C labels + one bracket label
})

## Review follow-ups ---------------------------------------------------------

test_that("expenditure() has a quasi-linear method that matches the numeric default", {
  q <- quasilinear(log, f_prime = function(x) 1 / x)
  strip <- function(x, y) q(x, y)
  lv <- c(0.5, 2, 5)
  expect_equal(expenditure(q, 2, 5, lv), expenditure(strip, 2, 5, lv), tolerance = 1e-6)
  # Interior case: x* = py / px = 2.5, y = level - log(2.5).
  expect_equal(expenditure(q, 2, 5, 5), 2 * 2.5 + 5 * (5 - log(2.5)))
  # Level below f(x*): only x is bought, x = exp(level).
  expect_equal(expenditure(q, 2, 5, 0.5), 2 * exp(0.5))
  # It inverts the indirect utility, like every other method.
  b <- budget(120, 3, 4)
  expect_equal(expenditure(q, b$px, b$py, optimal_bundle(q, b)$utility), b$income, tolerance = 1e-8)
  # Every constructor now has a dedicated method.
  for (f in list(cobb_douglas(0.3), ces(-1, 0.4), leontief(1, 2), perfect_substitutes(1, 2), q)) {
    expect_false(identical(utils::getS3method("expenditure", class(f)[1], optional = TRUE), NULL))
  }
})
