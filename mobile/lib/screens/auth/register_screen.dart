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

/// Tela de cadastro de nova conta.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.auth, super.key});

  final AuthRepository? auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  AuthRepository get _auth => widget.auth ?? authRepository;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await _auth.register(
      name: _name.text,
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
            Text('Já tem uma conta?', style: AppTypography.body),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Entrar'),
            ),
          ],
        );

        return AuthScaffold(
          title: 'Crie sua conta',
          subtitle: 'Comece grátis com 30 créditos para experimentar.',
          footer: footer,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthField(
                    label: 'Nome',
                    hint: 'Como quer ser chamado?',
                    controller: _name,
                    autofillHints: const <String>[AutofillHints.name],
                    validator: AuthValidators.name,
                  ),
                  AuthField(
                    label: 'E-mail',
                    hint: 'voce@exemplo.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  PasswordField(controller: _password),
                  PasswordField(
                    label: 'Confirmar senha',
                    controller: _confirmation,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[],
                    validator: (value) =>
                        AuthValidators.confirmation(value, _password.text),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AuthMessage(text: _auth.errorMessage),
                  AppButton(
                    label: 'Criar conta',
                    icon: Icons.person_add_outlined,
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
