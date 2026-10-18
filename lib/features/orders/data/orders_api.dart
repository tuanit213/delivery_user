import 'package:userapp/core/network/api_client.dart';

String _compactOrderStatus(String raw) {
  final value = raw
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
      .toUpperCase();
  return const {
        'PENDING': 'CHOXACNHAN',
        'ASSIGNED': 'CHOSHIPPERXACNHAN',
        'ACCEPTED': 'DAXACNHAN',
        'DELIVERING': 'DANGGIAO',
        'COMPLETED': 'HOANTHANH',
        'CANCELLED': 'DAHUY',
        'FAILED': 'GIAOTHATBAI',
        'RETURNED': 'DAHOANTRA',
      }[value] ??
      value;
}

String customerOrderStatusLabel(String raw) {
  switch (_compactOrderStatus(raw)) {
    case 'CHOXACNHAN':
      return 'Chờ phân công';

    case 'CHOSHIPPERXACNHAN':
      return 'Chờ tài xế xác nhận';

    case 'DAXACNHAN':
      return 'Tài xế đã nhận đơn';

    case 'DANGGIAO':
    case 'DANGVANCHUYEN':
      return 'Đang giao hàng';

    case 'DAGIAO':
    case 'HOANTHANH':
      return 'Đã giao thành công';

    case 'GIAOTHATBAI':
      return 'Giao hàng thất bại';

    case 'DAHUY':
      return 'Đã hủy';

    case 'HOANTRA':
    case 'DAHOANTRA':
      return 'Hoàn trả';

    case 'TREO':
      return 'Đang tạm giữ';

    case 'CANDIEUPHOTHUCONG':
      return 'Cần điều phối thủ công';

    default:
      final value = raw.trim();
      return value.isEmpty ? 'Chưa có trạng thái' : value;
  }
}

bool isCustomerOrderCompleted(String raw) {
  switch (_compactOrderStatus(raw)) {
    case 'DAGIAO':
    case 'HOANTHANH':
      return true;
    default:
      return false;
  }
}

bool isCustomerOrderClosed(String raw) {
  switch (_compactOrderStatus(raw)) {
    case 'DAGIAO':
    case 'HOANTHANH':
    case 'DAHUY':
    case 'HOANTRA':
    case 'DAHOANTRA':
      return true;
    default:
      return false;
  }
}

bool isCustomerOrderActive(String raw) => !isCustomerOrderClosed(raw);

String customerHistoryDescription(String status, {String? backendNote}) {
  switch (_compactOrderStatus(status)) {
    case 'CHOXACNHAN':
      final note = backendNote?.toLowerCase() ?? '';
      if (note.contains('trả') ||
          note.contains('dieu phoi') ||
          note.contains('điều phối')) {
        return 'Đơn hàng đang được tìm tài xế phù hợp khác.';
      }
      return 'Đơn hàng đã được tạo và đang chờ phân công tài xế.';

    case 'CHOSHIPPERXACNHAN':
      return 'Hệ thống đã phân công tài xế cho đơn hàng.';

    case 'DAXACNHAN':
      return 'Tài xế đã xác nhận nhận đơn.';

    case 'DANGGIAO':
    case 'DANGVANCHUYEN':
      return 'Tài xế đã lấy hàng và đang giao đến người nhận.';

    case 'DAGIAO':
    case 'HOANTHANH':
      return 'Đơn hàng đã được giao thành công.';

    case 'GIAOTHATBAI':
      return 'Tài xế chưa thể giao hàng thành công.';

    case 'DAHUY':
      return 'Đơn hàng đã được hủy.';

    case 'HOANTRA':
    case 'DAHOANTRA':
      return 'Đơn hàng đang trong quy trình hoàn trả.';

    case 'TREO':
      return 'Đơn hàng đang tạm giữ để xử lý thông tin.';

    default:
      return 'Trạng thái đơn hàng vừa được cập nhật.';
  }
}

