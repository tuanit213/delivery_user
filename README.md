# LogiRoute User

Ứng dụng khách hàng viết bằng Flutter: đăng ký, đăng nhập, tạo đơn, báo giá, theo dõi giao hàng, hủy đơn chờ và xem lịch sử. Giao diện pixel có ảnh chuyển động và hỗ trợ giảm chuyển động.

## Chạy local

Cài Flutter tương thích Dart `^3.11.5`, sau đó chạy:

```sh
flutter pub get
flutter run -d chrome --web-port 8081 --dart-define=API_BASE_URL=http://127.0.0.1:5031
```

Backend LogiRoute phải chạy riêng tại cổng 5031. Kho này chỉ chứa ứng dụng khách hàng, không chứa backend hoặc tài khoản trình diễn.

## Kiểm tra

```sh
flutter analyze
flutter test
```

## Build web

```sh
flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Thay địa chỉ API bằng gateway thực tế. Đưa nội dung `build/web` lên web server. Khi phục vụ ứng dụng qua HTTPS, API cũng cần HTTPS và cấu hình CORS cho origin của ứng dụng.

## Cấu hình

- `API_BASE_URL`: gateway backend, mặc định `http://127.0.0.1:5031`.
- `MAP_TILE_URL`: URL tile XYZ, mặc định OpenStreetMap.
- `GEOCODING_BASE_URL`: dịch vụ tương thích Photon.

Font và giấy phép nằm trong `assets/fonts` và `assets/font_licenses`. Bản đồ và tìm địa chỉ cần kết nối mạng. Mã xác nhận nhận hàng được hiển thị trong ứng dụng, không gửi SMS. Backend kiểm tra phí, quyền truy cập và trạng thái đơn.

Phiên bản này tập trung vào Flutter Web. Các thư mục nền tảng được giữ trong mã nguồn; Android/iOS cần toolchain và kiểm thử thiết bị riêng. Windows desktop hiện tắt trong `pubspec.yaml`.
