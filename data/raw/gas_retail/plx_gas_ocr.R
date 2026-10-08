# =====================================================================
# GAS_RETAIL: giá bán lẻ RON 95 vùng 1 của Petrolimex, 2011-08 -> nay
# Nguồn: thông cáo báo chí https://www.petrolimex.com.vn/ndi/thong-cao-bao-chi.html
# Bảng giá trong bài là ảnh -> OCR -> kiểm tra chéo -> chuỗi tháng.
# Chạy từng bước (BƯỚC 1 -> 2 -> 3 -> 4). Lần đầu đặt TEST_N = 25.
# =====================================================================
# install.packages(c("rvest","xml2","httr","callr","magick","tesseract","dplyr","stringr",
#                    "readr","zoo","lubridate","purrr"))
suppressPackageStartupMessages({
  library(rvest); library(xml2); library(magick); library(tesseract)
  library(dplyr); library(stringr); library(readr); library(zoo)
  library(lubridate); library(purrr)
})

BASE      <- "https://www.petrolimex.com.vn"
LAST_PAGE <- 60            # trang 60 ~ 2008; đủ phủ tới 2011
# Mục "Thông cáo báo chí" thiếu nhiều kỳ 2011 -> đầu 2012 (đã đối chiếu); chuỗi đáng tin bắt đầu 2012.
# Giá nền đầu 2012 và kỳ 20/04/2012 bị thiếu được bổ sung bằng manual_prices.csv.
START     <- as.Date("2012-01-01")
TEST_N    <- 25            # chạy thử 25 bài; đặt Inf khi chạy thật
OUT       <- "plx_out"; dir.create(file.path(OUT, "html"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUT, "img"), showWarnings = FALSE)
UA <- httr::user_agent("Mozilla/5.0 (research; contact: nhom-nghien-cuu)")

get_html <- function(url, cache) {
  f <- file.path(OUT, "html", paste0(cache, ".html"))
  if (!file.exists(f)) {
    r <- httr::GET(url, UA, httr::timeout(30))
    httr::stop_for_status(r)
    writeLines(httr::content(r, "text", encoding = "UTF-8"), f, useBytes = TRUE)
    Sys.sleep(1)                      # lịch sự với máy chủ
  }
  read_html(f, encoding = "UTF-8")
}

# ---------------------------------------------------------------- BƯỚC 1
# Duyệt trang danh sách, lấy link + tiêu đề, giữ bài điều chỉnh giá
crawl_list <- function() {
  map_dfr(1:LAST_PAGE, function(p) {
    url <- if (p == 1) paste0(BASE, "/ndi/thong-cao-bao-chi.html")
           else paste0(BASE, "/ndi/thong-cao-bao-chi/", p, ".html")
    message("list ", p)
    pg <- tryCatch(get_html(url, paste0("list_", p)), error = function(e) NULL)
    if (is.null(pg)) return(NULL)
    a <- html_elements(pg, "a")
    tibble(href = html_attr(a, "href"), title = str_squish(html_text(a))) |>
      filter(!is.na(href), str_detect(href, "thong-cao-bao-chi/[^/]+\\.html$"),
             !str_detect(href, "thong-cao-bao-chi/\\d+\\.html$"), nchar(title) > 15) |>
      mutate(url = xml2::url_absolute(href, BASE), page = p)
  }) |> distinct(url, .keep_all = TRUE)
}

# ngày hiệu lực lấy từ tiêu đề: "... ngày 09.9.2014", "... ngày 20-11-2017"
# Hai kiểu tiêu đề: "ngày 09.9.2014" (dd.m.yyyy) và "ngày 07 tháng 3 năm 2012" (bài 2011-07/2012)
parse_eff_date <- function(title) {
  t <- str_to_lower(title)
  m1 <- str_match(t, "ng[àa]y\\s+(\\d{1,2})[.\\-/](\\d{1,2})[.\\-/](\\d{4})")
  m2 <- str_match(t, "ng[àa]y\\s+(\\d{1,2})\\s+th[áa]ng\\s+(\\d{1,2})\\s+n[ăa]m\\s+(\\d{4})")
  d <- if_else(!is.na(m1[, 1]), m1[, 4], m2[, 4]); mo <- if_else(!is.na(m1[, 1]), m1[, 3], m2[, 3])
  dd <- if_else(!is.na(m1[, 1]), m1[, 2], m2[, 2])
  suppressWarnings(as.Date(sprintf("%s-%s-%s", d, mo, dd)))
}

