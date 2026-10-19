import 'package:flutter/material.dart';

import 'auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => const AuthForm(register: true);
}
