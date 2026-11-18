import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/app.dart';
import 'package:minha_ia/routes/app_router.dart';
import 'package:minha_ia/services/auth/auth_repository.dart';
import 'package:minha_ia/services/auth/token_storage.dart';

Future<void> _pump(
  WidgetTester tester,
  AuthRepository repo, {
  String initialLocation = '/',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MinhaIaApp(
        router: createAppRouter(auth: repo, initialLocation: initialLocation),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login exibe campos, recuperação e link de cadastro', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await _pump(tester, repo);

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(repo.isAuthenticated, isFalse);
  });

  testWidgets('login com credenciais válidas abre o início', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await _pump(tester, repo);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'ana@example.com');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repo.isAuthenticated, isTrue);
    expect(repo.user?.email, 'ana@example.com');
    expect(find.text('Sua imaginação,\nsem limites.'), findsOneWidget);
  });

  testWidgets('login recusa e-mail inválido sem autenticar', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'invalido');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(repo.isAuthenticated, isFalse);
  });

  testWidgets('cadastro exige nome e confirmação de senha', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await _pump(tester, repo, initialLocation: '/registrar');

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(1), 'bia@example.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '123456');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(repo.isAuthenticated, isFalse);
  });

  testWidgets('cadastro com dados válidos cria a sessão', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await _pump(tester, repo, initialLocation: '/registrar');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bia');
    await tester.enterText(fields.at(1), 'bia@example.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '123456');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(repo.isAuthenticated, isTrue);
    expect(repo.user?.displayName, 'Bia');
    expect(find.text('Sua imaginação,\nsem limites.'), findsOneWidget);
  });

  testWidgets('recuperação de senha confirma o envio', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await _pump(tester, repo, initialLocation: '/esqueci-senha');

    await tester.enterText(find.byType(TextFormField), 'ana@example.com');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('você receberá o link de recuperação'),
      findsOneWidget,
    );
    expect(repo.isAuthenticated, isFalse);
  });

  testWidgets('token persistido é restaurado na inicialização', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('dev:ana@example.com:persistido');
    final repo = AuthRepository(storage: storage);
    await repo.restore();
    expect(repo.isAuthenticated, isTrue);

    await _pump(tester, repo);
    expect(find.text('Sua imaginação,\nsem limites.'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('sair encerra a sessão e retorna ao login', (tester) async {
    final repo = AuthRepository(storage: InMemoryTokenStorage());
    await repo.signInAsDemo();
    await _pump(tester, repo);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sair'), 100);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(repo.isAuthenticated, isFalse);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
