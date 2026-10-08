# VIỆC 3 - Lõi NARDL dùng chung cho Mô hình 1 (LCPI) và Mô hình 2 (LVNI)
# - dựng ma trận ECM; lưới 500 cấu hình lag, cùng một mẫu, chọn theo BIC
#   (lọc tham số <= 25 và Breusch-Godfrey(6) không bác bỏ)
# - bounds test: F (vcov cổ điển) và t của rho, giá trị tới hạn mô phỏng theo n, k thật
# - hệ số dài hạn L = -theta/rho (delta-method, Newey-West); Wald đối xứng dài hạn/ngắn hạn
# - đối chiếu với gói kardl (hoặc nardl) trên cùng panel
