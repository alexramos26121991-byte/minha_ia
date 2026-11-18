/// Contrato de notificações push do app.
///
/// O Firebase Cloud Messaging ainda não foi provisionado (sem
/// `google-services.json` / `GoogleService-Info.plist`). Esta camada existe
/// para que as telas não dependam do plugin: a implementação real será
/// injetada aqui quando o projeto Firebase existir. Nenhuma credencial de
/// provedor ou de push vive no aplicativo.
library;

/// Evento de mudança de estado de uma geração assíncrona.
class GenerationNotification {
  const GenerationNotification({
    required this.generationId,
    required this.status,
    this.title,
    this.body,
  });

  final String generationId;
  final String status;
  final String? title;
  final String? body;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

abstract class NotificationService {
  /// Inicializa o canal de push (no-op até o Firebase ser configurado).
  Future<void> initialize();

  /// Token do dispositivo, quando houver push de verdade.
  Future<String?> getToken();

  /// Eventos de geração recebidos enquanto o app está em primeiro plano.
  Stream<GenerationNotification> get generations;

  Future<void> dispose();
}
