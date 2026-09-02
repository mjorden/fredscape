test_that("theme_econ() returns a complete theme", {
  th <- theme_econ()
  expect_s3_class(th, "theme")
  expect_true(isTRUE(attr(th, "complete")))
})

test_that("the base theme is merged in, not replaced", {
  # theme(complete = TRUE) would discard theme_minimal() and silently ignore
  # base_size / base_family; these elements only exist if the merge happened.
  th <- theme_econ()
  expect_false(is.null(th$text))
  expect_false(is.null(th$line))
})

test_that("base_size actually reaches the text elements", {
  expect_identical(theme_econ(base_size = 12)$text$size, 12)
  expect_identical(theme_econ(base_size = 18)$text$size, 18)
})

test_that("base_family reaches the text elements", {
  expect_identical(theme_econ(base_family = "serif")$text$family, "serif")
})

test_that("panel styles set distinct surfaces", {
  blue <- theme_econ(panel = "blue")
  white <- theme_econ(panel = "white")
  dark <- theme_econ(panel = "dark")

  expect_identical(blue$panel.background$fill, unname(econ_colours("panel_blue")))
  expect_identical(white$panel.background$fill, "#FFFFFF")
  expect_identical(dark$panel.background$fill, unname(econ_colours("panel_dark")))

  # Dark panels need light ink, or the labels vanish.
  expect_identical(dark$axis.text$colour, unname(econ_colours("ink_light")))
})

test_that("an unknown panel style is rejected", {
  expect_error(theme_econ(panel = "neon"))
})

test_that("the grid argument controls which gridlines are drawn", {
  y <- theme_econ(grid = "y")
  expect_s3_class(y$panel.grid.major.y, "element_line")
  expect_s3_class(y$panel.grid.major.x, "element_blank")

  x <- theme_econ(grid = "x")
  expect_s3_class(x$panel.grid.major.x, "element_line")
  expect_s3_class(x$panel.grid.major.y, "element_blank")

  both <- theme_econ(grid = "both")
  expect_s3_class(both$panel.grid.major.x, "element_line")
  expect_s3_class(both$panel.grid.major.y, "element_line")

  none <- theme_econ(grid = "none")
  expect_s3_class(none$panel.grid.major.x, "element_blank")
  expect_s3_class(none$panel.grid.major.y, "element_blank")
})

test_that("titles hang off the plot, not the panel", {
  th <- theme_econ()
  expect_identical(th$plot.title.position, "plot")
  expect_identical(th$plot.caption.position, "plot")
  expect_identical(th$plot.title$hjust, 0)
  expect_identical(th$plot.caption$hjust, 0)
})

test_that("scale_y_econ() puts labels on the right with no padding below", {
  sc <- scale_y_econ()
  expect_identical(sc$position, "right")
  expect_identical(as.numeric(sc$expand)[1:2], c(0, 0))
})

test_that("scale_x_econ_date() removes horizontal padding", {
  expect_identical(as.numeric(scale_x_econ_date()$expand), c(0, 0, 0, 0))
})

test_that("labs_econ() formats a single source", {
  l <- labs_econ(title = "T", source = "FRED")
  expect_identical(l$caption, "Source: FRED")
  expect_identical(l$title, "T")
  expect_null(l$x)
  expect_null(l$y)
})

test_that("labs_econ() pluralises and joins multiple sources", {
  expect_identical(labs_econ(sources = c("FRED", "BLS"))$caption, "Sources: FRED; BLS")
})

test_that("labs_econ() stacks a note above the source line", {
  expect_identical(
    labs_econ(note = "Seasonally adjusted", source = "FRED")$caption,
    "Seasonally adjusted\nSource: FRED"
  )
})

test_that("labs_econ() with no caption content leaves the caption unset", {
  expect_null(labs_econ(title = "T")$caption)
})

test_that("labs_econ() refuses ambiguous source arguments", {
  expect_error(labs_econ(source = "a", sources = "b"), "not both")
})