class CreateOrderRequest {
  const CreateOrderRequest({
    required this.customerId,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.weightKg,
    required this.codAmount,
    required this.shippingFee,
    this.senderName,
    this.senderPhone,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  final String customerId,
      receiverName,
      receiverPhone,
      pickupAddress,
      deliveryAddress;
  final double weightKg, codAmount, shippingFee;
  final String? senderName, senderPhone;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'senderName': senderName,
    'senderPhone': senderPhone,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'pickupAddress': pickupAddress,
    'deliveryAddress': deliveryAddress,
    'weightKg': weightKg,
    'codAmount': codAmount,
    'shippingFee': shippingFee,
    if (pickupLatitude != null) 'viDoLay': pickupLatitude,
    if (pickupLongitude != null) 'kinhDoLay': pickupLongitude,
    if (deliveryLatitude != null) 'viDoGiao': deliveryLatitude,
    if (deliveryLongitude != null) 'kinhDoGiao': deliveryLongitude,
  };
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.codAmount,
    required this.shippingFee,
    this.createdAt,
    this.senderName,
    this.senderPhone,
    this.receiverName,
    this.receiverPhone,
    this.weightKg,
    this.sizeText,
    this.distanceKm,
    this.estimatedMinutes,
  });

  final String id, status, pickupAddress, deliveryAddress;
  final num codAmount, shippingFee;
  final String? createdAt;

  final String? senderName;
  final String? senderPhone;
  final String? receiverName;
  final String? receiverPhone;
  final num? weightKg;
  final String? sizeText;
  final num? distanceKm;
  final num? estimatedMinutes;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
    id: _value(json, const ['maDonHang', 'maDh', 'id']) ?? '',
    status:
        _value(json, const ['trangThai', 'trangThaiDonHang', 'status']) ??
        'Chưa có trạng thái',
    pickupAddress: _value(json, const ['diaChiLay', 'diaChiNguoiGui']) ?? '',
    deliveryAddress:
        _value(json, const ['diaChiGiao', 'diaChiNguoiNhan']) ?? '',
    codAmount:
        num.tryParse(
          _value(json, const ['tienCOD', 'tienCod', 'codAmount']) ?? '0',
        ) ??
        0,
    shippingFee:
        num.tryParse(
          _value(json, const ['phiVanChuyen', 'phiGiaoHang', 'shippingFee']) ??
              '0',
        ) ??
        0,
    createdAt: _value(json, const [
      'taoLuc',
      'ngayTao',
      'thoiGianTao',
      'createdAt',
    ]),
    senderName: _value(json, const ['tenNguoiGui', 'senderName']),
    senderPhone: _value(json, const ['sdtNguoiGui', 'senderPhone']),
    receiverName: _value(json, const ['tenNguoiNhan', 'receiverName']),
    receiverPhone: _value(json, const ['sdtNguoiNhan', 'receiverPhone']),
    weightKg: _numValue(json, const ['khoiLuong', 'trongLuong', 'weightKg']),
    sizeText: _value(json, const ['kichThuoc', 'size']),
    distanceKm: _numValue(json, const [
      'quangDuongKm',
      'khoangCach',
      'distanceKm',
    ]),
    estimatedMinutes: _numValue(json, const [
      'duKienGiaoPhut',
      'durationMinutes',
    ]),
  );
}

class OrderStatusHistory {
  const OrderStatusHistory({required this.status, this.time, this.note});
  final String status;
  final String? time, note;

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) =>
      OrderStatusHistory(
        status:
            _value(json, const ['trangThaiMoi', 'trangThai', 'status']) ?? '',
        time: _value(json, const ['thoiGian', 'ngayTao', 'createdAt']),
        note: _value(json, const ['ghiChu', 'note']),
      );
}

class DeliveryProof {
  const DeliveryProof({this.imageUrl, this.otpSignature, this.time});
  final String? imageUrl, otpSignature, time;

  factory DeliveryProof.fromJson(Map<String, dynamic> json) => DeliveryProof(
    imageUrl: _value(json, const ['hinhAnh', 'hinhAnhUrl', 'imageUrl']),
    otpSignature: _value(json, const ['chuKyOtp', 'otpSignature']),
    time: _value(json, const ['thoiGian', 'ngayTao', 'createdAt']),
  );
}