if (!file.exists(file.path(OUT, "list.csv"))) {
  lst <- crawl_list() |>
    mutate(eff_date = parse_eff_date(title),
           dir = case_when(str_detect(str_to_lower(title), "tăng") ~ "up",
                           str_detect(str_to_lower(title), "giảm") ~ "down",
                           TRUE ~ "adj")) |>
    filter(str_detect(str_to_lower(title), "giá xăng|giá dầu|điều chỉnh giá|giá bán"),
           !str_detect(str_to_lower(title), "ưu đãi|tại quảng ngãi|e5 ron 92 tại"),
           !is.na(eff_date), eff_date >= START) |>
    arrange(eff_date)
  write_csv(lst, file.path(OUT, "list.csv"))
}
lst <- read_csv(file.path(OUT, "list.csv"), show_col_types = FALSE)
message("Số bài điều chỉnh giá: ", nrow(lst))   # kỳ vọng khoảng 350-450
# KIỂM TRA: có hai bài cùng ngày hiệu lực? có khoảng trống > 30 ngày? In ra để xem
print(lst |> mutate(gap = as.integer(eff_date - lag(eff_date))) |> filter(gap == 0 | gap > 30) |>
        select(eff_date, gap, title))

# ---------------------------------------------------------------- BƯỚC 2
# Tải ảnh trong bài + OCR, tìm dòng RON 95 vùng 1
num_re <- "\\d{1,2}[.,\\s]?\\d{3}"            # 21.540 | 21,540 | 21 540
to_num <- function(s) as.numeric(str_replace_all(s, "[^0-9]", ""))

MIN_W <- 300; MIN_H <- 80   # bỏ ảnh nhỏ (pixel theo dõi, icon, spacer) -> đây là thứ làm crash

img_ok <- function(path) {
  info <- tryCatch(image_info(image_read(path)), error = function(e) NULL)
  !is.null(info) && nrow(info) >= 1 && info$width[1] >= MIN_W && info$height[1] >= MIN_H
}

# OCR chạy trong tiến trình R riêng (callr): nếu Tesseract/Leptonica segfault thì
# chỉ tiến trình con chết, phiên RStudio của bạn vẫn sống, ảnh lỗi bị bỏ qua.
# Đường dẫn ảnh được ghi vào plx_out/ocr_log.txt TRƯỚC khi OCR -> biết ảnh nào gây lỗi.
# 3 cách tiền xử lý/đọc khác nhau; thử lần lượt cho tới khi ra dòng RON 95 hợp lý.
#  1 = xám + tăng tương phản, psm 6 (khối chữ);  2 = nhị phân, psm 4 (cột);  3 = đảo màu + nhị phân, psm 11 (rời rạc)
dir.create(file.path(OUT, "ocr_txt"), showWarnings = FALSE)
ocr_img <- function(path, variant = 1) {
  cat(path, " variant", variant, "\n", file = file.path(OUT, "ocr_log.txt"), append = TRUE)
  txt <- tryCatch(
    callr::r(function(path, variant) {
      library(magick); library(tesseract)
      im <- image_read(path)[1]
      w  <- image_info(im)$width
      if (w > 2400) im <- image_resize(im, "2400x") else if (w < 1400) im <- image_resize(im, "200%")
      im <- im |> image_background("white") |> image_flatten() |>   # bỏ kênh alpha
        image_convert(colorspace = "gray")
      if (variant == 1) im <- im |> image_contrast(sharpen = 1) |> image_normalize()
      if (variant == 2) im <- im |> image_normalize() |>
        image_threshold(type = "white", threshold = "55%") |> image_threshold(type = "black", threshold = "55%")
      if (variant == 3) im <- im |> image_negate() |> image_normalize() |>
        image_threshold(type = "white", threshold = "55%") |> image_threshold(type = "black", threshold = "55%")
      psm <- c(6, 4, 11)[variant]
      ocr(im, engine = tesseract("eng", options = list(tessedit_pageseg_mode = psm)))
    }, args = list(path = path, variant = variant), timeout = 90),
    error = function(e) {
      cat("  LỖI/CRASH: ", conditionMessage(e), "\n", file = file.path(OUT, "ocr_log.txt"), append = TRUE)
      ""
    })
  # lưu chữ OCR thô để soi khi đọc sai
  writeLines(txt, file.path(OUT, "ocr_txt", sprintf("%s_v%d.txt", tools::file_path_sans_ext(basename(path)), variant)))
  gc(); txt
}

