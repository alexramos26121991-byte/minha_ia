//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:minha_ia/services/api/generated/src/date_serializer.dart';
import 'package:minha_ia/services/api/generated/src/model/date.dart';

import 'package:minha_ia/services/api/generated/src/model/animate_photo_in.dart';
import 'package:minha_ia/services/api/generated/src/model/balance_out.dart';
import 'package:minha_ia/services/api/generated/src/model/checkout_in.dart';
import 'package:minha_ia/services/api/generated/src/model/checkout_out.dart';
import 'package:minha_ia/services/api/generated/src/model/cost_config_out.dart';
import 'package:minha_ia/services/api/generated/src/model/credit_adjustment_in.dart';
import 'package:minha_ia/services/api/generated/src/model/generation_out.dart';
import 'package:minha_ia/services/api/generated/src/model/http_validation_error.dart';
import 'package:minha_ia/services/api/generated/src/model/health_out.dart';
import 'package:minha_ia/services/api/generated/src/model/image_generation_in.dart';
import 'package:minha_ia/services/api/generated/src/model/ledger_entry_out.dart';
import 'package:minha_ia/services/api/generated/src/model/location_inner.dart';
import 'package:minha_ia/services/api/generated/src/model/payment_out.dart';
import 'package:minha_ia/services/api/generated/src/model/plan_out.dart';
import 'package:minha_ia/services/api/generated/src/model/session_in.dart';
import 'package:minha_ia/services/api/generated/src/model/session_out.dart';
import 'package:minha_ia/services/api/generated/src/model/user_out.dart';
import 'package:minha_ia/services/api/generated/src/model/user_update_in.dart';
import 'package:minha_ia/services/api/generated/src/model/validation_error.dart';
import 'package:minha_ia/services/api/generated/src/model/video_generation_in.dart';

part 'serializers.g.dart';

@SerializersFor([
  AnimatePhotoIn,
  BalanceOut,
  CheckoutIn,
  CheckoutOut,
  CostConfigOut,
  CreditAdjustmentIn,
  GenerationOut,
  HTTPValidationError,
  HealthOut,
  ImageGenerationIn,
  LedgerEntryOut,
  LocationInner,
  PaymentOut,
  PlanOut,
  SessionIn,
  SessionOut,
  UserOut,
  UserUpdateIn,
  ValidationError,
  VideoGenerationIn,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PaymentOut)]),
        () => ListBuilder<PaymentOut>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltMap, [FullType(String), FullType(String)]),
        () => MapBuilder<String, String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(LocationInner)]),
        () => ListBuilder<LocationInner>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(CostConfigOut)]),
        () => ListBuilder<CostConfigOut>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(ValidationError)]),
        () => ListBuilder<ValidationError>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PlanOut)]),
        () => ListBuilder<PlanOut>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(UserOut)]),
        () => ListBuilder<UserOut>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(GenerationOut)]),
        () => ListBuilder<GenerationOut>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(LedgerEntryOut)]),
        () => ListBuilder<LedgerEntryOut>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
