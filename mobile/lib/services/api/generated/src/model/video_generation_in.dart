//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'video_generation_in.g.dart';

/// VideoGenerationIn
///
/// Properties:
/// * [prompt] 
/// * [durationSeconds] 
/// * [resolution] 
/// * [idempotencyKey] 
@BuiltValue()
abstract class VideoGenerationIn implements Built<VideoGenerationIn, VideoGenerationInBuilder> {
  @BuiltValueField(wireName: r'prompt')
  String get prompt;

  @BuiltValueField(wireName: r'duration_seconds')
  int? get durationSeconds;

  @BuiltValueField(wireName: r'resolution')
  String? get resolution;

  @BuiltValueField(wireName: r'idempotency_key')
  String get idempotencyKey;

  VideoGenerationIn._();

  factory VideoGenerationIn([void updates(VideoGenerationInBuilder b)]) = _$VideoGenerationIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VideoGenerationInBuilder b) => b
      ..durationSeconds = 5
      ..resolution = '720p';

  @BuiltValueSerializer(custom: true)
  static Serializer<VideoGenerationIn> get serializer => _$VideoGenerationInSerializer();
}

class _$VideoGenerationInSerializer implements PrimitiveSerializer<VideoGenerationIn> {
  @override
  final Iterable<Type> types = const [VideoGenerationIn, _$VideoGenerationIn];

  @override
  final String wireName = r'VideoGenerationIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VideoGenerationIn object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'prompt';
    yield serializers.serialize(
      object.prompt,
      specifiedType: const FullType(String),
    );
    if (object.durationSeconds != null) {
      yield r'duration_seconds';
      yield serializers.serialize(
        object.durationSeconds,
        specifiedType: const FullType(int),
      );
    }
    if (object.resolution != null) {
      yield r'resolution';
      yield serializers.serialize(
        object.resolution,
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
    VideoGenerationIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VideoGenerationInBuilder result,
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
        case r'duration_seconds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.durationSeconds = valueDes;
          break;
        case r'resolution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resolution = valueDes;
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
  VideoGenerationIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VideoGenerationInBuilder();
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


