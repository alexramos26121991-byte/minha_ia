import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth/auth_locator.dart';
import '../../services/auth/auth_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import 'auth_message.dart';
import 'auth_scaffold.dart';
import 'auth_validators.dart';
import 'password_field.dart';

/// Tela de entrada com e-mail e senha.
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.auth, super.key});

  /// Injeta um repositório (testes). Por padrão usa a instância global.
  final AuthRepository? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  AuthRepository get _auth => widget.auth ?? authRepository;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await _auth.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (error == null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final footer = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ainda não tem conta?', style: AppTypography.body),
            TextButton(
              onPressed: () => context.go('/registrar'),
              child: const Text('Criar conta'),
            ),
          ],
        );

        return AuthScaffold(
          title: 'Bem-vindo de volta',
          subtitle: 'Entre para continuar criando com inteligência artificial.',
          footer: footer,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    label: 'E-mail',
                    hint: 'voce@exemplo.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  PasswordField(
                    controller: _password,
                    textInputAction: TextInputAction.done,
                    validator: AuthValidators.password,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/esqueci-senha'),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AuthMessage(text: _auth.errorMessage),
                  AppButton(
                    label: 'Entrar',
                    icon: Icons.login,
                    gradient: true,
                    loading: _auth.isBusy,
                    onPressed: _auth.isBusy ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
