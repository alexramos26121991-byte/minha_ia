//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ledger_entry_out.g.dart';

/// LedgerEntryOut
///
/// Properties:
/// * [id] 
/// * [amount] 
/// * [reason] 
/// * [balanceAfter] 
/// * [createdAt] 
@BuiltValue()
abstract class LedgerEntryOut implements Built<LedgerEntryOut, LedgerEntryOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'reason')
  String get reason;

  @BuiltValueField(wireName: r'balance_after')
  int get balanceAfter;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  LedgerEntryOut._();

  factory LedgerEntryOut([void updates(LedgerEntryOutBuilder b)]) = _$LedgerEntryOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LedgerEntryOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LedgerEntryOut> get serializer => _$LedgerEntryOutSerializer();
}

class _$LedgerEntryOutSerializer implements PrimitiveSerializer<LedgerEntryOut> {
  @override
  final Iterable<Type> types = const [LedgerEntryOut, _$LedgerEntryOut];

  @override
  final String wireName = r'LedgerEntryOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LedgerEntryOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
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
    yield r'balance_after';
    yield serializers.serialize(
      object.balanceAfter,
      specifiedType: const FullType(int),
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
    LedgerEntryOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LedgerEntryOutBuilder result,
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
        case r'balance_after':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.balanceAfter = valueDes;
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
  LedgerEntryOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LedgerEntryOutBuilder();
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