# Lấy dòng RON 95-III (loại 95-V, E5, RON 92). Hai chế độ:
#  strict = TRUE  (chữ trong bài): bắt buộc "RON 95" + giá dạng 23.400 ngay sau
#  strict = FALSE (chữ OCR từ ảnh), theo giai đoạn (dt = ngày hiệu lực):
#    < 03/2015 : logic cũ (dòng có "95" + chữ xăng/ron)
#    >= 03/2015: bảng Vùng 1 | Vùng 2. Bỏ dòng sinh học E5, RON 92, 95-V (kể cả OCR "RONY5/RON9S5/RONgQl", dính chữ "XangRON95l_")
#                ưu tiên dòng "-III"; 01/2026-05/2026 bỏ dòng E10 (khi đó còn song song xăng không chứa ethanol)
#    Bảng ghi "Không thay đổi"/"Giữ nguyên" cho xăng -> nc = "nochg" (giá giữ như kỳ trước)
#    Bảng chỉ có diesel/dầu hỏa/mazut, không có dòng xăng (trước 2019) -> nc = "impl" (xăng không đổi, suy ra)
E10_FROM <- as.Date("2026-01-01"); E10_ONLY_FROM <- as.Date("2026-06-01")
extract_ron95 <- function(txt, strict = FALSE, dt = as.Date(NA)) {
  ln <- str_split(txt, "\n")[[1]] |> str_squish()
  ln <- ln[!str_detect(ln, regex("ngh[ịi]\\s*đ[ịi]nh|n[đd]\\s*-?\\s*cp|/20\\d\\d|kho[ảa]n\\s+\\d|đi[ềe]u\\s+\\d", ignore_case = TRUE))]
  none <- function(nc = NA_character_) tibble(line = NA_character_, v1 = NA_real_, v2 = NA_real_, ok = FALSE, nc = nc)
  if (strict) {
    m <- str_match(ln, regex("ron\\s*95(?!\\s*-?\\s*v\\b)[^0-9]{0,40}(\\d{2}[.,]\\d{3})", ignore_case = TRUE))
    hit <- which(!is.na(m[, 2]))
    if (length(hit) == 0) return(none())
    v <- to_num(m[hit[1], 2])
    return(tibble(line = ln[hit[1]], v1 = if (v >= 8000 & v <= 40000) v else NA_real_, v2 = NA_real_, ok = TRUE, nc = NA_character_))
  }
  nums_of <- function(l) { x <- str_extract_all(l, num_re)[[1]] |> to_num(); x[!is.na(x) & x >= 8000 & x <= 40000] }
  old_mode <- !is.na(dt) && dt < as.Date("2015-03-01")
  if (old_mode) {
    cand <- ln[str_detect(ln, regex("(ron|r0n|mogas|xăng|xang|x.ng).{0,15}\\b9[56]\\b", ignore_case = TRUE)) &
               !str_detect(ln, regex("9[56]\\s*-?\\s*V\\b|e5\\s*ron", ignore_case = TRUE))]
  } else {
    e10_era <- !is.na(dt) && dt >= E10_FROM && dt < E10_ONLY_FROM
    is_e10  <- str_detect(ln, regex("e1[o0]", ignore_case = TRUE))
    excl <- str_detect(ln, regex("\\be5|e5\\s*ron", ignore_case = TRUE)) |
            (str_detect(ln, regex("sinh\\s*h", ignore_case = TRUE)) & !is_e10) | (is_e10 & e10_era) |
            str_detect(ln, regex("ron\\s*(92|[qy]2|[a-z]92)", ignore_case = TRUE)) |
            str_detect(ln, "-\\s*V(?![A-Za-z0-9])|95\\s*-?\\s*V\\b|M\\S{0,3}c\\s*5\\b") |
            str_detect(ln, "[Il1|]V(?![A-Za-z0-9])") |                       # RON 95-IV (OCR: RONSSIV, RONQSIV...) là sản phẩm khác

            str_detect(ln, regex("di.zen|d.u\\s*h|mazut|maz.t", ignore_case = TRUE))
    is_ron <- str_detect(ln, "R[O0]N|mogas") | str_detect(ln, regex("(x.{0,3}ng).{0,15}\\b9[56]\\b", ignore_case = TRUE))
    cand <- ln[is_ron & !excl]
  }
  is3 <- str_detect(cand, "[-\\s]\\s*[Il1|]{3}(?![A-Za-z0-9])|III")
  cand <- c(cand[is3], cand[!is3])
  best <- NULL
  for (l in cand) {
    nums <- nums_of(l)
    if (length(nums) == 0) next
    d <- if (length(nums) >= 2) nums[2] - nums[1] else NA_real_
    ok <- !is.na(d) && d >= 250 && d <= 800          # Vùng 2 hơn Vùng 1 khoảng 300-700
    r <- tibble(line = l, v1 = nums[1], v2 = nums[2], ok = ok, nc = NA_character_)
    if (ok) return(r)
    if (is.null(best)) best <- r
  }
  if (!is.null(best)) return(best)
  if (old_mode) return(none())
  # không có dòng giá xăng: "Không thay đổi"/"Giữ nguyên"?
  nc <- ln[str_detect(ln, regex("r[o0]n\\s*\\S{0,2}9.*(kh.{1,3}ng\\s*thay|gi.{1,3}\\s*ngu.{0,2}n)", ignore_case = TRUE))]   # chỉ dòng "RON 95 ... không thay đổi" (bảng Quỹ BOG cũng có chữ "giữ nguyên" -> KHÔNG dùng)
  if (length(nc) > 0) return(tibble(line = nc[1], v1 = NA_real_, v2 = NA_real_, ok = TRUE, nc = "nochg"))
  dsl <- ln[str_detect(ln, regex("di.zen|d.u\\s*h|mazut|maz.t", ignore_case = TRUE))]
  if (!is.na(dt) && dt < as.Date("2019-01-01") && any(lengths(lapply(dsl, nums_of)) >= 2))
    return(none("impl"))
  none()
}

