# nardl_vn — Cú sốc giá dầu & rủi ro địa chính trị → CPI và VN-Index (NARDL, R)

## Chạy nhanh
```r
# 1) Cài gói (một lần): install.packages(c("urca","sandwich","lmtest","tseries","strucchange","ggplot2","writexl","openxlsx","readxl","zoo"))
# 2) Mở R tại THƯ MỤC GỐC dự án này
source("tools/make_synthetic_raw.R")     # CHỈ để thử: sinh 18 file dữ liệu GIẢ vào data/raw/ (xóa đi khi có dữ liệu thật)
source("tests/test_engine.R")            # 22 kiểm thử lõi phải PASS
source("scripts/99_run_all.R")           # chạy 01 -> 08; kết quả ở output/tables, output/figures
```
Dữ liệu thật: bỏ 18 file `data/raw/<TÊN>.csv` (cột `date,value`) theo bảng dưới, **không sửa code**. Mọi tham số ở `config/config.R`.

## Hợp đồng dữ liệu thô (data/raw/<FILE>.csv, cột date,value; date dạng YYYY-MM-DD)
| File | Tần suất | Gộp về tháng | Ghi chú |
|---|---|---|---|
| CPI_MOM, CPI_CORE_MOM | tháng | — | chỉ số "tháng trước = 100" (GSO); code tự nối chuỗi + khử mùa Tết |
| VNINDEX | ngày | cuối tháng (và bình quân cho VNINDEX_AVG) | |
| OIL (Brent), OIL_WTI | ngày | bình quân tháng | |
| GPR, GPR_THREAT, GPR_ACT | tháng | — | Caldara–Iacoviello |
| EXCH, VIX | ngày | cuối tháng | |
| INTEREST, FEDRATE, IIP, M2, GDEMAND, CPI_US | tháng | — | GDEMAND: chỉ số cầu toàn cầu (vd. Kilian) |
| GAS_RETAIL | sự kiện (ngày hiệu lực, giá) | bình quân THEO SỐ NGÀY | chuỗi bậc thang |
| FFLOW | tháng | — | dòng vốn ngoại ròng; tự chuẩn hóa thành FFLOW_S |

## Kiến trúc & người phụ trách (nhóm 5 người)
| Module | File | Người |
|---|---|---|
| Data: nạp, đồng bộ tần suất, nối CPI, khử Tết | `R/utils_data.R`, `R/build_panel.R`, `scripts/01` | P1 |
| Variables/Tests: log, tổng riêng phần, dummy, GPR trực giao, ADF/PP/KPSS/ZA, GTY | `R/utils_vars.R`, `R/utils_tests.R`, `scripts/02` | P2 |
| Engine: lag, ECM, bounds, Wald, dài hạn, nhân tử, bootstrap, chẩn đoán | `R/nardl_engine.R`, `scripts/03`, `04`, `tests/` | P3 |
| Channels/States: kênh truyền dẫn, trạng thái GPR | `R/channels.R`, `scripts/05`, `06` | P4 |
| Robustness/Report: bền vững, hình, bảng tổng hợp | `R/utils_plot.R`, `scripts/07`, `08`, `99` | P5 |

## API lõi (R/nardl_engine.R)
`make_spec(y, asym=list(OIL=c("OIL_P","OIL_N"),...), z, dummies)` → `run_nardl(df, spec, cfg, lags=NULL, do_boot)`
trả: `lags, fit, coef, bounds, longrun, symmetry, mult, mult_ci, diag`.
Quy ước nhân tử: `mp` = phản ứng với +1 ở x; `mn` = phản ứng với GIẢM 1 ở x; `asym = mp + mn` (=0 nếu đối xứng).

## Cổng kiểm soát (không qua cổng thì không đi tiếp)
G1 (sau 02): không biến nào I(2). G2 (sau 03): bounds kết luận rõ + BG(6) không bác bỏ; nếu "vùng không kết luận" thì dùng t-bounds/ARDL dừng và nói rõ.
G3 (sau 05): chỉ diễn giải Sobel với trung gian I(1); cột `flag` cảnh báo ρ≈0.

## Lưu ý phương pháp
- Tổng riêng phần của biến I(0) (vd. LGPR nếu ADF/KPSS bảo dừng) vẫn là chuỗi "giả I(1)": cần nêu rõ, và chạy thêm biến thể GPR trực giao / GPR dạng mức + trạng thái.
- Kết quả trên dữ liệu giả lập CHỈ dùng để kiểm tra code, không có ý nghĩa kinh tế.
- Bounds test dùng ngưỡng mô phỏng theo n và k thực tế (cache ở `output/rds`); báo cáo cuối nên tăng `bounds_reps=20000`, `boot_B=1000`.
