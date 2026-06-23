# TRANSACTION ANOMALIES GUIDE

# 1. Transaction Overview

## Definition

Transaction là một đơn vị công việc (Unit of Work) trong cơ sở dữ liệu, bao gồm một hoặc nhiều thao tác đọc và ghi dữ liệu được thực hiện như một thể thống nhất.

Một Transaction chỉ được xem là hoàn thành khi toàn bộ các thao tác bên trong thành công. Nếu xảy ra lỗi ở bất kỳ bước nào, toàn bộ thay đổi phải được hoàn tác (Rollback).

Trong hệ thống ngân hàng, các nghiệp vụ như:

* Chuyển tiền
* Rút tiền
* Nạp tiền
* Mở tài khoản

đều phải được thực hiện bên trong Transaction.

### Typical Transaction Flow

1. Bắt đầu Transaction.
2. Kiểm tra dữ liệu đầu vào.
3. Kiểm tra điều kiện nghiệp vụ.
4. Thực hiện các thao tác đọc và ghi dữ liệu.
5. Ghi lịch sử và Audit Log.
6. Commit nếu thành công.
7. Rollback nếu có lỗi.

---

# 2. ACID Properties

Để đảm bảo dữ liệu luôn chính xác, mọi Transaction trong hệ thống phải tuân thủ bốn tính chất ACID.

## Atomicity

Transaction phải được thực hiện toàn bộ hoặc không thực hiện gì cả.

Ví dụ:

Trong giao dịch chuyển tiền:

* Trừ tiền thành công.
* Cộng tiền thất bại.

=> Hệ thống phải Rollback để tránh mất tiền.

---

## Consistency

Transaction phải đưa cơ sở dữ liệu từ trạng thái hợp lệ này sang trạng thái hợp lệ khác.

Ví dụ:

* Không cho phép số dư âm.
* Không cho phép chuyển tiền đến tài khoản không tồn tại.

---

## Isolation

Các Transaction chạy đồng thời không được làm ảnh hưởng lẫn nhau theo cách gây sai lệch dữ liệu.

Isolation là nguyên nhân xuất hiện các Transaction Anomalies được trình bày trong tài liệu này.

---

## Durability

Sau khi Commit thành công, dữ liệu phải được lưu trữ bền vững và không bị mất ngay cả khi hệ thống gặp sự cố.

---

# 3. Transaction Anomalies Overview

## Definition

Transaction Anomaly là hiện tượng dữ liệu không nhất quán phát sinh khi nhiều Transaction cùng truy cập và thao tác trên cùng một tập dữ liệu nhưng không được cô lập (Isolation) đúng cách.

Các lỗi này không phải do cú pháp SQL sai, mà do sự tương tác đồng thời giữa nhiều Transaction.

Trong hệ thống ngân hàng, các lỗi này có thể dẫn đến:

* Sai số dư tài khoản.
* Báo cáo sai.
* Kiểm tra hạn mức sai.
* Mất dữ liệu cập nhật.
* Hiển thị thông tin không chính xác.

Bốn Transaction Anomalies phổ biến gồm:

* Dirty Read
* Non-repeatable Read
* Phantom Read
* Lost Update

---

# 4. Dirty Read

## Definition

Dirty Read xảy ra khi một Transaction đọc dữ liệu chưa được Commit bởi một Transaction khác.

Nếu Transaction ghi sau đó bị Rollback, dữ liệu mà Transaction đọc được thực tế chưa từng tồn tại trong hệ thống.

---

## Banking Example

Giả sử tài khoản A có số dư:

100.000.000 VND

Transaction A thực hiện:

* Trừ tiền còn 50.000.000 VND.
* Chưa Commit.

Trong lúc đó:

Transaction B đọc số dư và thấy:

50.000.000 VND

Sau đó Transaction A gặp lỗi và Rollback.

Số dư thực tế vẫn là:

100.000.000 VND.

Transaction B đã đọc một giá trị không tồn tại thực sự.

---

## Consequences

* Hiển thị sai số dư.
* Báo cáo sai.
* Đưa ra quyết định dựa trên dữ liệu chưa hợp lệ.

---

## Prevention

Không cho phép đọc dữ liệu chưa Commit.

Sử dụng mức cô lập phù hợp như READ COMMITTED hoặc cao hơn.

---

# 5. Non-repeatable Read

## Definition

Non-repeatable Read xảy ra khi cùng một Transaction đọc lại cùng một bản ghi nhưng nhận được giá trị khác nhau vì Transaction khác đã cập nhật dữ liệu và Commit trong khoảng thời gian giữa hai lần đọc.

---

## Banking Example

Transaction A đọc số dư:

100.000.000 VND

Trong lúc Transaction A vẫn đang thực hiện:

Transaction B cập nhật số dư thành:

