import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minha_ia/app.dart';
import 'package:minha_ia/routes/app_router.dart';
import 'package:minha_ia/services/auth/auth_repository.dart';
import 'package:minha_ia/services/auth/token_storage.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';

import '../generation/fakes.dart';
import '../generation/pump_app.dart';

/// Viewport largo o bastante para os cards horizontais serem construídos.
void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Monta a Home no roteador real, com sessão e dados falsos (sem rede).
Future<GoRouter> _pumpHome(WidgetTester tester) async {
  _useLargeViewport(tester);
  mockClipboard();
  final auth = AuthRepository(storage: InMemoryTokenStorage());
  await auth.signInAsDemo();
  final generation = GenerationController(
    credits: FakeCreditSource(),
    generations: FakeGenerationSource(),
  );
  final router = createAppRouter(
    auth: auth,
    generation: generation,
    initialLocation: '/',
  );
  await tester.pumpWidget(
    ProviderScope(child: MinhaIaApp(router: router)),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tapModelCard(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cards da Home não dizem mais "Em breve"', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Em breve'), findsNothing);
    expect(find.text('Transforme uma foto em vídeo'), findsOneWidget);
    expect(find.text('Crie um vídeo a partir de texto'), findsOneWidget);
  });

  testWidgets('card Animar foto navega para /criar/animar-foto', (tester) async {
    final router = await _pumpHome(tester);

    await _tapModelCard(tester, 'Animar foto');

    expect(router.state.uri.path, '/criar/animar-foto');
    expect(find.byKey(const Key('animate-photo-button')), findsOneWidget);
  });

  testWidgets('card Vídeo IA navega para /criar/video', (tester) async {
    final router = await _pumpHome(tester);

    await _tapModelCard(tester, 'Vídeo IA');

    expect(router.state.uri.path, '/criar/video');
    expect(find.byKey(const Key('generate-video-button')), findsOneWidget);
  });

  testWidgets('card Imagem IA navega para /imagens', (tester) async {
    final router = await _pumpHome(tester);

    await _tapModelCard(tester, 'Imagem IA');

    expect(router.state.uri.path, '/imagens');
  });
}
