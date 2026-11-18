//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_update_in.g.dart';

/// UserUpdateIn
///
/// Properties:
/// * [fcmToken] 
/// * [consentVersion] 
@BuiltValue()
abstract class UserUpdateIn implements Built<UserUpdateIn, UserUpdateInBuilder> {
  @BuiltValueField(wireName: r'fcm_token')
  String? get fcmToken;

  @BuiltValueField(wireName: r'consent_version')
  String? get consentVersion;

  UserUpdateIn._();

  factory UserUpdateIn([void updates(UserUpdateInBuilder b)]) = _$UserUpdateIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserUpdateInBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserUpdateIn> get serializer => _$UserUpdateInSerializer();
}

class _$UserUpdateInSerializer implements PrimitiveSerializer<UserUpdateIn> {
  @override
  final Iterable<Type> types = const [UserUpdateIn, _$UserUpdateIn];

  @override
  final String wireName = r'UserUpdateIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserUpdateIn object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.fcmToken != null) {
      yield r'fcm_token';
      yield serializers.serialize(
        object.fcmToken,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.consentVersion != null) {
      yield r'consent_version';
      yield serializers.serialize(
        object.consentVersion,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserUpdateIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserUpdateInBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fcm_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.fcmToken = valueDes;
          break;
        case r'consent_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.consentVersion = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserUpdateIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserUpdateInBuilder();
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


