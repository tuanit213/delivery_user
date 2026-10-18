import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

class PollingController<T extends Object> extends ChangeNotifier {
  PollingController(this.load, {this.interval = const Duration(seconds: 5)});

  final Future<T> Function() load;
  final Duration interval;
  T? _data;
  Object? _error;
  DateTime? _updatedAt;
  bool _isRefreshing = false;
  bool _disposed = false;
  int _revision = 0;
  Timer? _timer;

  T? get data => _data;
  Object? get error => _error;
  DateTime? get updatedAt => _updatedAt;
  bool get isRefreshing => _isRefreshing;
  bool get isInitialLoading => data == null && isRefreshing;

  void start() {
    if (_disposed || _timer != null) return;
    _timer = Timer.periodic(interval, (_) {
      if (!isRefreshing) unawaited(refresh());
    });
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    _isRefreshing = true;
    notifyListeners();
    try {
      final next = await Future<T>.sync(load);
      if (_disposed || revision != _revision) return;
      _data = next;
      _error = null;
      _updatedAt = DateTime.now();
    } catch (failure) {
      if (_disposed || revision != _revision) return;
      _error = failure;

      if (failure is SessionChangedException ||
          failure is ApiException &&
              [401, 403, 404].contains(failure.statusCode)) {
        _data = null;
        _updatedAt = null;
      }
    } finally {
      if (!_disposed && revision == _revision) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _timer?.cancel();
    super.dispose();
  }
}
