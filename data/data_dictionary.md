# Từ điển dữ liệu

Mẫu: 01/2012–07/2026 (175 tháng). Mỗi biến một file `data/raw/<TÊN>.csv` gồm hai cột `date,value`, `date` là ngày đầu tháng (YYYY-MM-01).
Cột "Gộp tháng", "Nguồn", "Ngày truy cập" do người làm Việc 1 điền; dòng trống = chưa làm.

| # | Biến | Mô tả | Đơn vị | Gộp tháng | Nguồn | Ngày truy cập | Trạng thái |
|---|---|---|---|---|---|---|---|
| 1 | CPI | Chỉ số giá tiêu dùng, nối 4 mối nối năm gốc (2009, 2014, 2019, 2024), khử mùa Tết | chỉ số | giữ nguyên | Cục Thống kê | | |
| 2 | CPI_CORE | CPI lõi | chỉ số | giữ nguyên | Cục Thống kê / NHNN | | |
| 3 | VNINDEX | VN-Index | điểm | cuối tháng | HOSE | | |
| 4 | BRENT | Giá dầu Brent | USD/thùng | bình quân tháng | EIA / FRED | | |
| 5 | WTI | Giá dầu WTI | USD/thùng | bình quân tháng | EIA / FRED | | |
| 6 | GPR | Chỉ số rủi ro địa chính trị | chỉ số | giữ nguyên | Caldara–Iacoviello | | |
| 7 | GPR_THREAT | GPR đe dọa | chỉ số | giữ nguyên | Caldara–Iacoviello | | |
| 8 | GPR_ACT | GPR hành động | chỉ số | giữ nguyên | Caldara–Iacoviello | | |
| 9 | EXCH | Tỷ giá VND/USD (chốt một loại cho cả mẫu, không dùng tỷ giá trung tâm) | VND/USD | cuối tháng | NHNN / ngân hàng thương mại | | |
| 10 | INTEREST | Lãi suất (tái cấp vốn là chính) | %/năm | giữ nguyên | NHNN | | |
| 11 | FEDRATE | Lãi suất Fed | %/năm | giữ nguyên | FRED | | |
| 12 | VIX | Chỉ số biến động VIX | điểm | cuối tháng | FRED | | |
| 13 | IIP | Chỉ số sản xuất công nghiệp, nối chuỗi | chỉ số | giữ nguyên | Cục Thống kê | | |
| 14 | M2 | Cung tiền M2 (tùy chọn) | | giữ nguyên | NHNN | | tùy chọn |
| 15 | GAS_RETAIL | Giá bán lẻ xăng RON 95-III vùng 1 (Petrolimex) | VND/lít | bình quân theo số ngày giữa các kỳ điều chỉnh | Thông cáo báo chí Petrolimex, Bộ Công Thương | 2026-10 | **xong** |
| 16 | FFLOW | Dòng vốn ngoại (HOSE) | | giữ nguyên | HOSE | | |
| 17 | CPI_US | CPI Mỹ | chỉ số | giữ nguyên | FRED | | |
| 18 | GDEMAND | Cầu toàn cầu | | giữ nguyên | | | |

## GAS_RETAIL (chi tiết)
- File: `data/raw/GAS_RETAIL.csv` (date,value; value = bình quân tháng của giá ngày), 179 dòng từ 2011-09 đến 2026-07. Dòng 2011-09..2011-12 là tháng đệm, chuỗi dùng cho mẫu bắt đầu từ 2012-01.
- File đầy đủ các cột (`gas_end` giá cuối tháng, `gas_avg` bình quân tháng, `lgas_end`, `dlgas_end`): `data/raw/gas_retail/GAS_RETAIL_monthly.csv`.
- Nguồn: bảng giá trong Thông cáo báo chí Petrolimex (OCR bảng ảnh, kiểm tra chéo bằng Vùng 2 − Vùng 1 và bằng chuỗi giá cũ/mới), một số kỳ bổ sung tay có ghi chú trong `manual_prices.csv` và `manual_fix.csv`.
- Sản phẩm: RON 95 → RON 95-II (2016–2017) → RON 95-III (từ 2017); từ 06/2026 là E10 RON 95-III Mức 3. Loại trừ RON 95-IV và dòng E10 trong 01/2026–05/2026 khi cùng lúc có xăng không chứa ethanol.
- 09/2011–02/2012: giá không đổi 21.300 đ/lít (không có kỳ điều chỉnh xăng nào từ 26/08/2011 đến 07/03/2012; xem Dân Trí 26/12/2011 và VietnamPlus 07/03/2012).
- Kỳ 20/04/2012 không có thông cáo trên website, bổ sung tay: tăng 900 từ 23.400 (khớp thông cáo 09/05/2012).
- Tháng 4/2015: giá phẳng thật (một lần điều chỉnh, kiểm chứng bằng tin 5/5/2015).
- Tái tạo: chạy `plx_gas_ocr.R` trong RStudio (đọc `manual_*.csv` trong `plx_out/` trước, thư mục làm việc sau).
