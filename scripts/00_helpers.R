# 00_helpers.R -- shared by every R script. Not run on its own.
# Loads the two local CSVs, attaches household fields, builds the sample
# (variant 3 = Sindh urban), and defines the weighted statistics.

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(ggplot2); library(scales); library(svglite)
})

# Always work from the repository root, whether the script is run from the
# root or from scripts/
if (!dir.exists("data") && dir.exists("../data")) setwd("..")
dir.create("figures", showWarnings = FALSE)
dir.create("tables",  showWarnings = FALSE)

VARIANT   <- 3        # FA24-BEDS-0xx: last two digits mod 8
PROV_CODE <- 3        # Sindh
AREA_CODE <- 2        # urban

person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
hh     <- read_csv("data/pslm_hh_subset.csv",     show_col_types = FALSE) |>
  select(hhid, hhweight, prov_code, urban_rural)

# Earners: variant persons aged 15-64 with earn_annual > 0
earners <- person |>
  left_join(hh, by = "hhid") |>
  filter(prov_code == PROV_CODE, urban_rural == AREA_CODE,
         age >= 15, age <= 64,
         !is.na(earn_annual), earn_annual > 0)

# Weighted mean: sum(w x) / sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# Weighted p-th quantile (course definition): sort by x, cumulative share of
# weight, smallest x whose cumulative share >= p.
wquant <- function(x, w, p) {
  o <- order(x); x <- x[o]; w <- w[o]
  cs <- cumsum(w) / sum(w)
  x[which(cs >= p)[1]]
}

rs <- function(x) paste0("Rs ", formatC(round(x), format = "d", big.mark = ","))

# Five-year age bands 15-19, ..., 60-64 plotted at midpoints 17, 22, ..., 62
earners <- earners |>
  mutate(band_lo  = 15 + 5 * ((age - 15) %/% 5),
         band     = paste0(band_lo, "-", band_lo + 4),
         band_mid = band_lo + 2)
