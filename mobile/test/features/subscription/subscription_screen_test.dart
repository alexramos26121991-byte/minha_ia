import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/app.dart';
import 'package:minha_ia/routes/app_router.dart';
import 'package:minha_ia/services/auth/auth_repository.dart';
import 'package:minha_ia/services/auth/token_storage.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';
import 'package:minha_ia/widgets/app_button.dart';

import '../generation/fakes.dart';
import '../generation/pump_app.dart';

/// Viewport alto o bastante para que nenhum plano fique fora da tela.
void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpPlans(WidgetTester tester) async {
  _useLargeViewport(tester);
  mockClipboard();
  final auth = AuthRepository(storage: InMemoryTokenStorage());
  await auth.signInAsDemo();
  final generation = GenerationController(
    credits: FakeCreditSource(),
    generations: FakeGenerationSource(),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MinhaIaApp(
        router: createAppRouter(
          auth: auth,
          generation: generation,
          initialLocation: '/perfil/planos',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('não simula checkout nem pagamento', (tester) async {
    await _pumpPlans(tester);

    expect(find.text('Continuar'), findsNothing);
    expect(find.byType(AppButton), findsNothing);
    expect(find.text('Pagamentos disponíveis na próxima versão.'), findsNothing);
  });

  testWidgets('avisa que planos pagos não estão disponíveis e gratuito está ativo', (
    tester,
  ) async {
    await _pumpPlans(tester);

    expect(
      find.textContaining(
        'Planos pagos e pagamentos ainda não estão disponíveis nesta versão',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('créditos do plano gratuito já estão ativos'),
      findsOneWidget,
    );
  });

  testWidgets('catálogo permanece visível, mas preços são previstos/prévia', (
    tester,
  ) async {
    await _pumpPlans(tester);

    for (final plan in ['Gratuito', 'Básico', 'Pro', 'Premium']) {
      expect(find.text(plan), findsOneWidget);
    }
    expect(find.text('Prévia dos planos'), findsOneWidget);
    expect(find.textContaining('previsto'), findsWidgets);
    expect(find.text('R\$ 29,90'), findsNothing);
    expect(find.text('R\$ 89,90'), findsNothing);
    expect(find.text('R\$ 249,90'), findsNothing);
  });
}
