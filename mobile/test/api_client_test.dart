import 'package:built_value/serializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/api/api_client.dart';
import 'package:minha_ia/services/api/generated/minha_ia_api.dart';

void main() {
  test('ApiClient expõe todas as APIs contratadas no OpenAPI', () {
    final client = ApiClient(baseUrl: 'http://localhost:8000');

    expect(client.system, isA<SystemApi>());
    expect(client.auth, isA<AuthApi>());
    expect(client.users, isA<UsersApi>());
    expect(client.plans, isA<PlansApi>());
    expect(client.credits, isA<CreditsApi>());
    expect(client.generations, isA<GenerationsApi>());
    expect(client.payments, isA<PaymentsApi>());
    expect(client.admin, isA<AdminApi>());
  });

  test('serializers gerados desserializam PlanOut do contrato', () {
    final plan = standardSerializers.deserialize(
      <String, Object?>{
        'id': '11111111-1111-4111-8111-111111111111',
        'slug': 'gratuito',
        'name': 'Gratuito',
        'monthly_credits': 30,
        'price_brl': 0.0,
        'recurrence': 'monthly',
        'is_active': true,
      },
      specifiedType: const FullType(PlanOut),
    ) as PlanOut;

    expect(plan.slug, 'gratuito');
    expect(plan.monthlyCredits, 30);
    expect(plan.priceBrl, 0.0);
    expect(plan.isActive, isTrue);
  });
}
