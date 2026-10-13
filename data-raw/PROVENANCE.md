# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-marine-heat-waves/index.html>  \
  sha256 `12a387a1d01bbab871e18c39a103ba37d562e331a0011af497cf3a76405853fd`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/marine-heat-waves_documentation.pdf>

## Figure data

- **Figure 1** has no data download on EPA's page. The narrative carries the caption; there is nothing to build.

- **Figure 2** has no data download on EPA's page. The narrative carries the caption; there is nothing to build.

- `marine-heat-waves_fig-3.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/marine-heat-waves_fig-3.csv>  \
  sha256 `a0c54a81ad95ab5936a8eb85b151a364d4c1deae21b9f50f3ef555f6984a59ac`  \
  encoding UTF-8-BOM, 42 data rows, columns: `Year`, `West Coast Moderate`, `West Coast Strong`, `West Coast Severe`, `West Coast Extreme`, `Gulf of Mexico Moderate`, `Gulf of Mexico Strong`, `Gulf of Mexico Severe`, `Gulf of Mexico Extreme`, `Southeast Moderate`, `Southeast Strong`, `Southeast Severe`, `Southeast Extreme`, `Northeast Moderate`, `Northeast Strong`, `Northeast Severe`, `Northeast Extreme`, `Alaska Moderate`, `Alaska Strong`, `Alaska Severe`, `Alaska Extreme`, `Hawaii Moderate`, `Hawaii Strong`, `Hawaii Severe`, `Hawaii Extreme`  \
  title: Figure 3. Areas Affected by Marine Heat Waves by U.S. Coastal Region, 1982-2023  \
  data source: NOAA, 2024; web update: June 2024; units: percent area (%)

- `marine-heat-waves_fig-4.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/marine-heat-waves_fig-4.csv>  \
  sha256 `8ae074fa28a871d10eb6d25a6bcb5c8e9e92579948bd4f4cc1a430541e8523c2`  \
  encoding UTF-8-BOM, 568 data rows, columns: `event_no`, `duration`, `date_start`, `date_end`, `intensity_mean`, `severity`, `marine_protected_area`  \
  title: Figure 4. Marine Heat Wave Intensity and Duration at Five Marine Protected Areas, 1982-2023  \
  data source: NOAA, 2024; web update: June 2024; units: duration (days), intensity (degrees F), severity
