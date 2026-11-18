import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minha_ia/screens/video/animate_photo_screen.dart';
import 'package:minha_ia/screens/video/video_screen.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';
import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/services/generation/generation_sources.dart';

import '../generation/fakes.dart';
import 'fakes.dart';

/// Tela alta o suficiente para que nenhum botão fique fora da viewport.
void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget screen) => MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (context, state) => screen),
          GoRoute(
            path: '/galeria',
            builder: (context, state) =>
                const Scaffold(body: Text('Galeria de testes')),
          ),
        ],
      ),
    );

Future<GenerationController> _readyController(
  GenerationSource generations, {
  CreditSource? credits,
}) async {
  final controller = GenerationController(
    credits: credits ??
        FakeCreditSource(
          balance: const CreditBalance(balance: 100, reserved: 0, available: 100),
        ),
    generations: generations,
  );
  await controller.load();
  return controller;
}

void main() {
  group('VideoScreen', () {
    testWidgets('mostra custo real, saldo e opções de duração/resolução', (
      tester,
    ) async {
      _useLargeViewport(tester);
      final controller = await _readyController(FakeGenerationSource());

      await tester.pumpWidget(_wrap(VideoScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Custo: 50 créditos'), findsOneWidget);
      expect(find.text('5 s'), findsOneWidget);
      expect(find.text('10 s'), findsOneWidget);
      expect(find.text('720p'), findsOneWidget);
      expect(find.byKey(const Key('generate-video-button')), findsOneWidget);
    });

    testWidgets('job na fila exibe progresso e ação de atualizar', (tester) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        generateVideoResult: fakeItem(
          id: 'video-1',
          isVideo: true,
          status: 'queued',
          progress: 0,
          mediaUrl: null,
        ),
      );
      final controller = await _readyController(generations);
      await controller.generateVideo(prompt: 'um dragão');

      await tester.pumpWidget(_wrap(VideoScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Seu vídeo está sendo criado'), findsOneWidget);
      expect(find.text('Na fila'), findsOneWidget);
      expect(find.text('Atualizar status'), findsOneWidget);
    });

    testWidgets('503 aparece como mensagem de erro sem card de saldo', (
      tester,
    ) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        generateVideoError: const GenerationApiFailure(
          message: 'O provedor de vídeo está indisponível. Tente novamente.',
          statusCode: 503,
        ),
      );
      final controller = await _readyController(generations);
      await controller.generateVideo(prompt: 'uma cidade');

      await tester.pumpWidget(_wrap(VideoScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.text('O provedor de vídeo está indisponível. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.textContaining('Saldo insuficiente'), findsNothing);
    });

    testWidgets('saldo insuficiente aparece com atalho para planos', (tester) async {
      _useLargeViewport(tester);
      final credits = FakeCreditSource(
        balance: const CreditBalance(balance: 5, reserved: 0, available: 5),
      );
      final controller = await _readyController(
        FakeGenerationSource(),
        credits: credits,
      );
      await controller.generateVideo(prompt: 'uma nave');

      await tester.pumpWidget(_wrap(VideoScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Saldo insuficiente: esta criação custa 50 créditos.'),
        findsOneWidget,
      );
    });

    testWidgets('envia duração e resolução escolhidas ao backend', (tester) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        generateVideoResult: fakeItem(
          id: 'video-1',
          isVideo: true,
          status: 'completed',
          mediaUrl: 'https://storage.example.com/video-1.mp4',
        ),
      );
      final controller = await _readyController(generations);

      await tester.pumpWidget(_wrap(VideoScreen(controller: controller)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'um dragão futurista');
      await tester.tap(find.text('10 s'));
      await tester.tap(find.text('1080p'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('generate-video-button')));
      await tester.pumpAndSettle();

      expect(generations.generateVideoCalls, 1);
      expect(generations.lastDurationSeconds, 10);
      expect(generations.lastResolution, '1080p');
      expect(find.text('Pronto!'), findsOneWidget);
    });

    testWidgets('vídeo concluído pode ser baixado como .mp4', (tester) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        generateVideoResult: fakeItem(
          id: 'video-1',
          isVideo: true,
          status: 'completed',
          mediaUrl: 'https://storage.example.com/video-1',
        ),
      );
      final downloader = FakeGenerationDownloader(
        '/dispositivo/videos/video-1.mp4',
      );
      final controller = await _readyController(generations);
      await controller.generateVideo(prompt: 'um dragão');

      await tester.pumpWidget(
        _wrap(VideoScreen(controller: controller, downloader: downloader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Baixar'));
      for (var i = 0;
          i < 8 && find.textContaining('Vídeo salvo em:').evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(downloader.downloaded?.id, 'video-1');
      expect(
        find.text('Vídeo salvo em: /dispositivo/videos/video-1.mp4'),
        findsOneWidget,
      );
    });
  });

  group('AnimatePhotoScreen', () {
    testWidgets('mostra custo de 20 créditos e botão de galeria', (tester) async {
      _useLargeViewport(tester);
      final controller = await _readyController(FakeGenerationSource());
      final picker = FakeImagePicker(picked: fakePickedImage());

      await tester.pumpWidget(
        _wrap(
          AnimatePhotoScreen(controller: controller, imagePicker: picker),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Custo: 20 créditos'), findsOneWidget);
      expect(find.text('Suave'), findsOneWidget);
      expect(find.text('Toque para escolher da galeria'), findsOneWidget);
    });

    testWidgets('selecionar foto faz upload e preenche a URL', (tester) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        uploadUrl: 'https://storage.example.com/foto.png',
      );
      final controller = await _readyController(generations);
      final picker = FakeImagePicker(picked: fakePickedImage());

      await tester.pumpWidget(
        _wrap(
          AnimatePhotoScreen(controller: controller, imagePicker: picker),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-image')));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(generations.uploadCalls, 1);
      expect(generations.lastUploadMimeType, 'image/png');
      expect(find.text('Imagem: foto.png'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'https://storage.example.com/foto.png',
      );
    });

    testWidgets('URL alternativa e movimento são enviados ao backend', (
      tester,
    ) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        animatePhotoResult: fakeItem(
          id: 'animate-1',
          type: 'animate_photo',
          isVideo: true,
          status: 'completed',
          mediaUrl: 'https://storage.example.com/animate-1.mp4',
        ),
      );
      final controller = await _readyController(generations);

      await tester.pumpWidget(
        _wrap(AnimatePhotoScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'https://example.com/minha-foto.jpg',
      );
      await tester.tap(find.text('Cinematográfico'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('animate-photo-button')));
      await tester.pumpAndSettle();

      expect(generations.animatePhotoCalls, 1);
      expect(generations.lastImageUrl, 'https://example.com/minha-foto.jpg');
      expect(generations.lastMotion, 'Cinematográfico');
      expect(find.text('Pronto!'), findsOneWidget);
    });

    testWidgets('animação na fila exibe progresso', (tester) async {
      _useLargeViewport(tester);
      final generations = FakeGenerationSource(
        animatePhotoResult: fakeItem(
          id: 'animate-1',
          type: 'animate_photo',
          isVideo: true,
          status: 'processing',
          progress: 30,
          mediaUrl: null,
        ),
      );
      final controller = await _readyController(generations);
      await controller.animatePhoto(imageUrl: 'https://example.com/foto.jpg');

      await tester.pumpWidget(
        _wrap(AnimatePhotoScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seu vídeo está sendo criado'), findsOneWidget);
      expect(find.text('Processando · 30%'), findsOneWidget);
    });

    testWidgets('saldo insuficiente aparece na animação', (tester) async {
      _useLargeViewport(tester);
      final credits = FakeCreditSource(
        balance: const CreditBalance(balance: 10, reserved: 0, available: 10),
      );
      final controller = await _readyController(
        FakeGenerationSource(),
        credits: credits,
      );
      await controller.animatePhoto(imageUrl: 'https://example.com/foto.jpg');

      await tester.pumpWidget(
        _wrap(AnimatePhotoScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Saldo insuficiente: esta criação custa 20 créditos.'),
        findsOneWidget,
      );
    });
  });
}
