f <- cobb_douglas(0.3, 0.5, A = 2, kind = "production")   # decreasing returns
crs <- cobb_douglas(0.4, kind = "production")               # constant returns

test_that("the Cobb-Douglas expansion path is a ray with the right slope", {
  ep <- expansion_path(f, w = 20, r = 30, outlays = c(300, 600, 900))
  expect_named(ep, c("outlay", "x", "y", "output"))
  expect_equal(20 * ep$x + 30 * ep$y, ep$outlay)
  # y / x = (beta / alpha) * (w / r)
  expect_equal(ep$y / ep$x, rep((0.5 / 0.3) * (20 / 30), 3))
  expect_equal(ep$output, f(ep$x, ep$y))
  # Decreasing returns: tripling the outlay less than triples the output.
  expect_true(ep$output[3] / ep$output[1] < 3)
})

test_that("conditional demand produces exactly the requested output at least cost", {
  cd <- conditional_demand(f, w = 20, r = 30, q = c(5, 10, 20))
  expect_named(cd, c("output", "x", "y", "cost"))
  expect_equal(f(cd$x, cd$y), cd$output)
  expect_equal(20 * cd$x + 30 * cd$y, cd$cost)
  # Any other bundle on the same isocost produces no more.
  other_x <- cd$x[1] * 1.3
  other_y <- (cd$cost[1] - 20 * other_x) / 30
  expect_true(f(other_x, other_y) < cd$output[1])
})

test_that("cost curves follow the closed form for Cobb-Douglas", {
  q <- c(5, 10, 20)
  cc <- cost_curves(f, w = 20, r = 30, q = q)
  expect_named(cc, c("output", "total", "average", "marginal"))
  expect_equal(cc$total, expenditure(f, 20, 30, q))
  expect_equal(cc$average, cc$total / q)
  # C(q) = k q^(1/d): MC = C / (d q), and MC > AC under decreasing returns.
  expect_equal(cc$marginal, cc$total / (0.8 * q))
  expect_true(all(cc$marginal > cc$average))
  # Doubling output costs more than double.
  expect_true(cc$total[2] > 2 * cc$total[1])
})

test_that("constant returns give flat, equal average and marginal cost", {
  for (g in list(crs, ces(-1, 0.4, kind = "production"), leontief(1, 2, kind = "production"))) {
    cc <- cost_curves(g, w = 20, r = 30, q = c(1, 5, 25))
    expect_equal(cc$average, rep(cc$average[1], 3))
    expect_equal(cc$marginal, cc$average, tolerance = 1e-6)
  }
})

test_that("closed-form marginal cost agrees with the numeric derivative", {
  strip <- function(g) function(x, y) g(x, y)
  q <- c(4, 8, 16)
  expect_equal(cost_curves(f, 20, 30, q)$marginal,
               cost_curves(strip(f), 20, 30, q)$marginal, tolerance = 1e-4)
})

test_that("a fixed cost gives average cost its U shape and leaves marginal cost alone", {
  q <- seq(1, 40, by = 1)
  base <- cost_curves(f, 20, 30, q)
  with_fixed <- cost_curves(f, 20, 30, q, fixed = 150)
  expect_equal(with_fixed$marginal, base$marginal)
  expect_equal(with_fixed$total, base$total + 150)
  ac <- with_fixed$average
  turning <- which.min(ac)
  expect_true(turning > 1 && turning < length(q))
  expect_true(all(diff(ac[seq_len(turning)]) < 0))
  expect_true(all(diff(ac[turning:length(q)]) > 0))
  # MC crosses AC at its minimum.
  expect_true(with_fixed$marginal[turning - 1] < ac[turning - 1])
  expect_true(with_fixed$marginal[turning + 1] > ac[turning + 1])
})

test_that("the producer helpers validate their inputs", {
  expect_error(expansion_path("f", 1, 1, 1), "function")
  expect_error(expansion_path(f, w = 0, r = 1, outlays = 1), "positive")
  expect_error(conditional_demand(f, 1, 1, q = c(1, -1)), "positive")
  expect_error(cost_curves(f, 1, 1, q = 1, fixed = -5), "non-negative")
  expect_error(cost_curves(f, 1, -1, q = 1), "positive")
})

test_that("plot_cost_curves() builds with two labelled lines", {
  p <- plot_cost_curves(f, 20, 30, q = seq(1, 40, by = 0.5), fixed = 150)
  expect_s3_class(p, "ggplot")
  built <- ggplot2::ggplot_build(p)
  expect_identical(length(unique(built$data[[1]]$group)), 2L)
  expect_identical(nrow(built$data[[2]]), 2L)   # one end label per curve
  expect_match(p$labels$subtitle, "fixed cost 150")
  expect_no_match(plot_cost_curves(f, 20, 30, q = 1:5)$labels$subtitle, "fixed")
})

test_that("plot_producer_choice() uses the producer vocabulary for any function", {
  p <- plot_producer_choice(f, budget(600, 20, 30))
  expect_identical(p$labels$title, "Cost minimisation")
  expect_identical(p$labels$x, "Labour")
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  # A plain function with no kind attribute still gets the labels.
  plain <- function(x, y) x^0.5 * y^0.5
  q <- plot_producer_choice(plain, budget(600, 20, 30), inputs = c("L", "K"))
  expect_identical(q$labels$title, "Cost minimisation")
  expect_match(q$labels$subtitle, "Outlay")
  expect_error(plot_producer_choice("f", budget(1, 1, 1)), "function")
})
