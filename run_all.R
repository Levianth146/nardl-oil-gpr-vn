# Một lệnh chạy nối toàn bộ pipeline:  source("run_all.R")
# Seed và phiên bản gói được ghi vào outputs/run_info.txt
suppressPackageStartupMessages({ library(yaml); library(here) })
cfg <- read_yaml(here("config.yml")); set.seed(cfg$seed)

steps <- c("01_clean_merge.R", "02_derive_unitroot.R", "03_model_cpi.R",
           "04_model_vnindex.R", "05_multipliers_toda_yamamoto.R",
           "06_state_channels.R", "07_robustness.R")
for (s in steps) {
  f <- here("scripts", s)
  if (file.exists(f) && length(readLines(f, warn = FALSE)) > 8) { message(">> ", s); source(f, echo = FALSE) }
  else message("-- bỏ qua (chưa viết): ", s)
}
writeLines(c(format(Sys.time()), R.version.string,
             paste(names(sessionInfo()$otherPkgs), sapply(sessionInfo()$otherPkgs, `[[`, "Version"))),
           here("outputs", "run_info.txt"))
