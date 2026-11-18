import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/app.dart';
import 'package:minha_ia/routes/app_router.dart';
import 'package:minha_ia/services/auth/auth_repository.dart';
import 'package:minha_ia/services/auth/token_storage.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';

/// Responde às chamadas da área de transferência: sem isso, `Clipboard.setData`
/// fica pendurado no canal da plataforma durante os testes.
void mockClipboard() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
}

/// Monta o app autenticado com um controlador de geração injetado.
Future<void> pumpGenerationApp(
  WidgetTester tester,
  GenerationController controller, {
  String location = '/imagens',
}) async {
  mockClipboard();
  final auth = AuthRepository(storage: InMemoryTokenStorage());
  await auth.signInAsDemo();
  await tester.pumpWidget(
    ProviderScope(
      child: MinhaIaApp(
        router: createAppRouter(
          auth: auth,
          generation: controller,
          initialLocation: location,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
