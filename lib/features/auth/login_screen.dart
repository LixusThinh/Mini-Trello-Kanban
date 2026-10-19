import 'package:flutter/material.dart';

import 'auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const AuthForm(register: false);
}
