//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'checkout_in.g.dart';

/// CheckoutIn
///
/// Properties:
/// * [planSlug]
/// * [provider]
/// * [successUrl]
@BuiltValue()
abstract class CheckoutIn implements Built<CheckoutIn, CheckoutInBuilder> {
  @BuiltValueField(wireName: r'plan_slug')
  String get planSlug;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'success_url')
  String? get successUrl;

  CheckoutIn._();

  factory CheckoutIn([void updates(CheckoutInBuilder b)]) = _$CheckoutIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CheckoutInBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CheckoutIn> get serializer => _$CheckoutInSerializer();
}

class _$CheckoutInSerializer implements PrimitiveSerializer<CheckoutIn> {
  @override
  final Iterable<Type> types = const [CheckoutIn, _$CheckoutIn];

  @override
  final String wireName = r'CheckoutIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CheckoutIn object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'plan_slug';
    yield serializers.serialize(
      object.planSlug,
      specifiedType: const FullType(String),
    );
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    if (object.successUrl != null) {
      yield r'success_url';
      yield serializers.serialize(
        object.successUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CheckoutIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CheckoutInBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'plan_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.planSlug = valueDes;
          break;
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
          break;
        case r'success_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.successUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CheckoutIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CheckoutInBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


