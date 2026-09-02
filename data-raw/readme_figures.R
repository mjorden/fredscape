## Render the figures embedded in README.md.
##
## These deliberately use ggplot2's bundled `economics` data set -- itself an
## extract of five FRED series -- so the README can be rebuilt with no API key
## and no network. Re-run with:  Rscript data-raw/readme_figures.R

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(".", quiet = TRUE)
} else {
  library(fredscape)
}
library(ggplot2)

fig <- function(name) file.path("man", "figures", paste0(name, ".png"))
save_fig <- function(plot, name, width = 8, height = 4.6) {
  ggsave(fig(name), plot, width = width, height = height, dpi = 150, bg = "white")
  message("wrote ", fig(name))
}

## 1. Single series with recession shading -----------------------------------

p_unemployment <- ggplot(economics, aes(date, uempmed)) +
  annotate_recessions(from = min(economics$date), to = max(economics$date)) +
  geom_line(colour = econ_colours("blue"), linewidth = 0.8) +
  scale_x_econ_date(date_breaks = "10 years", date_labels = "%Y") +
  scale_y_econ() +
  labs_econ(
    title = "The long wait",
    subtitle = "United States, median duration of unemployment, weeks",
    note = "Shaded areas are NBER-dated recessions",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()

save_fig(econ_masthead(p_unemployment), "README-recessions")

## 2. Several series, indexed --------------------------------------------------

base_date <- min(economics$date)
indexed <- do.call(rbind, lapply(
  c(pce = "pce", pop = "pop", unemploy = "unemploy"),
  function(col) {
    data.frame(
      date = economics$date,
      series = col,
      value = economics[[col]] / economics[[col]][economics$date == base_date] * 100
    )
  }
))
indexed$series <- factor(
  indexed$series,
  levels = c("pce", "pop", "unemploy"),
  labels = c("Consumer spending", "Population", "Unemployed persons")
)

p_index <- ggplot(indexed, aes(date, value, colour = series)) +
  geom_hline(yintercept = 100, colour = econ_colours("muted"), linewidth = 0.3) +
  geom_line(linewidth = 0.8) +
  scale_colour_econ() +
  scale_x_econ_date(date_breaks = "10 years", date_labels = "%Y") +
  scale_y_econ() +
  labs_econ(
    title = "Diverging fortunes",
    subtitle = "United States, indexed to 100 at July 1967",
    source = "FRED, Federal Reserve Bank of St Louis"
  ) +
  theme_econ()

save_fig(econ_masthead(p_index), "README-index")

## 3. The palette itself -------------------------------------------------------

sizes <- c(main = 7L, cool = 3L, contrast = 2L, blues = 7L, redblue = 7L)
swatches <- do.call(rbind, lapply(names(sizes), function(name) {
  cols <- econ_pal(name)(sizes[[name]])
  data.frame(palette = name, i = seq_along(cols), colour = cols,
             stringsAsFactors = FALSE)
}))
swatches$palette <- factor(
  swatches$palette,
  levels = rev(c("main", "cool", "contrast", "blues", "redblue"))
)

p_palette <- ggplot(swatches, aes(i, palette, fill = colour)) +
  geom_tile(width = 0.94, height = 0.72) +
  scale_fill_identity() +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.01))) +
  labs_econ(
    title = "The palette",
    subtitle = "Categorical hues follow The Economist's published data colours"
  ) +
  theme_econ(panel = "white", grid = "none") +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.line.x = element_blank()
  )

save_fig(econ_masthead(p_palette), "README-palette", height = 3)

## 4. Consumer choice ----------------------------------------------------------

u <- cobb_douglas(alpha = 0.4)
b <- budget(income = 120, px = 3, py = 4)

p_choice <- plot_consumer_choice(
  u, b,
  goods = c("Coffee, cups", "Bagels"),
  title = "Breakfast, optimised",
  subtitle = "Cobb-Douglas utility, alpha = 0.4; income 120 at prices 3 and 4",
  source = "fredscape"
)

save_fig(econ_masthead(p_choice), "README-choice", width = 7, height = 5.2)
