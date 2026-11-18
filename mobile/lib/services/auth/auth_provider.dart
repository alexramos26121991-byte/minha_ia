/// Provedor de credenciais de autenticação.
///
/// A implementação de produção (Firebase Auth) será plugada quando o projeto
/// Firebase e os arquivos `google-services.json` / `GoogleService-Info.plist`
/// estiverem disponíveis. Até lá, [DevAuthProvider] mantém o fluxo E2E testável
/// sem credenciais externas, gerando tokens aceitos pelo modo `auth_provider=dev`
/// do backend.
library;

/// Falha de autenticação com mensagem pronta para exibição ao usuário.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('E-mail ou senha incorretos. Tente novamente.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure()
      : super('A senha deve ter ao menos 6 caracteres.');
}

class EmailInUseFailure extends AuthFailure {
  const EmailInUseFailure()
      : super('Este e-mail já está cadastrado. Faça login para continuar.');
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('Informe um e-mail válido.');
}

/// Credencial obtida do provedor (ID token + dados básicos do perfil).
class AuthCredential {
  const AuthCredential({
    required this.idToken,
    this.email,
    this.displayName,
  });

  final String idToken;
  final String? email;
  final String? displayName;
}

/// Contrato do provedor — permite trocar Firebase por fake nos testes.
abstract class AuthProvider {
  Future<AuthCredential> signIn({
    required String email,
    required String password,
  });

  Future<AuthCredential> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});
}

/// Provedor local para desenvolvimento e testes (sem Firebase).
class DevAuthProvider implements AuthProvider {
  const DevAuthProvider();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _validateEmail(String email) {
    if (!_emailPattern.hasMatch(email.trim())) {
      throw const InvalidEmailFailure();
    }
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw const WeakPasswordFailure();
    }
  }

  String _tokenFor(String email) {
    final nonce = DateTime.now().microsecondsSinceEpoch;
    return 'dev:${email.trim().toLowerCase()}:$nonce';
  }

  @override
  Future<AuthCredential> signIn({
    required String email,
    required String password,
  }) async {
    _validateEmail(email);
    _validatePassword(password);
    return AuthCredential(
      idToken: _tokenFor(email),
      email: email.trim().toLowerCase(),
      displayName: email.trim().split('@').first,
    );
  }

  @override
  Future<AuthCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _validateEmail(email);
    _validatePassword(password);
    if (name.trim().isEmpty) {
      throw const AuthFailure('Informe seu nome.');
    }
    return AuthCredential(
      idToken: _tokenFor(email),
      email: email.trim().toLowerCase(),
      displayName: name.trim(),
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    _validateEmail(email);
    // Sem Firebase não há e-mail real; o fluxo apenas valida o endereço.
  }
}
