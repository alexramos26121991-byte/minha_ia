/// Modelos de domínio do fluxo de geração.
///
/// São deliberadamente independentes dos DTOs gerados: a UI e os testes não
/// precisam conhecer `built_value` nem o contrato HTTP.
library;

import '../../l10n/pt_br.dart';

/// Tipo de criação iniciada pelo usuário (usado para mensagens e custos).
enum GenerationKind { image, video, animatePhoto }

extension GenerationKindLabel on GenerationKind {
  String get label => switch (this) {
        GenerationKind.image => 'imagem',
        GenerationKind.video => 'vídeo',
        GenerationKind.animatePhoto => 'animação',
      };
}

/// Filtros exibidos na galeria, na ordem exata pedida pelo produto.
enum GenerationFilter { videos, images, downloads, projects }

extension GenerationFilterLabel on GenerationFilter {
  String get label => switch (this) {
        GenerationFilter.videos => 'Vídeos',
        GenerationFilter.images => 'Imagens criadas',
        GenerationFilter.downloads => 'Downloads',
        GenerationFilter.projects => 'Projetos',
      };

  /// Imagens, vídeos e animações existem no backend a partir da E5.
  bool get hasBackendData => switch (this) {
        GenerationFilter.videos || GenerationFilter.images => true,
        GenerationFilter.downloads || GenerationFilter.projects => false,
      };

  String? get backendType => switch (this) {
        GenerationFilter.videos => 'video',
        GenerationFilter.images => 'image',
        GenerationFilter.downloads || GenerationFilter.projects => null,
      };
}

/// Saldo informado pelo backend (`available = balance - reserved`).
class CreditBalance {
  const CreditBalance({
    required this.balance,
    required this.reserved,
    required this.available,
  });

  final int balance;
  final int reserved;
  final int available;
}

/// Preço de uma operação, lido de `GET /credits/costs`.
class GenerationCost {
  const GenerationCost({
    required this.operation,
    required this.credits,
    required this.enabled,
  });

  final String operation;
  final int credits;
  final bool enabled;
}

/// Uma geração concluída ou falha, pronta para exibição.
class GenerationItem {
  const GenerationItem({
    required this.id,
    required this.type,
    required this.status,
    required this.costCredits,
    required this.createdAt,
    this.prompt,
    this.mediaUrl,
    this.errorMessage,
    this.progress = 0,
  });

  final String id;
  final String type;
  final String status;
  final int costCredits;
  final DateTime createdAt;
  final String? prompt;
  final String? mediaUrl;
  final String? errorMessage;

  /// 0..100, informado pelo backend para jobs assíncronos (E5).
  final int progress;

  bool get isVideo => type == 'video' || type == 'animate_photo';
  bool get isFailed => status == 'failed';
  bool get isCompleted => status == 'completed';
  bool get isTerminal => isCompleted || isFailed;
  bool get isQueued => status == 'pending' || status == 'queued';
  bool get isProcessing => status == 'processing' || isQueued;

  String get progressLabel {
    if (isCompleted) return 'Concluído';
    if (isFailed) return 'Falhou';
    if (isQueued) return 'Na fila';
    return 'Processando · $progress%';
  }

  String get title {
    final text = (prompt ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return isVideo ? 'Vídeo gerado' : 'Imagem gerada';
    final words = text.split(' ').take(4).join(' ');
    return words.length < text.length ? '$words…' : words;
  }

  String get createdLabel => formatarRelativo(createdAt);

  /// Data completa em pt-BR, útil para dicas e leitores de tela.
  String get createdFullLabel => formatarDataHora(createdAt);

  String get subtitle => '$createdLabel · $costCredits créditos';
}