# id theo ngày + tên bài (không phụ thuộc số thứ tự) -> cache vẫn đúng khi danh sách thay đổi
id_of <- function(i) sprintf("%s_%s", format(lst$eff_date[i]),
                             substr(str_remove(basename(lst$url[i]), "\\.html$"), 1, 45))

# mã hóa %XX cho ký tự không phải ASCII trong đường dẫn ảnh
enc_nonascii <- function(x) vapply(x, function(s) {
  b <- as.integer(charToRaw(enc2utf8(s)))
  paste(ifelse(b < 128, rawToChar(as.raw(b), multiple = TRUE), sprintf("%%%02X", b)), collapse = "")
}, "", USE.NAMES = FALSE)

# tải ảnh: file 0 byte (lần tải hỏng trước đó) coi như chưa có; thử URL gốc + URL mã hóa, tối đa 3 lượt
dl_img <- function(u, f) {
  if (file.exists(f) && file.size(f) > 500) return(TRUE)
  for (att in 1:3) {
    for (uu in unique(c(u, utils::URLencode(u), utils::URLencode(u, reserved = FALSE)))) {
      resp <- tryCatch(httr::GET(uu, UA, httr::write_disk(f, overwrite = TRUE), httr::timeout(90)), error = function(e) NULL)
      if (!is.null(resp) && httr::status_code(resp) == 200 && file.size(f) > 500) { Sys.sleep(0.5); return(TRUE) }
      cat("TẢI LỖI: ", uu, " status ", if (is.null(resp)) "error" else httr::status_code(resp), "\n",
          file = file.path(OUT, "ocr_log.txt"), append = TRUE)
    }
    Sys.sleep(2)
  }
  unlink(f); FALSE
}

