//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'balance_out.g.dart';

/// BalanceOut
///
/// Properties:
/// * [userId] 
/// * [balance] 
/// * [reserved] 
/// * [available] 
@BuiltValue()
abstract class BalanceOut implements Built<BalanceOut, BalanceOutBuilder> {
  @BuiltValueField(wireName: r'user_id')
  String get userId;

  @BuiltValueField(wireName: r'balance')
  int get balance;

  @BuiltValueField(wireName: r'reserved')
  int? get reserved;

  @BuiltValueField(wireName: r'available')
  int get available;

  BalanceOut._();

  factory BalanceOut([void updates(BalanceOutBuilder b)]) = _$BalanceOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BalanceOutBuilder b) => b
      ..reserved = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<BalanceOut> get serializer => _$BalanceOutSerializer();
}

class _$BalanceOutSerializer implements PrimitiveSerializer<BalanceOut> {
  @override
  final Iterable<Type> types = const [BalanceOut, _$BalanceOut];

  @override
  final String wireName = r'BalanceOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BalanceOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'balance';
    yield serializers.serialize(
      object.balance,
      specifiedType: const FullType(int),
    );
    if (object.reserved != null) {
      yield r'reserved';
      yield serializers.serialize(
        object.reserved,
        specifiedType: const FullType(int),
      );
    }
    yield r'available';
    yield serializers.serialize(
      object.available,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BalanceOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BalanceOutBuilder result,
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
        case r'balance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.balance = valueDes;
          break;
        case r'reserved':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.reserved = valueDes;
          break;
        case r'available':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.available = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BalanceOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BalanceOutBuilder();
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


