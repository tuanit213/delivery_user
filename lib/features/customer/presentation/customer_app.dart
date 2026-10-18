import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:userapp/theme/app_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../auth/presentation/auth_screens.dart';
import '../../home/presentation/home_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../orders/presentation/confirmation_screen.dart';
import '../../orders/presentation/create_order_screen.dart';
import '../../orders/presentation/order_flow_screens.dart';
import '../../profile/presentation/profile_screen.dart';

Future<void> runCustomerApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sessionStore.restore();
  runApp(const ProviderScope(child: LogiRouteApp()));
}

class LogiRouteApp extends StatefulWidget {
  const LogiRouteApp({super.key});

  @override
  State<LogiRouteApp> createState() => _LogiRouteAppState();
}

class _LogiRouteAppState extends State<LogiRouteApp> {
  late final GoRouter _router = createCustomerRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.panelAlt,
      colorScheme: const ColorScheme.light(
        primary: AppColors.red,
        secondary: AppColors.amber,
        surface: AppColors.panel,
        onSurface: AppColors.text,
      ),
      textTheme: AppFonts.textTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.panel,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF9F9F2),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        hintStyle: TextStyle(color: AppColors.faint, fontSize: 13),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: const RoundedRectangleBorder(),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
    ),
    routerConfig: _router,
  );
}

GoRouter createCustomerRouter() => GoRouter(
  initialLocation: appState.value.customerId == null ? '/login' : '/home',
  refreshListenable: appState,
  redirect: (context, state) {
    final signedIn = appState.value.customerId?.trim().isNotEmpty ?? false;
    final authPage =
        state.uri.path == '/login' || state.uri.path == '/register';
    if (!signedIn && !authPage) return '/login';
    if (signedIn && authPage) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/create-order',
      builder: (context, state) => const CreateOrderScreen(),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) => ConfirmationScreen(
        orderId: state.extra is String ? state.extra as String : null,
      ),
    ),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(
      path: '/orders/:id/status',
      builder: (context, state) =>
          StatusScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id/track',
      builder: (context, state) =>
          TrackingScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id/proof',
      builder: (context, state) =>
          ProofScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
