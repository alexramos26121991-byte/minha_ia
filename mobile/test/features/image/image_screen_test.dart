import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';
import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/services/generation/generation_sources.dart';
import 'package:minha_ia/widgets/insufficient_balance_card.dart';

import '../generation/fakes.dart';
import '../generation/pump_app.dart';

GenerationController _controller({
  required FakeGenerationSource generations,
  FakeCreditSource? credits,
}) =>
    GenerationController(
      credits: credits ?? FakeCreditSource(),
      generations: generations,
    );

void main() {
  testWidgets('mostra o custo real do backend antes de confirmar', (tester) async {
    await pumpGenerationApp(
      tester,
      _controller(generations: FakeGenerationSource()),
    );

    expect(
      find.text('Custo: 10 créditos · saldo disponível: 42'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
  });

  testWidgets('gera imagem e mostra confirmação com thumbnail', (tester) async {
    final generations = FakeGenerationSource();
    await pumpGenerationApp(tester, _controller(generations: generations));

    await tester.enterText(find.byType(TextField).first, 'um gato astronauta');
    await tester.ensureVisible(find.text('Gerar imagem'));
    await tester.tap(find.text('Gerar imagem'));
    await tester.pumpAndSettle();

    expect(generations.generateCalls, 1);
    expect(find.text('Imagem criada!'), findsOneWidget);
    expect(find.text('Ver na galeria'), findsOneWidget);
  });

  testWidgets('saldo insuficiente oferece link direto para planos', (tester) async {
    final generations = FakeGenerationSource();
    final credits = FakeCreditSource(
      balance: const CreditBalance(balance: 5, reserved: 0, available: 5),
    );
    await pumpGenerationApp(
      tester,
      _controller(generations: generations, credits: credits),
    );

    await tester.enterText(find.byType(TextField).first, 'um dragão');
    await tester.ensureVisible(find.text('Gerar imagem'));
    await tester.tap(find.text('Gerar imagem'));
    await tester.pumpAndSettle();

    expect(generations.generateCalls, 0);
    expect(find.byType(InsufficientBalanceCard), findsOneWidget);
    expect(find.text('Ver planos e créditos'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver planos e créditos'));
    await tester.tap(find.text('Ver planos e créditos'));
    await tester.pumpAndSettle();
    expect(find.text('Planos'), findsOneWidget);
  });

  testWidgets('erro de indisponibilidade mostra mensagem amigável', (tester) async {
    final generations = FakeGenerationSource(
      generateError: const GenerationApiFailure(
        message:
            'A geração está temporariamente indisponível. Tente novamente em instantes.',
        statusCode: 503,
      ),
    );
    await pumpGenerationApp(tester, _controller(generations: generations));

    await tester.enterText(find.byType(TextField).first, 'uma cidade futurista');
    await tester.ensureVisible(find.text('Gerar imagem'));
    await tester.tap(find.text('Gerar imagem'));
    await tester.pumpAndSettle();

    expect(find.textContaining('temporariamente indisponível'), findsOneWidget);
    expect(find.byType(InsufficientBalanceCard), findsNothing);
  });

  testWidgets('prompt vazio não chama o backend', (tester) async {
    final generations = FakeGenerationSource();
    await pumpGenerationApp(tester, _controller(generations: generations));

    await tester.ensureVisible(find.text('Gerar imagem'));
    await tester.tap(find.text('Gerar imagem'));
    await tester.pumpAndSettle();

    expect(generations.generateCalls, 0);
    expect(find.text('Descreva o que você quer criar.'), findsOneWidget);
  });
}
