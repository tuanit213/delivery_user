import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_state.dart';
import '../../../core/state/session_store.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/pixel_auth_layout.dart';
import '../../../theme/app_colors.dart';
import '../data/auth_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController(), password = TextEditingController();
  bool obscure = true;
  bool submitting = false;
  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (submitting) return;
    if (phone.text.length != 10 || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i ph\u1ea3i \u0111\u1ee7 10 s\u1ed1 v\u00e0 m\u1eadt kh\u1ea9u t\u1ed1i thi\u1ec3u 6 k\u00fd t\u1ef1.',
          ),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final session = await authApi.login(
        username: phone.text.trim(),
        password: password.text,
      );
      appState.value = appState.value.copyWith(
        customerId: session.customerId,
        name: session.name,
        phone: session.phone,
        email: session.email,
        defaultAddress: session.defaultAddress,
      );
      await sessionStore.save(appState.value);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PixelAuthLayout(
    title: 'Chào bạn trở lại!',
    subtitle: 'Đăng nhập để gửi hàng và theo dõi đơn của bạn.',
    footer: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Lần đầu đến LogiRoute?',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        TextButton(
          onPressed: submitting ? null : () => context.go('/register'),
          child: const Text(
            'Tạo tài khoản',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputBox(
            'Số điện thoại',
            'Nhập SĐT 10 số',
            controller: phone,
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Mật khẩu',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: password,
            obscureText: obscure,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) {
              if (!submitting) login();
            },
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              suffixIcon: IconButton(
                tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                ),
                onPressed: () => setState(() => obscure = !obscure),
              ),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            submitting ? 'Đang đăng nhập…' : 'Đăng nhập',
            icon: Icons.arrow_forward_rounded,
            onTap: submitting ? null : login,
          ),
        ],
      ),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController(),
      phone = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool accepted = false;
  bool submitting = false;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (submitting) return;
    final validEmail =
        email.text.isEmpty ||
        (email.text.contains('@') && email.text.contains('.'));
    if (name.text.trim().isEmpty ||
        phone.text.length != 10 ||
        password.text.length < 6 ||
        !accepted ||
        !validEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui l\u00f2ng nh\u1eadp h\u1ecd t\u00ean, S\u0110T \u0111\u1ee7 10 s\u1ed1, email h\u1ee3p l\u1ec7 v\u00e0 \u0111\u1ed3ng \u00fd \u0111i\u1ec1u kho\u1ea3n.',
          ),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final session = await authApi.registerCustomer(
        username: phone.text.trim(),
        password: password.text,
        name: name.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim().isEmpty ? null : email.text.trim(),
      );
      appState.value = appState.value.copyWith(
        customerId: session.customerId,
        name: session.name,
        phone: session.phone,
        email: session.email,
        defaultAddress: session.defaultAddress,
      );
      await sessionStore.save(appState.value);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PixelAuthLayout(
    title: 'Bắt đầu hành trình.',
    subtitle: 'Tạo tài khoản để gửi món hàng đầu tiên của bạn.',
    registration: true,
    footer: TextButton(
      onPressed: submitting ? null : () => context.go('/login'),
      child: const Text(
        'Đã có tài khoản? Đăng nhập',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputBox(
          'Họ và tên',
          'Tên của bạn',
          controller: name,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 18),
        InputBox(
          'Số điện thoại',
          'Nhập SĐT 10 số',
          controller: phone,
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 18),
        InputBox(
          'Email (không bắt buộc)',
          'ban@email.com',
          controller: email,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline,
        ),
        const SizedBox(height: 18),
        InputBox(
          'Mật khẩu',
          'Tối thiểu 6 ký tự',
          controller: password,
          obscureText: true,
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: 36,
              child: Checkbox(
                value: accepted,
                activeColor: appRed,
                onChanged: (value) => setState(() => accepted = value ?? false),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.7,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          submitting ? 'Đang tạo tài khoản…' : 'Tạo tài khoản',
          icon: Icons.arrow_forward_rounded,
          onTap: submitting ? null : submit,
        ),
      ],
    ),
  );
}

void _showApiError(BuildContext context, Object error) {
  final message = error is FormatException
      ? error.message.toString()
      : 'Không thể kết nối máy chủ hoặc dữ liệu không hợp lệ. $error';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
