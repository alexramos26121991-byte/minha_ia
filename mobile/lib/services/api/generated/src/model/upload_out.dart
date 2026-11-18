//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'upload_out.g.dart';

/// URL pública da imagem enviada ao backend para animar depois.
///
/// Properties:
/// * [imageUrl]
/// * [mediaType]
@BuiltValue()
abstract class UploadOut implements Built<UploadOut, UploadOutBuilder> {
  @BuiltValueField(wireName: r'image_url')
  String get imageUrl;

  @BuiltValueField(wireName: r'media_type')
  String get mediaType;

  UploadOut._();

  factory UploadOut([void updates(UploadOutBuilder b)]) = _$UploadOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UploadOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UploadOut> get serializer => _$UploadOutSerializer();
}

class _$UploadOutSerializer implements PrimitiveSerializer<UploadOut> {
  @override
  final Iterable<Type> types = const [UploadOut, _$UploadOut];

  @override
  final String wireName = r'UploadOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UploadOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'image_url';
    yield serializers.serialize(
      object.imageUrl,
      specifiedType: const FullType(String),
    );
    yield r'media_type';
    yield serializers.serialize(
      object.mediaType,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UploadOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UploadOutBuilder result,
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
        case r'media_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mediaType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UploadOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UploadOutBuilder();
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


