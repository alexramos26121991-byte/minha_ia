//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_out.g.dart';

/// SessionOut
///
/// Properties:
/// * [userId] 
/// * [isNew] 
/// * [planSlug] 
@BuiltValue()
abstract class SessionOut implements Built<SessionOut, SessionOutBuilder> {
  @BuiltValueField(wireName: r'user_id')
  String get userId;

  @BuiltValueField(wireName: r'is_new')
  bool get isNew;

  @BuiltValueField(wireName: r'plan_slug')
  String? get planSlug;

  SessionOut._();

  factory SessionOut([void updates(SessionOutBuilder b)]) = _$SessionOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionOut> get serializer => _$SessionOutSerializer();
}

class _$SessionOutSerializer implements PrimitiveSerializer<SessionOut> {
  @override
  final Iterable<Type> types = const [SessionOut, _$SessionOut];

  @override
  final String wireName = r'SessionOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'is_new';
    yield serializers.serialize(
      object.isNew,
      specifiedType: const FullType(bool),
    );
    if (object.planSlug != null) {
      yield r'plan_slug';
      yield serializers.serialize(
        object.planSlug,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionOutBuilder result,
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
        case r'is_new':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isNew = valueDes;
          break;
        case r'plan_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.planSlug = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionOutBuilder();
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


