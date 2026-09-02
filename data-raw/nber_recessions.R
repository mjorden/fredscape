## Build the bundled NBER recession table.
##
## Source: National Bureau of Economic Research, US Business Cycle Expansions
## and Contractions, <https://www.nber.org/research/data/
## us-business-cycle-expansions-and-contractions>. The NBER dates turning
## points to a month; a peak is the last month of the expansion and a trough
## the last month of the contraction, so the shaded band conventionally runs
## from the peak month to the trough month.
##
## Re-run with:  Rscript data-raw/nber_recessions.R

peaks <- c(
  "1857-06", "1860-10", "1865-04", "1869-06", "1873-10", "1882-03",
  "1887-03", "1890-07", "1893-01", "1895-12", "1899-06", "1902-09",
  "1907-05", "1910-01", "1913-01", "1918-08", "1920-01", "1923-05",
  "1926-10", "1929-08", "1937-05", "1945-02", "1948-11", "1953-07",
  "1957-08", "1960-04", "1969-12", "1973-11", "1980-01", "1981-07",
  "1990-07", "2001-03", "2007-12", "2020-02"
)

troughs <- c(
  "1858-12", "1861-06", "1867-12", "1870-12", "1879-03", "1885-05",
  "1888-04", "1891-05", "1894-06", "1897-06", "1900-12", "1904-08",
  "1908-06", "1912-01", "1914-12", "1919-03", "1921-07", "1924-07",
  "1927-11", "1933-03", "1938-06", "1945-10", "1949-10", "1954-05",
  "1958-04", "1961-02", "1970-11", "1975-03", "1980-07", "1982-11",
  "1991-03", "2001-11", "2009-06", "2020-04"
)

stopifnot(length(peaks) == length(troughs))

nber_recessions <- data.frame(
  peak = as.Date(paste0(peaks, "-01")),
  trough = as.Date(paste0(troughs, "-01")),
  stringsAsFactors = FALSE
)

nber_recessions$months <- as.integer(round(
  as.numeric(nber_recessions$trough - nber_recessions$peak) / 30.4375
))

## Invariants: every contraction ends after it starts, the list is in order,
## and no two contractions overlap.
stopifnot(
  all(nber_recessions$trough > nber_recessions$peak),
  !is.unsorted(nber_recessions$peak),
  all(nber_recessions$peak[-1] > nber_recessions$trough[-nrow(nber_recessions)])
)

dir.create("data", showWarnings = FALSE)
save(nber_recessions, file = "data/nber_recessions.rda", compress = "bzip2")
message("Wrote data/nber_recessions.rda: ", nrow(nber_recessions), " recessions.")
