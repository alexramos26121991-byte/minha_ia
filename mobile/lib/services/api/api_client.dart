import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'generated/minha_ia_api.dart';

/// Fachada para o cliente Dart gerado a partir de `backend/openapi.yaml`.
///
/// A base URL é configurável em runtime (dev/homolog/prod). Chaves de
/// provedores e regras de crédito permanecem exclusivamente no backend.
class ApiClient {
  ApiClient({
    String baseUrl = 'http://localhost:8000',
    Dio? dio,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ),
        _serializers = serializers;

  final Dio _dio;
  final Serializers _serializers;

  AdminApi get admin => AdminApi(_dio, _serializers);
  AuthApi get auth => AuthApi(_dio, _serializers);
  CreditsApi get credits => CreditsApi(_dio, _serializers);
  GenerationsApi get generations => GenerationsApi(_dio, _serializers);
  PaymentsApi get payments => PaymentsApi(_dio, _serializers);
  PlansApi get plans => PlansApi(_dio, _serializers);
  SystemApi get system => SystemApi(_dio, _serializers);
  UsersApi get users => UsersApi(_dio, _serializers);
}
