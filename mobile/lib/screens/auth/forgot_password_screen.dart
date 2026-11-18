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

/// Tela de recuperação de senha.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({this.auth, super.key});

  final AuthRepository? auth;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  String? _successMessage;

  AuthRepository get _auth => widget.auth ?? authRepository;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _successMessage = null);

    final error = await _auth.sendPasswordReset(email: _email.text);
    if (!mounted) return;
    if (error == null) {
      setState(() {
        _successMessage =
            'Se este e-mail estiver cadastrado, você receberá o link de recuperação em breve.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final footer = Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Voltar para o login'),
          ),
        );

        return AuthScaffold(
          title: 'Recuperar senha',
          subtitle: 'Informe seu e-mail para enviarmos um link de recuperação.',
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
                    textInputAction: TextInputAction.done,
                    validator: AuthValidators.email,
                  ),
                  AuthMessage(text: _auth.errorMessage),
                  if (_successMessage != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _successMessage!,
                          style: AppTypography.body.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                  AppButton(
                    label: 'Enviar link',
                    icon: Icons.mail_outline,
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
