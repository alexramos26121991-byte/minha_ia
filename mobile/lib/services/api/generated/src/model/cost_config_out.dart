//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cost_config_out.g.dart';

/// CostConfigOut
///
/// Properties:
/// * [operation]
/// * [credits]
/// * [enabled]
@BuiltValue()
abstract class CostConfigOut implements Built<CostConfigOut, CostConfigOutBuilder> {
  @BuiltValueField(wireName: r'operation')
  String get operation;

  @BuiltValueField(wireName: r'credits')
  int get credits;

  @BuiltValueField(wireName: r'enabled')
  bool get enabled;

  CostConfigOut._();

  factory CostConfigOut([void updates(CostConfigOutBuilder b)]) = _$CostConfigOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CostConfigOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CostConfigOut> get serializer => _$CostConfigOutSerializer();
}

class _$CostConfigOutSerializer implements PrimitiveSerializer<CostConfigOut> {
  @override
  final Iterable<Type> types = const [CostConfigOut, _$CostConfigOut];

  @override
  final String wireName = r'CostConfigOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CostConfigOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'operation';
    yield serializers.serialize(
      object.operation,
      specifiedType: const FullType(String),
    );
    yield r'credits';
    yield serializers.serialize(
      object.credits,
      specifiedType: const FullType(int),
    );
    yield r'enabled';
    yield serializers.serialize(
      object.enabled,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CostConfigOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CostConfigOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'operation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.operation = valueDes;
          break;
        case r'credits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.credits = valueDes;
          break;
        case r'enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enabled = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CostConfigOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CostConfigOutBuilder();
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