process_article <- function(i) {
  r <- lst[i, ]
  id <- id_of(i)
  pg <- tryCatch(get_html(r$url, id), error = function(e) NULL)
  if (is.null(pg)) return(tibble(id, url = r$url, src = "fetch_fail", line = NA, v1 = NA, v2 = NA))
  # (a) thử đọc chữ trong bài trước (bài cũ có thể là chữ)
  body <- html_text2(pg)
  t <- extract_ron95(body, strict = TRUE)
  if (!is.na(t$v1)) return(bind_cols(tibble(id, url = r$url, src = "text"), t))
  # (b) không có chữ -> tải ảnh, OCR từng ảnh
  # src có chữ có dấu/khoảng trắng (vd "Giá%20chuẩn%2011032015.jpg", "bảng%20giá%202.jpg") làm url_absolute trả NA
  # -> ảnh bảng giá không bao giờ được tải. Giữ nguyên chỉ số cũ (cache), ảnh bị NA thêm vào CUỐI danh sách sau khi mã hóa %XX.
  src0 <- html_elements(pg, "img") |> html_attr("src") |> na.omit() |> as.character()
  abs1 <- xml2::url_absolute(src0, BASE)
  imgs <- unique(abs1)
  imgs <- imgs[str_detect(imgs, "(?i)\\.(jpe?g|png)")]            # NA giữ nguyên vị trí cũ
  extra <- if (any(is.na(abs1))) unique(xml2::url_absolute(enc_nonascii(src0[is.na(abs1)]), BASE)) else character(0)
  extra <- extra[!is.na(extra) & str_detect(extra, "(?i)\\.(jpe?g|png)")]
  imgs <- c(imgs, extra)
  need_pair <- lst$eff_date[i] >= as.Date("2015-03-01")   # từ 2015: bảng Vùng 1 | Vùng 2 -> bắt buộc chênh 250-800
  fb <- NULL; fb_impl <- NULL
  for (k in seq_along(imgs)) {
    f <- file.path(OUT, "img", sprintf("%s_%d%s", id, k, ".jpg"))
    if (is.na(imgs[k])) next
    ok <- dl_img(imgs[k], f)
    if (!ok || !img_ok(f)) next
    for (v in 1:3) {                      # thử lần lượt 3 cách đọc
      txt <- tryCatch(ocr_img(f, v), error = function(e) "")
      t <- extract_ron95(txt, dt = r$eff_date)
      if (identical(t$nc, "nochg"))                       # bảng ghi xăng "không thay đổi"/"giữ nguyên"
        return(tibble(id, url = r$url, src = sprintf("ocr_nochg:%s", basename(f)), line = t$line, v1 = NA_real_, v2 = NA_real_))
      if (identical(t$nc, "impl")) {
        if (is.null(fb_impl)) fb_impl <- tibble(id, url = r$url, src = sprintf("ocr_impl_nochg:%s", basename(f)),
                                                 line = NA_character_, v1 = NA_real_, v2 = NA_real_)
        next
      }
      if (is.na(t$v1)) next
      res <- bind_cols(tibble(id, url = r$url, src = sprintf("ocr%d:%s", v, basename(f))), select(t, line, v1, v2))
      if (t$ok || !need_pair) return(res)
      if (is.null(fb)) fb <- res
    }
  }
  if (!is.null(fb)) return(fb)
  if (!is.null(fb_impl)) return(fb_impl)
  tibble(id, url = r$url, src = "none", line = NA_character_, v1 = NA_real_, v2 = NA_real_)
}

n <- min(nrow(lst), TEST_N)
# lưu kết quả từng bài -> nếu R crash, chạy lại sẽ bỏ qua bài đã xong
dir.create(file.path(OUT, "done"), showWarnings = FALSE)
raw <- map_dfr(seq_len(n), function(i) {
  f <- file.path(OUT, "done", paste0(id_of(i), ".rds"))
  if (file.exists(f)) {
    old <- readRDS(f)
    # làm lại: bài chưa đọc được, và bài "text" sau 08/2012 (bản cũ đọc nhầm số trong câu viện dẫn Nghị định)
    redo <- old$src[1] %in% c("none", "fetch_fail") || grepl("nochg", old$src[1]) || (!is.na(old$line[1]) && grepl("[Il1|]V(?![A-Za-z0-9])", old$line[1], perl = TRUE)) || (old$src[1] == "text" && lst$eff_date[i] > as.Date("2012-08-01"))
    if (!redo) return(old)
  }
  message("bài ", i, "/", n)
  res <- process_article(i); saveRDS(res, f); res
})
raw <- bind_cols(lst[seq_len(n), c("eff_date", "title", "dir")], raw |> select(-url)) |>
  mutate(url = lst$url[seq_len(n)])
write_csv(raw, file.path(OUT, "raw_ocr.csv"))
message("Đọc được: ", sum(!is.na(raw$v1)), "/", n)

