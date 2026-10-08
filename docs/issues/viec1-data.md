# Việc 1 - Thu thập và làm sạch dữ liệu thô
Branch: `viec1/data`

- [ ] Lấy 18 biến 01/2012–07/2026 (Cục Thống kê, FRED, EIA, Caldara–Iacoviello, HOSE, NHNN), mỗi biến một CSV (date,value)
- [ ] Chốt một loại tỷ giá cho cả mẫu (bình quân liên ngân hàng hoặc tỷ giá bán ra của một NHTM lớn; không dùng tỷ giá trung tâm vì chỉ có từ 04/01/2016)
- [ ] Gộp tháng: VNINDEX, EXCH, VIX cuối tháng; Brent, WTI bình quân tháng; GAS_RETAIL bình quân theo ngày; còn lại giữ nguyên
- [ ] CPI, CPI lõi, IIP: nhập dạng tháng trước = 100, nối chuỗi (CPI có 4 mối nối: 2009, 2014, 2019, 2024); kiểm tra tích 12 tháng khớp % so với cùng kỳ của Cục Thống kê; khử mùa Tết (hồi quy Δlog theo cửa sổ Tết −1,0,+1 và dummy tháng)
- [ ] Kiểm tra đủ 175 tháng, không thủng, không ngoại lệ vô lý; vẽ từng chuỗi
- [ ] Kiểm tra độ dài INTEREST (tái cấp vốn là chính), FFLOW (HOSE), CPI lõi; M2 chỉ lấy nếu dựng được chuỗi mức đến 07/2026
- [x] GAS_RETAIL (đã xong, xem data/raw/gas_retail)

Đầu ra: 18 CSV, `data/processed/panel_monthly.csv`, `data/data_dictionary.md` đã điền đủ (nguồn, đơn vị, ngày truy cập, cách gộp).
Xong thì gắn tag `v0.1-data` sau khi merge vào dev.
