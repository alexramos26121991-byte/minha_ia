//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'image_generation_in.g.dart';

/// ImageGenerationIn
///
/// Properties:
/// * [prompt] 
/// * [style] 
/// * [size] 
/// * [idempotencyKey] 
@BuiltValue()
abstract class ImageGenerationIn implements Built<ImageGenerationIn, ImageGenerationInBuilder> {
  @BuiltValueField(wireName: r'prompt')
  String get prompt;

  @BuiltValueField(wireName: r'style')
  String? get style;

  @BuiltValueField(wireName: r'size')
  String? get size;

  @BuiltValueField(wireName: r'idempotency_key')
  String get idempotencyKey;

  ImageGenerationIn._();

  factory ImageGenerationIn([void updates(ImageGenerationInBuilder b)]) = _$ImageGenerationIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ImageGenerationInBuilder b) => b
      ..size = '1024x1024';

  @BuiltValueSerializer(custom: true)
  static Serializer<ImageGenerationIn> get serializer => _$ImageGenerationInSerializer();
}

class _$ImageGenerationInSerializer implements PrimitiveSerializer<ImageGenerationIn> {
  @override
  final Iterable<Type> types = const [ImageGenerationIn, _$ImageGenerationIn];

  @override
  final String wireName = r'ImageGenerationIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ImageGenerationIn object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'prompt';
    yield serializers.serialize(
      object.prompt,
      specifiedType: const FullType(String),
    );
    if (object.style != null) {
      yield r'style';
      yield serializers.serialize(
        object.style,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.size != null) {
      yield r'size';
      yield serializers.serialize(
        object.size,
        specifiedType: const FullType(String),
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
    ImageGenerationIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ImageGenerationInBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'prompt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prompt = valueDes;
          break;
        case r'style':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.style = valueDes;
          break;
        case r'size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.size = valueDes;
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
  ImageGenerationIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ImageGenerationInBuilder();
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


