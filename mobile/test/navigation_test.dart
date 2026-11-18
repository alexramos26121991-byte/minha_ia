import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/app.dart';
import 'package:minha_ia/routes/app_router.dart';
import 'package:minha_ia/services/auth/auth_repository.dart';
import 'package:minha_ia/services/auth/token_storage.dart';

/// Cria um repositório autenticado sem depender de canais nativos ou rede.
Future<AuthRepository> _signedInRepo() async {
  final repo = AuthRepository(storage: InMemoryTokenStorage());
  await repo.signInAsDemo();
  return repo;
}

Future<void> _pumpApp(WidgetTester tester, AuthRepository auth) async {
  await tester.pumpWidget(
    ProviderScope(child: MinhaIaApp(router: createAppRouter(auth: auth))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exibe as 5 abas da navegação inferior', (tester) async {
    await _pumpApp(tester, await _signedInRepo());

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
    expect(find.text('Imagens'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('a tela inicial mostra saldo e acoes principais', (tester) async {
    await _pumpApp(tester, await _signedInRepo());

    expect(find.text('Sua imaginação,\nsem limites.'), findsOneWidget);
    expect(find.textContaining('créditos disponíveis'), findsWidgets);
    expect(find.text('Criar vídeo'), findsOneWidget);
    expect(find.text('Criar imagem'), findsOneWidget);
  });

  testWidgets('rota protegida redireciona para login quando sem sessão', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await tester.pumpWidget(
      ProviderScope(
        child: MinhaIaApp(
          router: createAppRouter(auth: repo, initialLocation: '/galeria'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Galeria'), findsNothing);
  });
}