class CustomerNotification {
  const CustomerNotification({
    required this.orderId,
    required this.status,
    this.time,
    this.note,
  });

  final String orderId;
  final String status;
  final String? time;
  final String? note;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) =>
      CustomerNotification(
        orderId: _value(json, const ['maDh', 'maDonHang']) ?? '',
        status: _value(json, const ['trangThai', 'trangThaiMoi']) ?? '',
        time: _value(json, const ['thoiGian', 'createdAt']),
        note: _value(json, const ['ghiChu', 'note']),
      );
}

class OrderDetailData {
  const OrderDetailData({
    required this.order,
    required this.history,
    this.proof,
  });
  final CustomerOrder order;
  final List<OrderStatusHistory> history;
  final DeliveryProof? proof;
}

class OrdersApi {
  OrdersApi({ApiClient? client}) : _client = client ?? apiClient;
  final ApiClient _client;
  int? _observedSession;
  int _cacheEpoch = 0;
  final Map<String, Object> _requestVersions = {};
  final Map<String, Object> _detailRequests = {};

  void _ensureSession() {
    if (_observedSession != _client.sessionRevision) clearCache();
  }

  void clearCache() {
    _observedSession = _client.sessionRevision;
    _cacheEpoch++;
    _customerCache.clear();
    _customerRequests.clear();
    _requestVersions.clear();
    _detailRequests.clear();
  }

  final Map<String, List<CustomerOrder>> _customerCache = {};
  final Map<String, Future<List<CustomerOrder>>> _customerRequests = {};

  Future<CustomerOrder?> create(CreateOrderRequest order) async {
    _ensureSession();
    final epoch = _cacheEpoch;
    final response = await _client.post('/api/order', data: order.toJson());
    if (epoch != _cacheEpoch) throw const SessionChangedException();
    final map = _findOrderMap(response);
    final orderId = map == null
        ? null
        : _value(map, const ['maDonHang', 'maDh', 'id']);
    if (orderId == null || orderId.isEmpty) {
      throw const FormatException(
        'Server khong tra ve ma don hang sau khi tao.',
      );
    }

    final created = CustomerOrder.fromJson(map!);
    final current = _customerCache[order.customerId] ?? const [];
    _customerCache[order.customerId] = [created, ...current];
    return created;
  }

  Future<List<CustomerOrder>> forCustomer(
    String customerId, {
    bool forceRefresh = false,
  }) {
    _ensureSession();
    if (!forceRefresh && _customerCache.containsKey(customerId)) {
      return Future.value(_customerCache[customerId]!);
    }
    if (!forceRefresh && _customerRequests.containsKey(customerId)) {
      return _customerRequests[customerId]!;
    }
    final version = Object();
    _requestVersions[customerId] = version;
    late final Future<List<CustomerOrder>> request;
    request = _loadCustomerOrders(customerId, _cacheEpoch, version)
        .whenComplete(() {
          if (identical(_customerRequests[customerId], request)) {
            _customerRequests.remove(customerId);
          }
        });
    _customerRequests[customerId] = request;
    return request;
  }

  Future<CustomerOrder?> byId(String orderId) async {
    final detail = await detailById(orderId);
    return detail?.order;
  }

