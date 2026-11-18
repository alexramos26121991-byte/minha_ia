/// Validações compartilhadas pelos formulários de autenticação.
final class AuthValidators {
  const AuthValidators._();

  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu e-mail.';
    if (!emailPattern.hasMatch(text)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha.';
    if (value.length < 6) return 'A senha deve ter ao menos 6 caracteres.';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu nome.';
    return null;
  }

  static String? confirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirme sua senha.';
    if (value != password) return 'As senhas não coincidem.';
    return null;
  }
}