# ---------------------------------------------------------------- BƯỚC 3
# Kiểm tra chéo + chỗ sửa tay
# (a) override: file manual_fix.csv với 2 cột url,v1 (nhập tay từ ảnh khi OCR sai/thiếu)
find_csv <- function(f) { p <- c(file.path(OUT, f), f); p <- p[file.exists(p)]; if (length(p)) { message("Đọc ", p[1]); p[1] } else NA_character_ }
f_fix <- find_csv("manual_fix.csv"); f_mp <- find_csv("manual_prices.csv")
if (!is.na(f_fix)) {
  fx <- read_csv(f_fix, show_col_types = FALSE) |> select(url, v1) |> filter(!is.na(v1))
  raw <- raw |> left_join(fx |> rename(v1_fix = v1), by = "url") |>
    mutate(src = if_else(!is.na(v1_fix), "manual", src), v1 = coalesce(v1_fix, v1)) |> select(-v1_fix)
}
# Dạng bảng giá giai đoạn đầu (2012-2014, có thể cả sau): 3 cột = GIÁ MỚI | GIÁ CŨ | CHÊNH LỆCH
#   -> v1 = giá mới, v2 = GIÁ CŨ (không phải vùng 2), số thứ 3 = chênh lệch hoặc "Không thay đổi".
# Dạng sau (nếu có cột Vùng 1 | Vùng 2): v2 là vùng 2. Phân biệt bằng số thứ 3 khớp |v1 - v2|.
parse_line <- function(l) {
  if (is.na(l)) return(tibble(d3 = NA_real_, nochg = FALSE))
  toks <- str_extract_all(l, "-?\\d+(?:[.,]\\d{3})*")[[1]]
  vals <- ifelse(startsWith(toks, "-"), -1, 1) * to_num(toks)
  isp  <- which(vals >= 8000 & vals <= 40000)
  d3   <- if (length(isp) >= 2 && length(vals) > isp[2]) vals[isp[2] + 1] else NA_real_
  if (!is.na(d3) && abs(d3) < 50) d3 <- NA_real_   # "Kh6ng thay déi" bị OCR thành số 6 -> coi là "không đổi"
  tibble(d3 = d3, nochg = is.na(d3) & str_detect(l, regex("kh.{1,3}ng|thay", ignore_case = TRUE)))
}
# (b) giá bổ sung bằng tay cho kỳ thiếu trên website / giá nền: manual_prices.csv (eff_date,v1,note)
if (!is.na(f_mp)) {
  mp <- read_csv(f_mp, show_col_types = FALSE)
  raw <- bind_rows(raw, mp |> transmute(eff_date, title = note, dir = "adj", id = paste0("manual_", eff_date),
                                         src = "manual_price", line = NA_character_, v1, v2 = NA_real_,
                                         url = paste0("manual:", eff_date)))
}
# Bài dạng chữ (2012): số thứ hai là RON 92, KHÔNG phải giá cũ/vùng 2 -> bỏ
raw <- raw |> mutate(v2 = if_else(src == "text", NA_real_, v2))
raw <- bind_cols(raw, map_dfr(raw$line, parse_line)) |> arrange(eff_date) |>
  mutate(nochg   = nochg & src != "text",
         fmt_old = !is.na(v2) & ((!is.na(d3) & abs(abs(d3) - abs(v1 - v2)) <= 10) | (nochg & v1 == v2)))

# Điền bài OCR không đọc được từ cột "giá cũ" của bài kế tiếp (nếu bài kế là dạng cũ)
raw$src_fill <- NA_character_
for (i in rev(seq_len(nrow(raw) - 1))) {
  if (is.na(raw$v1[i]) && isTRUE(raw$fmt_old[i + 1]) && !is.na(raw$v2[i + 1])) {
    raw$v1[i] <- raw$v2[i + 1]; raw$src_fill[i] <- "inferred_from_next_old_price"
  }
}

# bài chỉ nói về diesel/dầu hỏa/mazut (tiêu đề không nhắc xăng) mà không đọc được bảng -> xăng không đổi
t2 <- str_remove_all(str_to_lower(raw$title), "tập đoàn xăng dầu việt nam|xăng dầu|petrolimex")
only_oil <- is.na(raw$v1) & raw$src == "none" & !str_detect(t2, "xăng") &
            str_detect(t2, "đi[êe]zen|diesel|dầu hỏa|dầu hoả|mazut|dầu\\s*(0|kerosene)")
