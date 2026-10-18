import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:userapp/theme/app_fonts.dart';

import '../../theme/app_colors.dart';

const appRed = AppColors.red;

class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  const PageHeader(this.title, {super.key, this.fallbackRoute = '/home'});
  final String title, fallbackRoute;
  @override
  Size get preferredSize => const Size.fromHeight(72);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 72,
    leading: IconButton(
      tooltip: 'Quay lại',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(fallbackRoute),
    ),
    title: Text(
      title,
      style: TextStyle(
        fontFamily: AppFonts.body,
        color: AppColors.text,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(2),
      child: Divider(height: 2, thickness: 2, color: AppColors.text),
    ),
  );
}

class CardBox extends StatelessWidget {
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: const BoxDecoration(
      color: AppColors.panel,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.text, width: 1.5),
      ),
      boxShadow: [BoxShadow(color: Color(0xFFD4DBCF), offset: Offset(4, 4))],
    ),
    child: child,
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.outline = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool outline;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    width: double.infinity,
    decoration: BoxDecoration(
      boxShadow: onTap == null
          ? []
          : const [BoxShadow(color: AppColors.text, offset: Offset(3, 3))],
    ),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: outline ? AppColors.text : Colors.white,
        backgroundColor: outline ? AppColors.panel : appRed,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.muted,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: AppColors.text, width: 1.5),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

class InputBox extends StatelessWidget {
  const InputBox(
    this.label,
    this.hint, {
    super.key,
    this.icon,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
  });
  final String label, hint;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon, size: 19),
        ),
      ),
    ],
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 42 : 34,
          height: large ? 42 : 34,
          decoration: const BoxDecoration(
            color: AppColors.amber,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.text, width: 2),
            ),
            boxShadow: [BoxShadow(color: AppColors.text, offset: Offset(3, 3))],
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.text,
            size: large ? 25 : 21,
          ),
        ),
        const SizedBox(width: 13),
        Text(
          'LOGIROUTE',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: large ? 40 : 32,
            height: 1,
            color: AppColors.text,
            letterSpacing: 1.4,
          ),
        ),
      ],
    ),
  );
}

class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child, this.maxWidth = 1040});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class AppNav extends StatelessWidget {
  const AppNav(this.index, {super.key});
  final int index;
  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.home_outlined, 'Trang chủ', '/home'),
      (Icons.inventory_2_outlined, 'Đơn hàng', '/orders'),
      (Icons.notifications_none, 'Thông báo', '/notifications'),
      (Icons.person_outline, 'Hồ sơ', '/profile'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.text, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: NavigationBar(
              height: 76,
              backgroundColor: AppColors.panel,
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFFFD69C),
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(tabs[i].$3),
              destinations: tabs
                  .map(
                    (e) => NavigationDestination(
                      icon: Icon(e.$1, size: 22),
                      label: e.$2,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class Badge extends StatelessWidget {
  const Badge(this.label, {super.key, this.color = appRed});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
