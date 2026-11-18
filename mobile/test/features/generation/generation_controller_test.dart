import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/generation/generation_controller.dart';
import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/services/generation/generation_sources.dart';

import 'fakes.dart';

void main() {
  test('carrega saldo e custos reais do backend antes de gerar', () async {
    final credits = FakeCreditSource();
    final generations = FakeGenerationSource();
    final controller = GenerationController(
      credits: credits,
      generations: generations,
    );

    await controller.load();

    expect(controller.loadState, GenerationLoadState.ready);
    expect(controller.availableCredits, 42);
    expect(controller.imageCost, 10);
    expect(credits.balanceCalls, 1);
    expect(credits.costsCalls, 1);
  });

  test('geração com sucesso atualiza saldo e galeria', () async {
    final credits = FakeCreditSource();
    final generations = FakeGenerationSource();
    final controller = GenerationController(
      credits: credits,
      generations: generations,
    );
    await controller.load();

    final outcome = await controller.generateImage(prompt: 'um gato astronauta');

    expect(outcome, GenerateOutcome.success);
    expect(controller.lastGenerated?.prompt, 'um gato astronauta');
    expect(controller.generateState, GenerateState.success);
    expect(generations.generateCalls, 1);
    expect(controller.items, hasLength(1));
  });

  test('erro de disponibilidade é informado sem tentar novamente', () async {
    final generations = FakeGenerationSource(
      generateError: const GenerationApiFailure(
        message: 'A geração está temporariamente indisponível. Tente novamente em instantes.',
        statusCode: 503,
      ),
    );
    final controller = GenerationController(
      credits: FakeCreditSource(),
      generations: generations,
    );
    await controller.load();

    final outcome = await controller.generateImage(prompt: 'uma cidade futurista');

    expect(outcome, GenerateOutcome.error);
    expect(controller.errorMessage, contains('temporariamente indisponível'));
    expect(controller.insufficientBalance, isFalse);
    expect(controller.items, isEmpty);
  });

  test('saldo menor que o custo do backend bloqueia a geração', () async {
    final credits = FakeCreditSource(
      balance: const CreditBalance(balance: 5, reserved: 0, available: 5),
    );
    final generations = FakeGenerationSource();
    final controller = GenerationController(
      credits: credits,
      generations: generations,
    );
    await controller.load();

    final outcome = await controller.generateImage(prompt: 'um dragão');

    expect(outcome, GenerateOutcome.insufficientBalance);
    expect(controller.errorMessage, contains('10 créditos'));
    expect(controller.insufficientBalance, isTrue);
    expect(generations.generateCalls, 0);
  });

  test('402 do backend é traduzido como saldo insuficiente', () async {
    final generations = FakeGenerationSource(
      generateError: const GenerationApiFailure(
        message: 'Seus créditos acabaram. Escolha um plano para continuar criando.',
        statusCode: 402,
      ),
    );
    final controller = GenerationController(
      credits: FakeCreditSource(),
      generations: generations,
    );
    await controller.load();

    final outcome = await controller.generateImage(prompt: 'uma nave');

    expect(outcome, GenerateOutcome.insufficientBalance);
    expect(controller.insufficientBalance, isTrue);
  });

  test('filtros da galeria consultam o tipo correto no backend', () async {
    final generations = FakeGenerationSource(
      items: <GenerationItem>[fakeItem(), fakeItem(id: 'gen-2', isVideo: true)],
    );
    final controller = GenerationController(
      credits: FakeCreditSource(),
      generations: generations,
    );
    await controller.load();

    expect(controller.items, hasLength(1));
    expect(generations.lastFilter, GenerationFilter.images);

    await controller.setFilter(GenerationFilter.videos);
    expect(controller.items, hasLength(1));
    expect(controller.items.single.isVideo, isTrue);

    await controller.setFilter(GenerationFilter.downloads);
    expect(controller.filter, GenerationFilter.downloads);
    expect(controller.items, isEmpty);
    // Downloads não tem dados no backend da E4: a troca não faz nova chamada.
    expect(generations.listCalls, 2);
    expect(generations.lastFilter, GenerationFilter.videos);
  });

  test('exclusão remove o item sem estornar crédito', () async {
    final credits = FakeCreditSource();
    final generations = FakeGenerationSource(items: <GenerationItem>[fakeItem()]);
    final controller = GenerationController(
      credits: credits,
      generations: generations,
    );
    await controller.load();

    final deleted = await controller.delete('gen-1');

    expect(deleted, isTrue);
    expect(generations.deletedIds, <String>['gen-1']);
    expect(controller.items, isEmpty);
    expect(credits.balanceCalls, 1);
  });

  test('prompt vazio não consome crédito nem chama o backend', () async {
    final generations = FakeGenerationSource();
    final controller = GenerationController(
      credits: FakeCreditSource(),
      generations: generations,
    );
    await controller.load();

    final outcome = await controller.generateImage(prompt: '   ');

    expect(outcome, GenerateOutcome.error);
    expect(controller.errorMessage, 'Descreva o que você quer criar.');
    expect(generations.generateCalls, 0);
  });
}
