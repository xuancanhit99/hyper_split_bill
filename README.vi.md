# Hyper Split Bill (Chia sẻ hóa đơn) 🧾💸

Hyper Split Bill là một ứng dụng Flutter được thiết kế để đơn giản hóa quá trình chia sẻ các hóa đơn chung. Người dùng có thể tải lên hình ảnh hóa đơn, ứng dụng sẽ tự động trích xuất các mục và giá cả bằng OCR và AI, chỉnh sửa chi tiết, gán các mục cho người tham gia và tính toán phần chia của mỗi người.

## ✨ Tính năng

*   **Xác thực người dùng:** Đăng nhập và đăng ký an toàn (có thể sử dụng Supabase Auth).
*   **Tải lên hóa đơn:** Tải lên hình ảnh hóa đơn từ thư viện thiết bị hoặc máy ảnh.
*   **Cắt ảnh:** Cắt ảnh đã tải lên để tập trung vào khu vực hóa đơn liên quan.
*   **Xử lý OCR:** Trích xuất dữ liệu văn bản từ hình ảnh hóa đơn bằng dịch vụ Nhận dạng ký tự quang học (OCR).
*   **Cấu trúc hóa bằng AI:** Tự động cấu trúc văn bản được trích xuất thành các mục hóa đơn, giá cả và có thể xác định người tham gia bằng dịch vụ AI/LLM.
*   **Chỉnh sửa hóa đơn:** Thêm, chỉnh sửa hoặc xóa các mục hóa đơn, người tham gia và thông tin chung về hóa đơn (ví dụ: tiêu đề, ngày, đơn vị tiền tệ) theo cách thủ công.
*   **Gán người tham gia:** Gán các mục cụ thể cho những người tham gia khác nhau trong hóa đơn.
*   **Tính toán chia sẻ:** Tự động tính toán số tiền mỗi người tham gia nợ.
*   **Lịch sử hóa đơn:** (Giả định) Xem và quản lý các hóa đơn đã xử lý trước đó.
*   **Tương tác Chatbot:** (Tiềm năng) Tương tác với chatbot để được hỗ trợ hoặc tinh chỉnh dữ liệu có cấu trúc.

## 🛠️ Công nghệ sử dụng

*   **Framework:** Flutter
*   **Kiến trúc:** Clean Architecture (Data, Domain, Presentation)
*   **Quản lý trạng thái:** Bloc / flutter_bloc
*   **Tiêm phụ thuộc (Dependency Injection):** get_it / injectable
*   **Định tuyến (Routing):** go_router
*   **Backend:** Supabase (Auth, Database)
*   **Dịch vụ bên ngoài:**
    *   API Dịch vụ OCR (Google Gemini, Grok Vision, Google Cloud Vision, Tesseract)
    *   API Dịch vụ AI/LLM (Google Gemini, Grok)
*   **Xử lý ảnh:** image_picker, image_cropper

## 🏗️ Tổng quan kiến trúc

Ứng dụng tuân theo các nguyên tắc của Clean Architecture, tách biệt các mối quan tâm thành ba lớp chính:

1.  **Presentation (Trình bày):** Chứa UI (Widgets, Pages) và Quản lý trạng thái (Blocs). Xử lý tương tác người dùng và hiển thị dữ liệu.
2.  **Domain (Miền):** Chứa logic nghiệp vụ (Use Cases) và các thực thể cốt lõi (Entities). Xác định chức năng cốt lõi của ứng dụng độc lập với UI hoặc nguồn dữ liệu.
3.  **Data (Dữ liệu):** Chứa các triển khai Repository và Nguồn dữ liệu (Data Sources) (Remote - API, Supabase; Local - có thể là bộ đệm). Xử lý việc truy xuất và lưu trữ dữ liệu.

Tiêm phụ thuộc được quản lý bằng `get_it` và `injectable` để tách rời và kiểm thử dễ dàng hơn. Điều hướng được xử lý bởi `go_router`.

## 🚀 Bắt đầu

**Yêu cầu:**

*   Đã cài đặt Flutter SDK (kiểm tra `pubspec.yaml` để biết các ràng buộc phiên bản)
*   Đã cài đặt Dart SDK
*   Trình soạn thảo như VS Code hoặc Android Studio
*   Tài khoản Supabase và dự án đã được thiết lập
*   Khóa API cho các dịch vụ OCR và AI/LLM được sử dụng

**Cài đặt & Thiết lập:**

1.  **Sao chép kho lưu trữ:**
    ```bash
    git clone https://github.com/xuancanhit99/hyper_split_bill.git
    cd hyper_split_bill
    ```
2.  **Thiết lập biến môi trường:**
    *   Sao chép tệp `.env.example` thành `.env`:
        ```bash
        cp .env.example .env
        ```
    *   Điền các giá trị bắt buộc vào tệp `.env`, bao gồm:
        *   Supabase URL và Anon Key
        *   Khóa API cho các dịch vụ OCR và AI đã chọn (Google AI Studio, Grok API)

3.  **Cài đặt các phụ thuộc:**
    ```bash
    flutter pub get
    ```
4.  **Tạo mã tiêm phụ thuộc:**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

**Chạy ứng dụng:**

*   **Web:**
    ```bash
    flutter run -d chrome
    ```
*   **Mobile (Android/iOS):**
    *   Đảm bảo bạn có thiết bị được kết nối hoặc trình giả lập/mô phỏng đang chạy.
    *   ```bash
        flutter run
        ```

## 📁 Cấu trúc dự án (thư mục `lib`)

```
lib/
├── app.dart                  # Thiết lập widget ứng dụng chính (MaterialApp, Router)
├── injection_container.dart  # Thiết lập tiêm phụ thuộc (GetIt)
├── injection_module.dart     # Các module cho injectable
├── main.dart                 # Điểm vào ứng dụng
├── common/                   # Widgets/Tiện ích dùng chung cho các tính năng
├── core/                     # Chức năng cốt lõi (cấu hình, hằng số, xử lý lỗi, định tuyến, chủ đề)
│   ├── config/
│   ├── constants/
│   ├── error/
│   ├── router/
│   └── theme/
└── features/                 # Các module tính năng (theo Clean Architecture)
    ├── auth/                 # Tính năng xác thực
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── bill_splitting/       # Tính năng chia sẻ hóa đơn
        ├── data/             # Nguồn dữ liệu, mô hình, triển khai repository
        ├── domain/           # Thực thể, trường hợp sử dụng, giao diện repository
        └── presentation/     # Blocs, trang, widgets