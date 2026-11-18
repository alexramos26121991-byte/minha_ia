//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_out.g.dart';

/// PaymentOut
///
/// Properties:
/// * [id] 
/// * [provider] 
/// * [externalId] 
/// * [amountBrl] 
/// * [status] 
/// * [createdAt] 
@BuiltValue()
abstract class PaymentOut implements Built<PaymentOut, PaymentOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'external_id')
  String get externalId;

  @BuiltValueField(wireName: r'amount_brl')
  num get amountBrl;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  PaymentOut._();

  factory PaymentOut([void updates(PaymentOutBuilder b)]) = _$PaymentOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaymentOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaymentOut> get serializer => _$PaymentOutSerializer();
}

class _$PaymentOutSerializer implements PrimitiveSerializer<PaymentOut> {
  @override
  final Iterable<Type> types = const [PaymentOut, _$PaymentOut];

  @override
  final String wireName = r'PaymentOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaymentOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    yield r'external_id';
    yield serializers.serialize(
      object.externalId,
      specifiedType: const FullType(String),
    );
    yield r'amount_brl';
    yield serializers.serialize(
      object.amountBrl,
      specifiedType: const FullType(num),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PaymentOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaymentOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
          break;
        case r'external_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.externalId = valueDes;
          break;
        case r'amount_brl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amountBrl = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PaymentOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaymentOutBuilder();
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


