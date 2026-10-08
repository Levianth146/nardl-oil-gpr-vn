# Hàm dùng chung (đọc biến, ghi bảng/hình theo quy ước đặt tên chương)
read_var <- function(name) {
  readr::read_csv(here::here("data", "raw", paste0(name, ".csv")), show_col_types = FALSE)
}
save_table <- function(df, file) readr::write_csv(df, here::here("outputs", "tables", file))
