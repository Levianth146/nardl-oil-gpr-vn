# Việc 3 - Lõi NARDL và Mô hình 1 (CPI)
Branch: `viec3/nardl-core-cpi`. Phụ thuộc: Việc 2. Chặn: Việc 4 và 5 (làm lõi trước).

- [ ] Lõi `R/nardl_core.R`: ma trận ECM; lưới 500 cấu hình lag, cùng một mẫu, chọn BIC, lọc tham số ≤ 25 và Breusch–Godfrey(6) không bác bỏ
- [ ] Bounds test: F (vcov cổ điển) và t của ρ, giá trị tới hạn mô phỏng theo n và k thật; kết luận ba vùng
- [ ] Hệ số dài hạn L = −θ/ρ (delta-method, Newey–West); Wald đối xứng dài hạn (θ⁺ = θ⁻) và ngắn hạn (Σπ⁺ = Σπ⁻)
- [ ] Chẩn đoán: BG, ARCH-LM, JB, RESET, CUSUM; in rõ n, k, lag, ρ
- [ ] Đối chiếu hệ số dài hạn và F của bounds test với gói kardl (hoặc nardl) trên cùng panel

Đầu ra: lõi chạy được (giao cho Việc 4, 5), kết quả Mô hình 1 đầy đủ.
