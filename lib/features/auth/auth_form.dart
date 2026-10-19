import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../widgets/auth_frame.dart';
import '../../widgets/ui_helpers.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.register});
  final bool register;
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      if (widget.register) {
        await authRepo.signUp(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
        if (mounted && authRepo.currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng kiểm tra email để xác nhận tài khoản.'),
            ),
          );
        }
      } else {
        await authRepo.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _password.text.length < 6
        ? 1
        : (_password.text.length >= 10 &&
                  RegExp(r'[0-9]').hasMatch(_password.text) &&
                  RegExp(r'[A-Za-z]').hasMatch(_password.text)
              ? 3
              : 2);
    final scheme = Theme.of(context).colorScheme;
    return AuthFrame(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.register ? 'Bắt đầu miễn phí' : 'Chào mừng trở lại',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (widget.register) ...[
              TextFormField(
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập họ và tên'
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (value) =>
                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                      .hasMatch(value?.trim() ?? '')
                  ? 'Vui lòng nhập email hợp lệ'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: _hidden,
              textInputAction: TextInputAction.done,
              autofillHints: [
                widget.register
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 6
                  ? 'Mật khẩu phải có ít nhất 6 ký tự'
                  : null,
            ),
            if (widget.register) ...[
              const SizedBox(height: 12),
              Semantics(
                label:
                    'Độ mạnh mật khẩu: ${['Yếu', 'Vừa', 'Mạnh'][strength - 1]}',
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _password.text.isNotEmpty && i < strength
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _password.text.isEmpty
                    ? 'Dùng ít nhất 6 ký tự'
                    : [
                        'Mật khẩu yếu',
                        'Mật khẩu vừa',
                        'Mật khẩu mạnh',
                      ][strength - 1],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            SubmitButton(
              label: widget.register ? 'Tạo tài khoản' : 'Đăng nhập',
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  widget.register
                      ? 'Đã có tài khoản?'
                      : 'Lần đầu dùng Mini Trello?',
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.go(
                          widget.register ? Routes.login : Routes.register,
                        ),
                  child: Text(widget.register ? 'Đăng nhập' : 'Tạo tài khoản'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
