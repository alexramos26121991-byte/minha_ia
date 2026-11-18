import 'package:flutter/foundation.dart';

import 'auth_provider.dart';
import 'token_storage.dart';

/// Estados da autenticação, usados pelo redirecionamento do roteador.
enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

/// Dados do usuário exibidos na interface.
class AuthUser {
  const AuthUser({
    required this.idToken,
    this.email,
    this.displayName,
    this.planSlug,
  });

  final String idToken;
  final String? email;
  final String? displayName;
  final String? planSlug;

  String get greeting => displayName?.isNotEmpty == true ? displayName! : 'Bem-vindo!';

  static AuthUser fromCredential(AuthCredential credential) => AuthUser(
        idToken: credential.idToken,
        email: credential.email,
        displayName: credential.displayName,
      );

  /// Reconstrói o usuário a partir do token persistido (sem chamada de rede).
  static AuthUser fromStoredToken(String token) {
    String? email;
    String? name;
    if (token.startsWith('dev:')) {
      final parts = token.split(':');
      if (parts.length >= 2 && parts[1].contains('@')) {
        email = parts[1];
        name = parts[1].split('@').first;
      }
    }
    return AuthUser(idToken: token, email: email, displayName: name);
  }

  AuthUser copyWith({String? planSlug}) => AuthUser(
        idToken: idToken,
        email: email,
        displayName: displayName,
        planSlug: planSlug ?? this.planSlug,
      );
}

/// Sincroniza a sessão com o backend. Recebe o ID token e retorna o plano.
typedef SessionSync = Future<String?> Function(String idToken);

/// Repositório de autenticação — fonte da verdade para o gate de rotas.
class AuthRepository extends ChangeNotifier {
  AuthRepository({
    AuthProvider? provider,
    TokenStorage? storage,
    SessionSync? sessionSync,
  })  : _provider = provider ?? const DevAuthProvider(),
        _storage = storage ?? SecureTokenStorage(),
        _sessionSync = sessionSync;

  final AuthProvider _provider;
  final TokenStorage _storage;
  final SessionSync? _sessionSync;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isBusy => _status == AuthStatus.authenticating;

  /// Restaura a sessão persistida. Deve ser chamado na inicialização.
  Future<void> restore() async {
    final token = await _storage.read();
    if (token != null && token.isNotEmpty) {
      _user = AuthUser.fromStoredToken(token);
      _status = AuthStatus.authenticated;
    } else {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// Retorna `null` em sucesso ou uma mensagem em português em caso de falha.
  Future<String?> signIn({
    required String email,
    required String password,
  }) =>
      _authenticate(() => _provider.signIn(email: email, password: password));

  /// Retorna `null` em sucesso ou uma mensagem em português em caso de falha.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _authenticate(
        () => _provider.register(name: name, email: email, password: password),
      );

  Future<String?> sendPasswordReset({required String email}) async {
    try {
      await _provider.sendPasswordReset(email: email);
      return null;
    } on AuthFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'Não foi possível enviar o e-mail agora. Tente novamente.';
    }
  }

  Future<void> signOut() async {
    await _storage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Atalho para testes e navegação sem backend (usuário já autenticado).
  Future<void> signInAsDemo({String email = 'demo@minhaia.local'}) async {
    final credential = AuthCredential(
      idToken: 'dev:$email:demo',
      email: email,
      displayName: 'Demo',
    );
    await _storage.write(credential.idToken);
    _user = AuthUser.fromCredential(credential);
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> _authenticate(
    Future<AuthCredential> Function() obtainCredential,
  ) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await obtainCredential();
      await _storage.write(credential.idToken);
      var user = AuthUser.fromCredential(credential);

      if (_sessionSync != null) {
        try {
          final planSlug = await _sessionSync(credential.idToken);
          if (planSlug != null) user = user.copyWith(planSlug: planSlug);
        } catch (_) {
          // Backend indisponível não impede o uso local do app em desenvolvimento.
        }
      }

      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return null;
    } on AuthFailure catch (failure) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = failure.message;
      notifyListeners();
      return failure.message;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Não foi possível entrar agora. Tente novamente.';
      notifyListeners();
      return _errorMessage;
    }
  }
}