raw$src[only_oil] <- "title_nochg"
# xăng "không thay đổi"/"giữ nguyên" (ocr_nochg) hoặc bảng không có dòng xăng (ocr_impl_nochg): giá = giá kỳ trước
for (i in seq_len(nrow(raw))[-1]) {
  if (is.na(raw$v1[i]) && str_detect(raw$src[i], "nochg") && !is.na(raw$v1[i - 1])) {
    raw$v1[i] <- raw$v1[i - 1]; raw$src_fill[i] <- "carry_nochg"
  }
}

chk <- raw |>
  mutate(chg = v1 - lag(v1), pct = chg / lag(v1) * 100,
         # cột 3 (chênh lệch) hay bị OCR làm mất -> nhận ra dạng "mới | cũ" còn nhờ giá cũ = giá mới kỳ trước
         fmt_old    = fmt_old | (!is.na(v2) & !is.na(lag(v1)) & v2 == lag(v1)),
         flag_na    = is.na(v1),
         flag_big   = abs(pct) > 10,                         # đổi > 10% một kỳ là bất thường
         flag_dir   = (dir == "up" & chg < 0) | (dir == "down" & chg > 0),  # ngược hướng tiêu đề
         # tiêu đề nói đổi mà RON 95 không đổi: bình thường nếu bảng ghi giá cũ = giá mới (kỳ chỉ đổi E5/diesel)
         flag_zero  = !is.na(chg) & chg == 0 & dir %in% c("up", "down") & !coalesce(nochg, FALSE) & !fmt_old & is.na(src_fill),
         # KIỂM TRA MẠNH: giá cũ của kỳ này phải bằng giá mới của kỳ trước; lệch = thiếu một kỳ điều chỉnh hoặc OCR sai
         flag_chain = fmt_old & !is.na(lag(v1)) & !is.na(v2) & v2 != lag(v1),
         flag_impl  = grepl("impl_nochg", src),   # suy ra "xăng không đổi" vì bảng chỉ có diesel/mazut: nên liếc qua
         flag_v2    = !fmt_old & !is.na(v2) & !is.na(v1) & (v2 - v1 < 0 | v2 - v1 > 1500))
# gợi ý sửa lỗi 1 chữ số cho giá "nhọn" (lệch > 2000 so với cả kỳ trước và kỳ sau, hai kỳ kề nhau chênh < 1500): CHỈ gợi ý, không tự sửa
sug <- function(v, p, nx) {
  s5 <- sprintf("%05d", as.integer(v)); cand <- numeric(0)
  for (k in 1:5) for (dg in 0:9) { t <- s5; substr(t, k, k) <- as.character(dg); x <- as.numeric(t)
    if (x != v && x >= min(p, nx) - 600 && x <= max(p, nx) + 600) cand <- c(cand, x) }
  if (length(cand) == 0) NA_real_ else cand[which.min(abs(cand - (p + nx) / 2))]
}
chk$suggest <- NA_real_
for (i in 2:(nrow(chk) - 1)) {
  v <- chk$v1[i]; p <- chk$v1[i - 1]; nx <- chk$v1[i + 1]
  if (!any(is.na(c(v, p, nx))) && abs(v - p) > 2000 && abs(v - nx) > 2000 && abs(p - nx) < 1500) chk$suggest[i] <- sug(v, p, nx)
}
# gợi ý 2: cặp Vùng 1 | Vùng 2 lệch bất thường (Vùng 2 - Vùng 1 ngoài 250-800, bảng dạng Vùng) -> chữ số nào của v1 sửa 1 ký tự thì khớp
for (i in seq_len(nrow(chk))) {
  v <- chk$v1[i]; w <- chk$v2[i]
  if (is.na(chk$suggest[i]) && !is.na(v) && !is.na(w) && !isTRUE(chk$fmt_old[i]) && !(w - v >= 250 & w - v <= 800) && chk$eff_date[i] >= as.Date("2015-03-01")) {
    s5 <- sprintf("%05d", as.integer(v)); cand <- numeric(0)
    for (k in 1:5) for (dg in 0:9) { t <- s5; substr(t, k, k) <- as.character(dg); x <- as.numeric(t)
      if (x != v && w - x >= 250 && w - x <= 800) cand <- c(cand, x) }
    if (length(cand) >= 1) chk$suggest[i] <- cand[which.min(abs(cand - coalesce(chk$v1[i - 1], v)))]
  }
}
chk$flag_any <- with(chk, flag_na | flag_big | flag_dir | flag_zero | flag_chain | flag_v2 | flag_impl)
write_csv(chk, file.path(OUT, "check.csv"))
cat("\nBài cần xem lại bằng mắt: ", sum(chk$flag_any, na.rm = TRUE), "/", nrow(chk),
    " | tự điền từ giá cũ kỳ sau: ", sum(!is.na(chk$src_fill)), "\n")
