# Việc 2 - Biến phái sinh và kiểm định tính dừng
Branch: `viec2/derive-unitroot`. Phụ thuộc: Việc 1.

- [ ] Log các biến (LINTEREST = ln(1 + r/100); GDEMAND, FFLOW không log; FFLOW chuẩn hóa theo độ lệch chuẩn)
- [ ] Tổng riêng phần OIL_P/OIL_N, GPR_P/GPR_N (thêm WTI, GPR_THREAT, GPR_ACT cho kiểm định bền); GPR_ORTH tính trên số gia rồi cộng dồn
- [ ] Biến giả: D_COVID, D_TIGHT22 (nền); D_POST_UKR chỉ dùng cho trạng thái; trạng thái GPR cao dùng giá trị kỳ trước và tổng riêng phần theo trạng thái
- [ ] Thống kê mô tả, tương quan, VIF (tính trên số gia)
- [ ] ADF, PP, KPSS, Zivot–Andrews ở mức và sai phân; bảng kết luận I(0)/I(1)/I(2)
- [ ] Nếu LGPR là I(0): báo nhóm, chuyển sang cú sốc ngưỡng GPR (D_GPR_HIGH, GPR > phân vị 90). Nếu có biến I(2): báo nhóm ngay

Đầu ra: `data/processed/panel_derived.csv` (~40 cột), bảng mô tả + VIF, bảng bậc tích hợp.
