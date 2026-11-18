//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'credit_adjustment_in.g.dart';

/// CreditAdjustmentIn
///
/// Properties:
/// * [userId] 
/// * [amount] - Positivo credita; negativo debita.
/// * [reason] 
@BuiltValue()
abstract class CreditAdjustmentIn implements Built<CreditAdjustmentIn, CreditAdjustmentInBuilder> {
  @BuiltValueField(wireName: r'user_id')
  String get userId;

  /// Positivo credita; negativo debita.
  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'reason')
  String get reason;

  CreditAdjustmentIn._();

  factory CreditAdjustmentIn([void updates(CreditAdjustmentInBuilder b)]) = _$CreditAdjustmentIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreditAdjustmentInBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreditAdjustmentIn> get serializer => _$CreditAdjustmentInSerializer();
}

class _$CreditAdjustmentInSerializer implements PrimitiveSerializer<CreditAdjustmentIn> {
  @override
  final Iterable<Type> types = const [CreditAdjustmentIn, _$CreditAdjustmentIn];

  @override
  final String wireName = r'CreditAdjustmentIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreditAdjustmentIn object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(int),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreditAdjustmentIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreditAdjustmentInBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amount = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreditAdjustmentIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreditAdjustmentInBuilder();
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