print(chk |> filter(flag_any) |> select(eff_date, dir, v1, v2, chg, suggest, src, url), n = 80)
# mẫu để nhập tay các bài còn NA: điền cột v1 (giá RON 95-III vùng 1, vd 25240), đổi tên thành manual_fix.csv, chạy lại
na_rows <- chk |> filter(flag_na)
if (nrow(na_rows) > 0) {
  write_csv(na_rows |> transmute(url, v1 = NA_real_, eff_date, anh = sprintf("img/%s_4.jpg (hoặc số khác)", id)),
            file.path(OUT, "manual_fix_TEMPLATE.csv"))
  message("Đã ghi plx_out/manual_fix_TEMPLATE.csv cho ", nrow(na_rows), " bài còn NA")
}
# flag_chain = TRUE là dấu hiệu quan trọng nhất: danh sách bài còn thiếu một kỳ điều chỉnh ngay trước ngày đó.
# -> mở ảnh trong plx_out/img, nhập giá đúng vào manual_fix.csv (url,v1), chạy lại từ BƯỚC 3

# ---------------------------------------------------------------- BƯỚC 4
# Chuỗi tháng: giá cuối tháng và giá bình quân theo ngày (cả hai, chọn 1 cho bài)
price_daily <- function(d) {
  d <- d |> filter(!is.na(v1)) |> arrange(eff_date)
  # giá nền: trước kỳ đầu tiên, giá = "giá cũ" của kỳ đầu (nếu là dạng cũ) -> giữ nguyên từ START
  if (isTRUE(d$fmt_old[1]) && !is.na(d$v2[1]))
    d <- bind_rows(tibble(eff_date = START, v1 = d$v2[1]), d)
  d <- d |> group_by(eff_date) |> slice_tail(n = 1) |> ungroup()
  days <- tibble(date = seq(min(d$eff_date), max(max(d$eff_date), as.Date("2026-07-31")), by = "day"))
  days |> left_join(d |> select(date = eff_date, v1), by = "date") |>
    mutate(price = na.locf(v1, na.rm = FALSE)) |> select(date, price)
}
out_csv <- file.path(OUT, "GAS_RETAIL_monthly.csv")
if (any(chk$flag_na)) {
  # còn bài chưa có giá -> KHÔNG ghi chuỗi (nếu ghi, giá kỳ trước bị giữ phẳng một cách sai lặng lẽ)
  unlink(out_csv)
  message("BƯỚC 4 BỎ QUA: còn ", sum(chk$flag_na), " bài chưa có giá RON 95 (flag_na). File cũ (nếu có) đã bị xóa.")
} else {
  if (any(chk$flag_any, na.rm = TRUE)) message("Lưu ý: còn ", sum(chk$flag_any, na.rm = TRUE), " bài bị cờ khác, xem check.csv trước khi dùng chuỗi.")
  daily <- price_daily(chk)
  monthly <- daily |> mutate(ym = floor_date(date, "month")) |>
    group_by(ym) |> summarise(gas_end = last(price), gas_avg = mean(price), .groups = "drop") |>
    filter(ym >= as.Date("2011-09-01"), ym <= as.Date("2026-07-01")) |>
    mutate(lgas_end = log(gas_end), dlgas_end = c(NA, diff(log(gas_end))) * 100)
  write_csv(monthly, out_csv)
  print(tail(monthly, 8))
}
# Khi TEST_N = Inf, kỳ vọng 2011-09..2026-07 = 179 dòng, không NA ở gas_end.
# 09-12/2011: lấy từ manual_prices.csv (2011-08-26 = 21.300, không đổi tới 07/03/2012).
