//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'generation_out.g.dart';

/// GenerationOut
///
/// Properties:
/// * [id] 
/// * [userId] 
/// * [type] 
/// * [status] 
/// * [provider] 
/// * [costCredits] 
/// * [storagePath] 
/// * [createdAt] 
@BuiltValue()
abstract class GenerationOut implements Built<GenerationOut, GenerationOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'user_id')
  String get userId;

  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'provider')
  String? get provider;

  @BuiltValueField(wireName: r'cost_credits')
  int get costCredits;

  @BuiltValueField(wireName: r'storage_path')
  String? get storagePath;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  GenerationOut._();

  factory GenerationOut([void updates(GenerationOutBuilder b)]) = _$GenerationOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GenerationOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GenerationOut> get serializer => _$GenerationOutSerializer();
}

class _$GenerationOutSerializer implements PrimitiveSerializer<GenerationOut> {
  @override
  final Iterable<Type> types = const [GenerationOut, _$GenerationOut];

  @override
  final String wireName = r'GenerationOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GenerationOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    if (object.provider != null) {
      yield r'provider';
      yield serializers.serialize(
        object.provider,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'cost_credits';
    yield serializers.serialize(
      object.costCredits,
      specifiedType: const FullType(int),
    );
    if (object.storagePath != null) {
      yield r'storage_path';
      yield serializers.serialize(
        object.storagePath,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GenerationOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GenerationOutBuilder result,
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
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.provider = valueDes;
          break;
        case r'cost_credits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.costCredits = valueDes;
          break;
        case r'storage_path':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.storagePath = valueDes;
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
  GenerationOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GenerationOutBuilder();
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


