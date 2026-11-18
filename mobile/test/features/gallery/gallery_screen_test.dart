import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';
import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/widgets/generation_tile.dart';

import '../generation/fakes.dart';
import '../generation/pump_app.dart';

void main() {
  testWidgets('exibe os quatro filtros na ordem exigida', (tester) async {
    await pumpGenerationApp(
      tester,
      GenerationController(
        credits: FakeCreditSource(),
        generations: FakeGenerationSource(),
      ),
      location: '/galeria',
    );

    final filters = find.byType(ChoiceChip);
    expect(filters, findsNWidgets(4));
    expect(find.text('Vídeos'), findsOneWidget);
    expect(find.text('Imagens criadas'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Projetos'), findsOneWidget);
  });

  testWidgets('mostra thumbnail e ações de download, compartilhar e excluir',
      (tester) async {
    final item = fakeItem();
    await pumpGenerationApp(
      tester,
      GenerationController(
        credits: FakeCreditSource(),
        generations: FakeGenerationSource(items: <GenerationItem>[item]),
      ),
      location: '/galeria',
    );

    expect(find.byType(GenerationTile), findsOneWidget);
    expect(find.byTooltip('Baixar ${item.title}'), findsOneWidget);
    expect(find.byTooltip('Compartilhar ${item.title}'), findsOneWidget);
    expect(find.byTooltip('Excluir ${item.title}'), findsOneWidget);
  });

  testWidgets('alterna filtros e mostra estado vazio para downloads',
      (tester) async {
    final generations = FakeGenerationSource(
      items: <GenerationItem>[fakeItem()],
    );
    final controller = GenerationController(
      credits: FakeCreditSource(),
      generations: generations,
    );
    await pumpGenerationApp(tester, controller, location: '/galeria');

    expect(find.byType(GenerationTile), findsOneWidget);
    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    expect(controller.filter, GenerationFilter.downloads);
    expect(find.byType(GenerationTile), findsNothing);
    expect(find.text('Nada por aqui ainda'), findsOneWidget);
  });

  testWidgets('exclui a criação somente após confirmação', (tester) async {
    final item = fakeItem();
    final generations = FakeGenerationSource(
      items: <GenerationItem>[item],
    );
    await pumpGenerationApp(
      tester,
      GenerationController(
        credits: FakeCreditSource(),
        generations: generations,
      ),
      location: '/galeria',
    );

    await tester.tap(find.byTooltip('Excluir ${item.title}'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir criação?'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(generations.deletedIds, <String>['gen-1']);
    expect(find.byType(GenerationTile), findsNothing);
  });

  testWidgets('compartilhamento copia o link para a área de transferência',
      (tester) async {
    final item = fakeItem();
    await pumpGenerationApp(
      tester,
      GenerationController(
        credits: FakeCreditSource(),
        generations: FakeGenerationSource(items: <GenerationItem>[item]),
      ),
      location: '/galeria',
    );

    await tester.tap(find.byTooltip('Compartilhar ${item.title}'));
    await tester.pumpAndSettle();

    expect(find.text('Link copiado. Compartilhe onde quiser.'), findsOneWidget);
  });
}
