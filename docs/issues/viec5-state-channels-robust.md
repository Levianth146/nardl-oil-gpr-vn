# Việc 5 - Trạng thái, kênh truyền dẫn, kiểm định bền
Branch: `viec5/state-channels-robust`. Phụ thuộc: lõi của Việc 3. Chạy trên mô hình nền không có biến trung gian.

- [ ] Trạng thái: dầu tách theo GPR cao/thấp (ngưỡng 0,50 và 0,75), Wald θ_cao = θ_thấp; trước/sau COVID và trước/sau Ukraine bằng tổng riêng phần theo giai đoạn (không dùng biến tương tác, không chia mẫu thật)
- [ ] Kênh: thêm từng EXCH, INTEREST, VIX, FFLOW, GAS_RETAIL vào mô hình nền (cùng mẫu, cùng lag), hệ số trước/sau và % suy giảm; Sobel cho trung gian I(1), ARDL dừng cho I(0); cảnh báo khi ρ gần 0
- [ ] Kiểm định bền: GPR đe dọa/hành động/trực giao, WTI, OIL_VND, OIL_REAL, CPI lõi, VN-Index bình quân tháng, Thiết kế B, đổi lag tối đa, bỏ biến giả
- [ ] Mẫu con: 01/2012–12/2025 và 01/2016–07/2026; đổi mốc D_TIGHT22 (12/2022 hoặc 06/2023)

Đầu ra: bảng trạng thái, bảng kênh, bảng kiểm định bền (mỗi biến thể một dòng).
