# nardl-oil-gpr-vn

Tác động bất đối xứng của cú sốc giá dầu và rủi ro địa chính trị (GPR) đến CPI và VN-Index của Việt Nam, mô hình NARDL, dữ liệu tháng 01/2012–07/2026 (175 quan sát), ngôn ngữ R.

## Chạy lại
```r
# R >= 4.4
renv::restore()
source("run_all.R")
```
Kết quả sinh ra nằm trong `outputs/tables`, `outputs/figures`. Bản đóng băng dùng để viết luận: `outputs/frozen/`.

## Cấu trúc
```
config.yml        tham số chung (mẫu, lag, ngưỡng GPR, seed)
run_all.R         chạy nối mọi bước
data/raw/         18 file CSV (date,value), mỗi biến một file, KHÔNG sửa tay
data/processed/   panel_monthly.csv, panel_derived.csv
data/data_dictionary.md
R/                lõi NARDL, chẩn đoán, hàm dùng chung
scripts/          01..07, mỗi file một việc
outputs/          tables/ figures/ frozen/
docs/             ghi chú phương pháp, issues
```

## Phân công mô hình
| Việc | Nội dung | Script | Branch | Người làm |
|---|---|---|---|---|
| 1 | Thu thập và làm sạch 18 biến, gộp tháng | `01_clean_merge.R` | `viec1/data` | |
| 2 | Biến phái sinh, ADF/PP/KPSS/ZA | `02_derive_unitroot.R` | `viec2/derive-unitroot` | |
| 3 | Lõi NARDL + Mô hình 1 (CPI) | `R/nardl_core.R`, `03_model_cpi.R` | `viec3/nardl-core-cpi` | |
| 4 | Mô hình 2 (VN-Index), nhân tử động, tích hợp | `04_*`, `05_*`, `run_all.R` | `viec4/vnindex-multipliers` | |
| 5 | Trạng thái, kênh truyền dẫn, kiểm định bền | `06_*`, `07_*` | `viec5/state-channels-robust` | |

Chi tiết đầu vào/đầu ra từng việc: `docs/issues/`.

## Quy trình làm việc (Git)
- `main`: chỉ nhận PR từ `dev`, đánh tag mốc. `dev`: nhánh tích hợp.
- Mỗi người tạo nhánh từ `dev` theo bảng trên, commit nhỏ, mở PR vào `dev`, nhờ 1 bạn review trước khi merge.
- Mốc: `v0.1-data` (panel chốt) → `v0.2-frozen` (kết quả đóng băng) → `v1.0` (nộp).
- Quy ước commit: `data: …`, `model: …`, `analysis: …`, `fix: …`.
- Quy ước tên file đầu ra theo mục luận: `t4_2_nardl_cpi.csv`, `f4_4_multipliers_cpi.png`.
- Luận văn viết trong Word/Google Docs, không đưa vào repo (`.docx` bị `.gitignore`).

## Lưu ý dữ liệu
- GAS_RETAIL: giá bán lẻ RON 95-III vùng 1 của Petrolimex, bình quân theo số ngày giữa các kỳ điều chỉnh. Xem `data/raw/gas_retail/`.
