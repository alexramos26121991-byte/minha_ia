import '../api/api_client.dart';
import '../api/generated/src/model/session_in.dart';
import 'auth_repository.dart';

/// Base da API configurável em build/run:
/// `flutter run --dart-define=API_BASE_URL=https://api.seudominio.com`
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// Instância única de autenticação usada pelo roteador e pelas telas.
final AuthRepository authRepository = AuthRepository(
  sessionSync: (idToken) async {
    final response = await ApiClient(baseUrl: apiBaseUrl).auth.createSession(
          sessionIn: SessionIn(
            (builder) => builder..consentVersion = 'lgpd-2026-11',
          ),
          headers: <String, dynamic>{'Authorization': 'Bearer $idToken'},
        );
    return response.data?.planSlug;
  },
);
