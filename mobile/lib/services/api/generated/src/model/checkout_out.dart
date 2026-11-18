//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'checkout_out.g.dart';

/// CheckoutOut
///
/// Properties:
/// * [checkoutId]
/// * [provider]
/// * [checkoutUrl]
/// * [expiresAt]
@BuiltValue()
abstract class CheckoutOut implements Built<CheckoutOut, CheckoutOutBuilder> {
  @BuiltValueField(wireName: r'checkout_id')
  String get checkoutId;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'checkout_url')
  String get checkoutUrl;

  @BuiltValueField(wireName: r'expires_at')
  DateTime? get expiresAt;

  CheckoutOut._();

  factory CheckoutOut([void updates(CheckoutOutBuilder b)]) = _$CheckoutOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CheckoutOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CheckoutOut> get serializer => _$CheckoutOutSerializer();
}

class _$CheckoutOutSerializer implements PrimitiveSerializer<CheckoutOut> {
  @override
  final Iterable<Type> types = const [CheckoutOut, _$CheckoutOut];

  @override
  final String wireName = r'CheckoutOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CheckoutOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'checkout_id';
    yield serializers.serialize(
      object.checkoutId,
      specifiedType: const FullType(String),
    );
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    yield r'checkout_url';
    yield serializers.serialize(
      object.checkoutUrl,
      specifiedType: const FullType(String),
    );
    if (object.expiresAt != null) {
      yield r'expires_at';
      yield serializers.serialize(
        object.expiresAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CheckoutOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CheckoutOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'checkout_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.checkoutId = valueDes;
          break;
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
          break;
        case r'checkout_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.checkoutUrl = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.expiresAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CheckoutOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CheckoutOutBuilder();
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


