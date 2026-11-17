import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/app.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MinhaIaApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exibe as 5 abas da navegação inferior', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Criar'), findsOneWidget);
    expect(find.text('Imagens'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('a tela inicial mostra saldo e acoes principais', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Sua imaginação,\nsem limites.'), findsOneWidget);
    expect(find.textContaining('créditos disponíveis'), findsWidgets);
    expect(find.text('Criar vídeo'), findsOneWidget);
    expect(find.text('Criar imagem'), findsOneWidget);
  });

  testWidgets('navega para Criar imagem pela aba Imagens', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Imagens'));
    await tester.pumpAndSettle();

    expect(find.text('Criar imagem'), findsWidgets);
    expect(find.text('Descreva sua imagem'), findsOneWidget);
  });

  testWidgets('navega para Planos a partir do Perfil', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assinaturas e planos'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha o plano ideal'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
  });

  testWidgets('abre Animar foto pela aba Criar', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Criar vídeo'), findsWidgets);
    await tester.ensureVisible(find.text('Animar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Animar foto'));
    await tester.pumpAndSettle();

    expect(find.text('Animar foto'), findsWidgets);
    expect(find.textContaining('Animação de fotografias'), findsOneWidget);
  });
}
