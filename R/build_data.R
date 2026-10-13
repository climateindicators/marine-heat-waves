# Build tidy long-format data for the Marine Heat Waves indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Marine Heat Waves",
  slug                    = "marine-heat-waves",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-marine-heat-waves/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/marine-heat-waves_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 3: Areas Affected by Marine Heat Waves by U.S. Coastal Region, 1982-2023 ----

f3_path <- file.path(raw_dir, "marine-heat-waves_fig-3.csv")
f3_meta <- read_epa_preamble(f3_path)
f3_raw  <- read_epa_csv(f3_path)

# Each series header is "<region> <category>", where category is the marine
# heat wave severity class. Region and category are split on the last space,
# so a region name may itself contain spaces.
F3_REGIONS    <- c("West Coast", "Gulf of Mexico", "Southeast", "Northeast", "Alaska", "Hawaii")
F3_CATEGORIES <- c("Moderate", "Strong", "Severe", "Extreme")

assert_headers(
  f3_raw,
  id_cols          = "Year",
  expected_headers = c("West Coast Moderate", "West Coast Strong", "West Coast Severe", "West Coast Extreme", "Gulf of Mexico Moderate", "Gulf of Mexico Strong", "Gulf of Mexico Severe", "Gulf of Mexico Extreme", "Southeast Moderate", "Southeast Strong", "Southeast Severe", "Southeast Extreme", "Northeast Moderate", "Northeast Strong", "Northeast Severe", "Northeast Extreme", "Alaska Moderate", "Alaska Strong", "Alaska Severe", "Alaska Extreme", "Hawaii Moderate", "Hawaii Strong", "Hawaii Severe", "Hawaii Extreme"),
  what             = "marine-heat-waves_fig-3.csv"
)

# One row per year x region x category, values kept as EPA's character strings.
f3_series <- setdiff(names(f3_raw), "Year")
f3 <- f3_raw |>
  tidyr::pivot_longer(all_of(f3_series), names_to = "series", values_to = "value") |>
  mutate(
    year     = Year,
    region   = sub(" [^ ]+$", "", series),
    category = sub("^.* ", "", series)
  ) |>
  select(year, region, category, value)

stopifnot(
  setequal(unique(f3$region), F3_REGIONS),
  setequal(unique(f3$category), F3_CATEGORIES),
  !anyDuplicated(f3[c("year", "region", "category")])
)
assert_conservation(f3_raw, f3_series, nrow(f3), "marine-heat-waves_fig-3.csv")

write_csv_stable(f3, file.path(out_dir, "marine_heat_waves_area_by_region.csv"))

# ---- Figure 4: Marine Heat Wave Intensity and Duration at Five Marine Protected Areas, 1982-2023 ----

f4_path <- file.path(raw_dir, "marine-heat-waves_fig-4.csv")
f4_meta <- read_epa_preamble(f4_path)
f4_raw  <- read_epa_csv(f4_path)

# One source row per marine heat wave event. Two measures per event (duration
# and mean intensity) with different units, so they go long with a `measure`
# and `unit` column; severity is a category of the event, kept as EPA writes it.
F4_MEASURES <- c(duration = "days", intensity_mean = "degrees F")
F4_SEVERITY <- c("I Moderate", "II Strong", "III Severe", "IV Extreme")

f4_id_cols <- c("event_no", "date_start", "date_end", "severity", "marine_protected_area")
assert_headers(
  f4_raw,
  id_cols          = f4_id_cols,
  expected_headers = names(F4_MEASURES),
  what             = "marine-heat-waves_fig-4.csv"
)

# EPA writes dates as M/D/YYYY; ISO 8601 sorts and parses unambiguously.
iso_date <- function(x) {
  d <- as.Date(x, format = "%m/%d/%Y")
  if (anyNA(d)) stop("Unparseable date(s) in fig-4: ", paste(unique(x[is.na(d)]), collapse = ", "), call. = FALSE)
  format(d, "%Y-%m-%d")
}

f4 <- f4_raw |>
  mutate(date_start = iso_date(date_start), date_end = iso_date(date_end)) |>
  tidyr::pivot_longer(all_of(names(F4_MEASURES)), names_to = "measure", values_to = "value") |>
  mutate(unit = unname(F4_MEASURES[measure])) |>
  select(marine_protected_area, event_no, date_start, date_end, severity, measure, unit, value)

stopifnot(
  all(f4$severity %in% F4_SEVERITY),
  !anyDuplicated(f4[c("marine_protected_area", "event_no", "measure")])
)
assert_conservation(f4_raw, names(F4_MEASURES), nrow(f4), "marine-heat-waves_fig-4.csv")

write_csv_stable(f4, file.path(out_dir, "marine_heat_waves_events_by_protected_area.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order. tests/test-data.R checks these names
# against the written file, so the dictionary cannot drift from the data.
f3_columns <- list(
  col("year",     "integer",   "Calendar year."),
  col("region",   "character", "U.S. coastal region: West Coast, Gulf of Mexico, Southeast, Northeast, Alaska, or Hawaii."),
  col("category", "character", "Marine heat wave category: Moderate, Strong, Severe, or Extreme."),
  col("value",    "number",    "Percent of the region's coastal ocean area affected by a marine heat wave of this category during the year (%).")
)

f4_columns <- list(
  col("marine_protected_area", "character", "Name of the marine protected area, as EPA writes it."),
  col("event_no",              "integer",   "EPA's event number, sequential within each marine protected area."),
  col("date_start",            "date",      "First day of the marine heat wave event (ISO 8601)."),
  col("date_end",              "date",      "Last day of the marine heat wave event (ISO 8601)."),
  col("severity",              "character", "Event category as EPA writes it: I Moderate, II Strong, III Severe, or IV Extreme."),
  col("measure",               "character", "Which event measure the row carries: duration or intensity_mean."),
  col("unit",                  "character", "Unit of value: days for duration, degrees F for intensity_mean."),
  col("value",                 "number",    "Event duration in days, or mean intensity of the event in degrees F.")
)

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "marine_heat_waves_area_by_region.csv",
      figure          = "Figure 3",
      figure_title    = f3_meta$title,
      source_file     = "marine-heat-waves_fig-3.csv",
      source_sha256   = file_sha256(f3_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f3_meta$data_source,
      web_update      = f3_meta$web_update,
      unit            = f3_meta$units,
      rows            = nrow(f3),
      columns         = f3_columns
    ),
    list(
      file            = "marine_heat_waves_events_by_protected_area.csv",
      figure          = "Figure 4",
      figure_title    = f4_meta$title,
      source_file     = "marine-heat-waves_fig-4.csv",
      source_sha256   = file_sha256(f4_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f4_meta$data_source,
      web_update      = f4_meta$web_update,
      unit            = f4_meta$units,
      rows            = nrow(f4),
      columns         = f4_columns
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
