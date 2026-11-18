//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'animate_photo_in.g.dart';

/// AnimatePhotoIn
///
/// Properties:
/// * [imageUrl] 
/// * [motion] 
/// * [idempotencyKey] 
@BuiltValue()
abstract class AnimatePhotoIn implements Built<AnimatePhotoIn, AnimatePhotoInBuilder> {
  @BuiltValueField(wireName: r'image_url')
  String get imageUrl;

  @BuiltValueField(wireName: r'motion')
  String? get motion;

  @BuiltValueField(wireName: r'idempotency_key')
  String get idempotencyKey;

  AnimatePhotoIn._();

  factory AnimatePhotoIn([void updates(AnimatePhotoInBuilder b)]) = _$AnimatePhotoIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnimatePhotoInBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnimatePhotoIn> get serializer => _$AnimatePhotoInSerializer();
}

class _$AnimatePhotoInSerializer implements PrimitiveSerializer<AnimatePhotoIn> {
  @override
  final Iterable<Type> types = const [AnimatePhotoIn, _$AnimatePhotoIn];

  @override
  final String wireName = r'AnimatePhotoIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnimatePhotoIn object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'image_url';
    yield serializers.serialize(
      object.imageUrl,
      specifiedType: const FullType(String),
    );
    if (object.motion != null) {
      yield r'motion';
      yield serializers.serialize(
        object.motion,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'idempotency_key';
    yield serializers.serialize(
      object.idempotencyKey,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AnimatePhotoIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AnimatePhotoInBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'image_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.imageUrl = valueDes;
          break;
        case r'motion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motion = valueDes;
          break;
        case r'idempotency_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.idempotencyKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnimatePhotoIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnimatePhotoInBuilder();
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


