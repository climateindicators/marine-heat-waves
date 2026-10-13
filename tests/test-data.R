# Regression checks on the generated data for the Marine Heat Waves indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 2 dataset(s)", length(meta$datasets) == 2L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned against EPA's June 2024 web update. A data update should fail here.
row_is <- function(df, i, expected) identical(unname(unlist(df[i, names(expected)])), unname(expected))
num_range <- function(x) {
  v <- as.numeric(x)
  c(x[which.min(v)], x[which.max(v)])
}

a <- rd("marine_heat_waves_area_by_region.csv")
check("area_by_region: 1008 rows (42 years x 6 regions x 4 categories)", nrow(a) == 1008L)
check("area_by_region: years 1982 to 2023", identical(range(a$year), c("1982", "2023")))
check("area_by_region: first row is 1982 West Coast Moderate 47.84514244",
      row_is(a, 1, c(year = "1982", region = "West Coast", category = "Moderate", value = "47.84514244")))
check("area_by_region: last row is 2023 Hawaii Extreme 0",
      row_is(a, nrow(a), c(year = "2023", region = "Hawaii", category = "Extreme", value = "0")))
check("area_by_region: value range is 0 to 91.92422732", identical(num_range(a$value), c("0", "91.92422732")))
check("area_by_region: maximum is 2019 Gulf of Mexico Strong",
      row_is(a, which.max(as.numeric(a$value)), c(year = "2019", region = "Gulf of Mexico", category = "Strong")))
check("area_by_region: 213 zero values", sum(a$value == "0") == 213L)

b   <- rd("marine_heat_waves_events_by_protected_area.csv")
dur <- b[b$measure == "duration", ]
int <- b[b$measure == "intensity_mean", ]
check("events: 1136 rows (568 events x 2 measures)", nrow(b) == 1136L)
check("events: first row is Olympic Coast event 1 duration 7",
      row_is(b, 1, c(marine_protected_area = "Olympic Coast National Marine Sanctuary", event_no = "1",
                     date_start = "1982-12-20", date_end = "1982-12-26", severity = "I Moderate",
                     measure = "duration", unit = "days", value = "7")))
check("events: last row is Kachemak Bay event 97 intensity 2.5339",
      row_is(b, nrow(b), c(marine_protected_area = "Kachemak Bay National Estuarine Research Reserve", event_no = "97",
                           date_start = "2023-11-24", date_end = "2023-12-18", severity = "I Moderate",
                           measure = "intensity_mean", unit = "degrees F", value = "2.5339")))
check("events: duration range is 5 to 218 days", identical(num_range(dur$value), c("5", "218")))
check("events: intensity range is 1.0118 to 5.9637 degrees F", identical(num_range(int$value), c("1.0118", "5.9637")))
check("events: longest event is Kachemak Bay 2014-11-02 to 2015-06-07",
      row_is(dur, which.max(as.numeric(dur$value)),
             c(marine_protected_area = "Kachemak Bay National Estuarine Research Reserve",
               date_start = "2014-11-02", date_end = "2015-06-07", severity = "III Severe")))
check("events: per-area event counts 155/121/97/85/110",
      identical(as.integer(table(dur$marine_protected_area)[c(
        "Florida Keys National Marine Sanctuary",
        "Gerry E. Studds/Stellwagen Bank National Marine Sanctuary",
        "Kachemak Bay National Estuarine Research Reserve",
        "Olympic Coast National Marine Sanctuary",
        "Papahanaumokuakea Marine National Monument Particularly Sensitive Sea Area")]),
        c(155L, 121L, 97L, 85L, 110L)))
check("events: severity counts 421/132/14/1",
      identical(as.integer(table(dur$severity)[c("I Moderate", "II Strong", "III Severe", "IV Extreme")]),
                c(421L, 132L, 14L, 1L)))
check("events: start dates span 1982-02-09 to 2023-12-21", identical(range(b$date_start), c("1982-02-09", "2023-12-21")))
check("events: no event ends before it starts", all(as.Date(b$date_end) >= as.Date(b$date_start)))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
