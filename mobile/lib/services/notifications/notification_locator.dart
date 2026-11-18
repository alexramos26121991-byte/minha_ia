import 'dart:async';

import 'notification_service.dart';

/// Implementação padrão: não faz nada até o Firebase ser provisionado.
///
/// Substituir por uma implementação FCM em `main.dart` quando o projeto
/// Firebase e os arquivos de configuração estiverem disponíveis.
class NoopNotificationService implements NotificationService {
  final StreamController<GenerationNotification> _controller =
      StreamController<GenerationNotification>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<GenerationNotification> get generations => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

/// Instância única usada pelo app.
final NotificationService notificationService = NoopNotificationService();