  Future<OrderDetailData?> detailById(String orderId) async {
    _ensureSession();
    final epoch = _cacheEpoch;
    final version = Object();
    _detailRequests[orderId] = version;
    try {
      Object? response;
      try {
        response = await _client.get('/api/order/$orderId');
      } on ApiException catch (error) {
        if (epoch != _cacheEpoch) throw const SessionChangedException();
        if (error.statusCode != 404) rethrow;
        if (identical(_detailRequests[orderId], version)) {
          for (final customerId in _customerCache.keys.toList()) {
            _customerCache[customerId] = _customerCache[customerId]!
                .where((order) => order.id != orderId)
                .toList();
          }
        }
        return null;
      }
      if (response is! Map) {
        throw const FormatException('Máy chủ trả thông tin đơn không hợp lệ.');
      }
      final orderMap = _map(response);
      final order = CustomerOrder.fromJson(orderMap);
      if (order.id.toLowerCase() != orderId.toLowerCase()) {
        throw const FormatException('Thông tin trả về không đúng mã đơn hàng.');
      }
      final historyResponse = await _client.get('/api/order/$orderId/history');
      final history = _listOfMaps(
        historyResponse,
      ).map(OrderStatusHistory.fromJson).toList();
      final proofMap = _mapOrNull(
        await _client.get('/api/delivery/$orderId/proof'),
      );
      if (epoch != _cacheEpoch) throw const SessionChangedException();
      if (identical(_detailRequests[orderId], version)) {
        _syncOrderToCaches(order);
      }

      return OrderDetailData(
        order: order,
        history: history,
        proof: proofMap == null ? null : DeliveryProof.fromJson(proofMap),
      );
    } finally {
      if (identical(_detailRequests[orderId], version)) {
        _detailRequests.remove(orderId);
      }
    }
  }

  Future<List<CustomerNotification>> notificationsForCustomer(
    String customerId,
  ) async {
    final response = await _client.get('/api/order/notifications');

    return _listOfMaps(response).map(CustomerNotification.fromJson).toList();
  }

  Future<List<CustomerOrder>> _loadCustomerOrders(
    String customerId,
    int epoch,
    Object version,
  ) async {
    final response = await _client.get(
      '/api/order',
      query: {'customerId': customerId},
    );
    final orders = _findOrderMaps(response)
        .where(
          (json) => _value(json, const ['maKh', 'maKhachHang']) == customerId,
        )
        .map(CustomerOrder.fromJson)
        .toList();
    if (epoch != _cacheEpoch) throw const SessionChangedException();
    if (!identical(_requestVersions[customerId], version)) return orders;
    _customerCache[customerId] = orders;

    return orders;
  }

  void _syncOrderToCaches(CustomerOrder order) {
    if (order.id.isEmpty) return;

    final customerIds = _customerCache.keys.toList();

    for (final customerId in customerIds) {
      final cached = _customerCache[customerId];
      if (cached == null) continue;

      final index = cached.indexWhere((item) => item.id == order.id);

      if (index < 0) continue;

      final next = List<CustomerOrder>.from(cached);
      next[index] = order;
      _customerCache[customerId] = next;
    }
  }
}

final ordersApi = OrdersApi();

List<Map<String, dynamic>> _findOrderMaps(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map(_map).toList();
  }
  if (value is Map) {
    final map = _map(value);
    for (final key in const [
      'data',
      'result',
      'items',
      'donHang',
      '\$values',
    ]) {
      final child = map[key];
      if (child != null) return _findOrderMaps(child);
    }
    return _value(map, const ['maDonHang', 'maDh', 'id']) == null ? [] : [map];
  }
  return [];
}

Map<String, dynamic>? _findOrderMap(Object? value) {
  final orders = _findOrderMaps(value);
  return orders.isEmpty ? null : orders.first;
}

Map<String, dynamic> _map(Map value) =>
    value.map((key, value) => MapEntry(key.toString(), value));

Map<String, dynamic>? _mapOrNull(Object? value) =>
    value is Map ? _map(value) : null;

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is List) return value.whereType<Map>().map(_map).toList();
  if (value is Map) {
    final map = _map(value);
    return _listOfMaps(map['\$values'] ?? map['data'] ?? map['items']);
  }
  return [];
}

num? _numValue(Map<String, dynamic> map, List<String> names) {
  final value = _value(map, names);
  return value == null ? null : num.tryParse(value);
}

String? _value(Map<String, dynamic> map, List<String> names) {
  final wanted = names.map((name) => name.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (wanted.contains(entry.key.toLowerCase()) && entry.value != null) {
      return entry.value.toString();
    }
  }
  return null;
}
