# Việc 4 - Mô hình 2 (VN-Index), nhân tử động, tích hợp
Branch: `viec4/vnindex-multipliers`. Phụ thuộc: lõi của Việc 3.

- [ ] Mô hình 2 cho LVNI: cùng bộ biến kiểm soát và biến giả như Mô hình 1 (khác duy nhất biến phụ thuộc)
- [ ] Dynamic multipliers 24 tháng cho dầu và GPR, hai chiều; CI bootstrap; đỉnh, nửa đời; kiểm tra hội tụ về hệ số dài hạn
- [ ] Granger–Toda–Yamamoto (k theo BIC, dmax = 1); bảng so sánh CPI và VN-Index theo dầu và GPR
- [ ] Tích hợp: `config.yml`, `run_all.R`, lưu seed và phiên bản gói; kiểm tra chéo kết quả giữa các việc; đóng băng kết quả vào `outputs/frozen/`, gắn tag `v0.2-frozen`

Đầu ra: kết quả Mô hình 2, bảng và hình nhân tử, bảng so sánh, quy trình chạy nối.
