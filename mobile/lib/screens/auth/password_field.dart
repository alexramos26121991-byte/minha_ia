import 'package:material_ui/material_ui.dart';

import 'auth_scaffold.dart';

/// Campo de senha com botão acessível para mostrar/ocultar o texto.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    this.label = 'Senha',
    this.validator,
    this.autofillHints = const <String>[AutofillHints.password],
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final List<String> autofillHints;
  final TextInputAction textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthField(
      label: widget.label,
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      suffixIcon: Semantics(
        button: true,
        label: _obscure ? 'Mostrar senha' : 'Ocultar senha',
        child: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          color: Theme.of(context).hintColor,
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
