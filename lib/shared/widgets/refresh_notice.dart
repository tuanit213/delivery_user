import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Indicates that visible data is the last successful snapshot, not a live read.
class RefreshNotice extends StatelessWidget {
  const RefreshNotice({
    super.key,
    required this.onRetry,
    required this.isRefreshing,
    this.updatedAt,
  });

  final VoidCallback onRetry;
  final bool isRefreshing;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final time = updatedAt;
    final stamp = time == null
        ? ''
        : ' lúc ${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel2,
          border: Border.all(color: AppColors.text),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sync_problem, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chưa cập nhật được dữ liệu',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text('Đang hiển thị lần tải thành công gần nhất$stamp.'),
                  TextButton.icon(
                    onPressed: isRefreshing ? null : onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(isRefreshing ? 'Đang thử lại…' : 'Thử lại'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