120.000.000 VND

và Commit.

Transaction A đọc lại cùng tài khoản.

Kết quả:

120.000.000 VND.

Hai lần đọc cùng một bản ghi nhưng nhận được hai kết quả khác nhau.

---

## Consequences

* Báo cáo không nhất quán.
* Dữ liệu thay đổi trong cùng một giao dịch.
* Sai lệch khi tính toán.

---

## Prevention

Sử dụng mức cô lập REPEATABLE READ hoặc các cơ chế khóa phù hợp.

---

# 6. Phantom Read

## Definition

Phantom Read xảy ra khi một Transaction thực hiện truy vấn theo điều kiện và thu được một tập bản ghi. Trong khi Transaction đó chưa kết thúc, Transaction khác thêm hoặc xóa các bản ghi thỏa mãn điều kiện truy vấn. Khi Transaction đầu tiên thực hiện lại cùng truy vấn, tập kết quả thay đổi do xuất hiện hoặc biến mất các bản ghi mới (Phantom Rows).

Khác với Non-repeatable Read, Phantom Read không làm thay đổi giá trị của một bản ghi đã tồn tại mà làm thay đổi số lượng hoặc tập hợp các bản ghi được trả về.

---

## Banking Example

Ngân hàng quy định:

Tổng số tiền chuyển trong ngày không được vượt quá:

100.000.000 VND.

Transaction A kiểm tra:

Tổng tiền hôm nay:

80.000.000 VND.

Trong lúc đó:

Transaction B tạo thêm một giao dịch chuyển:

15.000.000 VND

và Commit.

Transaction A tiếp tục xử lý dựa trên kết quả cũ.

Nếu Transaction A thực hiện truy vấn lại, tổng tiền sẽ trở thành:

95.000.000 VND.

Sự xuất hiện của giao dịch mới chính là Phantom Row.

---

## Consequences

* Kiểm tra hạn mức sai.
* Báo cáo thống kê sai.
* Kết quả truy vấn không ổn định.

---

## Prevention

Sử dụng SERIALIZABLE hoặc các cơ chế khóa phạm vi dữ liệu (Range Lock).

---

# 7. Lost Update

## Definition

Lost Update xảy ra khi hai Transaction cùng cập nhật một bản ghi dựa trên cùng một giá trị ban đầu. Kết quả cập nhật của một Transaction bị Transaction còn lại ghi đè, dẫn đến mất dữ liệu.

---

## Banking Example

Tài khoản có số dư:

100.000.000 VND.

Transaction A:

Rút 30.000.000 VND.

Transaction B:

Rút 50.000.000 VND.

Cả hai cùng đọc số dư ban đầu:

100.000.000 VND.

Sau khi hai Transaction hoàn thành, số dư cuối cùng có thể là:

70.000.000 VND

hoặc

50.000.000 VND

Trong khi kết quả đúng phải là:

20.000.000 VND.

Một trong hai lần cập nhật đã bị mất.

---

## Consequences

* Sai số dư tài khoản.
* Mất dữ liệu cập nhật.
* Giao dịch tài chính không chính xác.

---

## Prevention

Sử dụng khóa dữ liệu phù hợp hoặc cập nhật dữ liệu theo cơ chế nguyên tử (Atomic Update).

---

# 8. Comparison Summary

| Anomaly             | Nguyên nhân                                    | Dấu hiệu                                        |
| ------------------- | ---------------------------------------------- | ----------------------------------------------- |
| Dirty Read          | Đọc dữ liệu chưa Commit                        | Đọc dữ liệu không tồn tại thực sự               |
| Non-repeatable Read | Bản ghi bị UPDATE giữa hai lần đọc             | Hai lần đọc cùng một dòng cho kết quả khác nhau |
| Phantom Read        | Có INSERT hoặc DELETE làm thay đổi tập kết quả | Số lượng bản ghi thay đổi                       |
| Lost Update         | Hai Transaction cùng ghi lên một dữ liệu       | Một cập nhật bị ghi đè                          |

---

# 9. Design Principles

Để hạn chế các Transaction Anomalies trong hệ thống quản lý giao dịch ngân hàng, nhóm thống nhất các nguyên tắc thiết kế sau:

* Mọi nghiệp vụ tài chính phải được thực hiện trong Transaction.
* Toàn bộ Business Logic được triển khai trong Stored Procedure.
* Không thao tác trực tiếp với bảng dữ liệu từ ứng dụng.
* Kiểm tra đầy đủ dữ liệu đầu vào trước khi cập nhật.
* Sử dụng mức cô lập (Isolation Level) phù hợp với từng nghiệp vụ.
* Ghi Audit Log cho mọi thay đổi quan trọng.
* Ưu tiên tính đúng đắn của dữ liệu hơn hiệu năng đối với các giao dịch tài chính.