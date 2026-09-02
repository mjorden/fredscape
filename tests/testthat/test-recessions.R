test_that("the bundled NBER table is internally consistent", {
  expect_s3_class(nber_recessions, "data.frame")
  expect_named(nber_recessions, c("peak", "trough", "months"))
  expect_s3_class(nber_recessions$peak, "Date")
  expect_s3_class(nber_recessions$trough, "Date")

  expect_true(all(nber_recessions$trough > nber_recessions$peak))
  expect_false(is.unsorted(nber_recessions$peak))

  # No two contractions may overlap.
  n <- nrow(nber_recessions)
  expect_true(all(nber_recessions$peak[-1] > nber_recessions$trough[-n]))
})

test_that("the table covers the recessions everyone checks against", {
  has <- function(peak, trough) {
    any(nber_recessions$peak == as.Date(peak) &
          nber_recessions$trough == as.Date(trough))
  }
  expect_true(has("1929-08-01", "1933-03-01"))  # Great Depression
  expect_true(has("2007-12-01", "2009-06-01"))  # Global financial crisis
  expect_true(has("2020-02-01", "2020-04-01"))  # Covid-19
  expect_identical(min(nber_recessions$peak), as.Date("1857-06-01"))
})

test_that("clip_recessions() keeps only overlapping intervals", {
  bands <- clip_recessions(nber_recessions,
                           from = as.Date("1990-01-01"),
                           to = as.Date("2015-01-01"))
  expect_identical(nrow(bands), 3L)  # 1990-91, 2001, 2007-09
  expect_true(all(bands$trough >= as.Date("1990-01-01")))
  expect_true(all(bands$peak <= as.Date("2015-01-01")))
})

test_that("clip_recessions() trims an interval that straddles the boundary", {
  bands <- clip_recessions(nber_recessions,
                           from = as.Date("2008-06-01"),
                           to = as.Date("2008-12-01"))
  expect_identical(nrow(bands), 1L)
  expect_identical(bands$peak, as.Date("2008-06-01"))
  expect_identical(bands$trough, as.Date("2008-12-01"))
})

test_that("clip_recessions() with no bounds is a pass-through", {
  expect_identical(nrow(clip_recessions(nber_recessions)), nrow(nber_recessions))
})

test_that("clip_recessions() can return nothing", {
  bands <- clip_recessions(nber_recessions,
                           from = as.Date("2021-01-01"),
                           to = as.Date("2023-01-01"))
  expect_identical(nrow(bands), 0L)
})

test_that("clip_recessions() rejects a reversed window", {
  expect_error(
    clip_recessions(nber_recessions, from = "2010-01-01", to = "2000-01-01"),
    "not be later"
  )
})

test_that("annotate_recessions() returns a usable layer", {
  layer <- annotate_recessions(from = "1990-01-01", to = "2015-01-01")
  expect_s3_class(layer, "Layer")

  p <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, uempmed)) +
    layer +
    ggplot2::geom_line()
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
})

test_that("annotate_recessions() rejects a frame without the interval columns", {
  expect_error(annotate_recessions(data = data.frame(a = 1)), "peak")
})

test_that("runs_to_intervals() collapses each run of ones", {
  dates <- seq(as.Date("2000-01-01"), by = "month", length.out = 12)
  value <- c(0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0)

  out <- runs_to_intervals(dates, value)
  expect_identical(nrow(out), 2L)
  expect_identical(out$peak, dates[c(3, 8)])
  expect_identical(out$trough, dates[c(5, 8)])
})

test_that("runs_to_intervals() handles a run that ends at the last observation", {
  dates <- seq(as.Date("2000-01-01"), by = "month", length.out = 4)
  out <- runs_to_intervals(dates, c(0, 0, 1, 1))
  expect_identical(nrow(out), 1L)
  expect_identical(out$trough, dates[4])
})

test_that("runs_to_intervals() handles a run that starts at the first observation", {
  dates <- seq(as.Date("2000-01-01"), by = "month", length.out = 4)
  out <- runs_to_intervals(dates, c(1, 1, 0, 0))
  expect_identical(nrow(out), 1L)
  expect_identical(out$peak, dates[1])
  expect_identical(out$trough, dates[2])
})

test_that("runs_to_intervals() treats NA as not-a-recession", {
  dates <- seq(as.Date("2000-01-01"), by = "month", length.out = 4)
  out <- runs_to_intervals(dates, c(NA, 1, NA, 1))
  expect_identical(nrow(out), 2L)
})

test_that("runs_to_intervals() returns a typed zero-row frame for no recessions", {
  dates <- seq(as.Date("2000-01-01"), by = "month", length.out = 3)
  expect_identical(nrow(runs_to_intervals(dates, c(0, 0, 0))), 0L)
  expect_identical(nrow(runs_to_intervals(as.Date(character(0)), numeric(0))), 0L)
  expect_s3_class(runs_to_intervals(dates, c(0, 0, 0))$peak, "Date")
})

test_that("the bundled table round-trips through the indicator logic", {
  # Rebuild a monthly USREC-style indicator from the bundled table, then
  # collapse it again; the intervals must come back unchanged.
  months <- seq(as.Date("1948-01-01"), as.Date("2023-12-01"), by = "month")
  recent <- nber_recessions[nber_recessions$peak >= as.Date("1948-01-01"), ]
  flag <- vapply(months, function(m) {
    as.integer(any(m >= recent$peak & m <= recent$trough))
  }, integer(1))

  out <- runs_to_intervals(months, flag)
  expect_identical(out$peak, recent$peak)
  expect_identical(out$trough, recent$trough)
})
