import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';
import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/services/generation/generation_sources.dart';

import '../generation/fakes.dart';

/// Saldo de 100 créditos cobre os custos de vídeo (50) e animação (20).
FakeCreditSource _richCredits() => FakeCreditSource(
      balance: const CreditBalance(balance: 100, reserved: 0, available: 100),
    );

GenerationController _controller(
  CreditSource? credits,
  GenerationSource generations,
) =>
    GenerationController(
      credits: credits ?? _richCredits(),
      generations: generations,
    );

void main() {
  test('custos de vídeo e animação vêm do backend', () async {
    final credits = _richCredits();
    final controller = _controller(credits, FakeGenerationSource());

    await controller.load();

    expect(controller.videoCost, 50);
    expect(controller.animatePhotoCost, 20);
    expect(controller.imageCost, 10);
  });

  test('gerar vídeo envia prompt, duração e resolução e enfileira o job', () async {
    final credits = _richCredits();
    final generations = FakeGenerationSource();
    final controller = _controller(credits, generations);
    await controller.load();

    final outcome = await controller.generateVideo(
      prompt: '  um dragão sobre a cidade  ',
      durationSeconds: 10,
      resolution: '1080p',
    );

    expect(outcome, GenerateOutcome.success);
    expect(generations.generateVideoCalls, 1);
    expect(generations.lastVideoPrompt, 'um dragão sobre a cidade');
    expect(generations.lastDurationSeconds, 10);
    expect(generations.lastResolution, '1080p');
    expect(controller.lastGenerated?.isVideo, isTrue);
    expect(controller.lastGenerated?.isQueued, isTrue);
    expect(controller.lastKind, GenerationKind.video);
  });

  test('vídeo com saldo menor que 50 créditos é bloqueado antes da chamada', () async {
    final credits = FakeCreditSource(
      balance: const CreditBalance(balance: 49, reserved: 0, available: 49),
    );
    final generations = FakeGenerationSource();
    final controller = _controller(credits, generations);
    await controller.load();

    final outcome = await controller.generateVideo(prompt: 'um vídeo');

    expect(outcome, GenerateOutcome.insufficientBalance);
    expect(controller.errorMessage, contains('50 créditos'));
    expect(generations.generateVideoCalls, 0);
  });

  test('animação com saldo menor que 20 créditos é bloqueada', () async {
    final credits = FakeCreditSource(
      balance: const CreditBalance(balance: 19, reserved: 0, available: 19),
    );
    final generations = FakeGenerationSource();
    final controller = _controller(credits, generations);
    await controller.load();

    final outcome = await controller.animatePhoto(
      imageUrl: 'https://example.com/foto.jpg',
    );

    expect(outcome, GenerateOutcome.insufficientBalance);
    expect(controller.errorMessage, contains('20 créditos'));
    expect(generations.animatePhotoCalls, 0);
  });

  test('503 vira erro de disponibilidade, sem marcar saldo insuficiente', () async {
    final generations = FakeGenerationSource(
      generateVideoError: const GenerationApiFailure(
        message: 'O provedor de vídeo está indisponível. Tente novamente.',
        statusCode: 503,
      ),
    );
    final controller = _controller(null, generations);
    await controller.load();

    final outcome = await controller.generateVideo(prompt: 'uma cidade');

    expect(outcome, GenerateOutcome.error);
    expect(controller.errorMessage, contains('indisponível'));
    expect(controller.insufficientBalance, isFalse);
  });

  test('402 do provedor de vídeo é traduzido como saldo insuficiente', () async {
    final generations = FakeGenerationSource(
      generateVideoError: const GenerationApiFailure(
        message: 'Créditos insuficientes.',
        statusCode: 402,
      ),
    );
    final controller = _controller(null, generations);
    await controller.load();

    final outcome = await controller.generateVideo(prompt: 'uma nave');

    expect(outcome, GenerateOutcome.insufficientBalance);
    expect(controller.insufficientBalance, isTrue);
  });

  test('upload guarda a URL do backend e repassa bytes, nome e MIME', () async {
    final generations = FakeGenerationSource(
      uploadUrl: 'https://storage.example.com/foto.png',
    );
    final controller = _controller(null, generations);
    final bytes = Uint8List.fromList(const <int>[1, 2, 3]);

    final ok = await controller.uploadImage(
      bytes,
      fileName: 'foto.png',
      mimeType: 'image/png',
    );

    expect(ok, isTrue);
    expect(controller.uploadedImageUrl, 'https://storage.example.com/foto.png');
    expect(controller.uploading, isFalse);
    expect(generations.uploadCalls, 1);
    expect(generations.lastUploadBytes, bytes);
    expect(generations.lastUploadFileName, 'foto.png');
    expect(generations.lastUploadMimeType, 'image/png');
  });

  test('falha no upload é exibida e não define uma URL', () async {
    final generations = FakeGenerationSource(
      uploadError: const GenerationApiFailure(
        message: 'Imagem inválida: use PNG, JPG ou WEBP.',
        statusCode: 400,
      ),
    );
    final controller = _controller(null, generations);

    final ok = await controller.uploadImage(
      Uint8List.fromList(const <int>[1]),
      fileName: 'foto.png',
      mimeType: 'image/png',
    );

    expect(ok, isFalse);
    expect(controller.uploadedImageUrl, isNull);
    expect(controller.errorMessage, contains('Imagem inválida'));
  });

  test('animação usa a URL enviada e o movimento escolhido', () async {
    final generations = FakeGenerationSource();
    final controller = _controller(null, generations);
    await controller.load();

    final outcome = await controller.animatePhoto(
      imageUrl: '  https://example.com/foto.jpg  ',
      motion: 'Cinematográfico',
    );

    expect(outcome, GenerateOutcome.success);
    expect(generations.animatePhotoCalls, 1);
    expect(generations.lastImageUrl, 'https://example.com/foto.jpg');
    expect(generations.lastMotion, 'Cinematográfico');
    expect(controller.lastGenerated?.type, 'animate_photo');
    expect(controller.lastKind, GenerationKind.animatePhoto);
  });

  test('URL vazia não consome créditos', () async {
    final generations = FakeGenerationSource();
    final controller = _controller(null, generations);
    await controller.load();

    final outcome = await controller.animatePhoto(imageUrl: '   ');

    expect(outcome, GenerateOutcome.error);
    expect(controller.errorMessage, 'Escolha uma imagem para animar.');
    expect(generations.animatePhotoCalls, 0);
  });

  test('polling acompanha o progresso até terminalizar e recarrega saldo', () async {
    final credits = _richCredits();
    final generations = FakeGenerationSource(
      generationResults: <GenerationItem>[
        fakeItem(
          id: 'video-1',
          isVideo: true,
          status: 'processing',
          progress: 45,
          mediaUrl: null,
        ),
        fakeItem(
          id: 'video-1',
          isVideo: true,
          status: 'completed',
          progress: 100,
          mediaUrl: 'https://storage.example.com/video-1.mp4',
        ),
      ],
    );
    final controller = _controller(credits, generations);
    await controller.load();
    final before = credits.balanceCalls;

    final item = await controller.pollGeneration(
      'video-1',
      interval: Duration.zero,
      maxAttempts: 3,
    );

    expect(generations.getGenerationCalls, 2);
    expect(generations.generationQueries, <String>['video-1', 'video-1']);
    expect(item?.isTerminal, isTrue);
    expect(item?.progress, 100);
    expect(controller.lastGenerated?.isCompleted, isTrue);
    expect(credits.balanceCalls, greaterThan(before));
  });

  test('polling para quando shouldStop retorna verdadeiro', () async {
    final generations = FakeGenerationSource();
    final controller = _controller(null, generations);
    var checks = 0;

    await controller.pollGeneration(
      'video-1',
      interval: Duration.zero,
      maxAttempts: 10,
      shouldStop: () => ++checks >= 2,
    );

    expect(generations.getGenerationCalls, 1);
  });

  test('falha pontual no polling mantém o último progresso conhecido', () async {
    final generations = FakeGenerationSource(
      getGenerationError: const GenerationApiFailure(
        message: 'Tempo limite',
        statusCode: 408,
      ),
    );
    final controller = _controller(null, generations);

    final item = await controller.pollGeneration(
      'video-1',
      interval: Duration.zero,
      maxAttempts: 3,
    );

    expect(item, isNull);
    expect(generations.getGenerationCalls, 1);
    expect(controller.errorMessage, isNull);
  });
}
