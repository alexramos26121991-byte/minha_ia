//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_in.g.dart';

/// Dados do dispositivo enviados no abertura de sessão.  ``fcm_token`` é registrado já no login para que as notificações da E5 possam ser enviadas sem uma segunda chamada do app.
///
/// Properties:
/// * [fcmToken] 
/// * [consentVersion] 
/// * [displayName] 
@BuiltValue()
abstract class SessionIn implements Built<SessionIn, SessionInBuilder> {
  @BuiltValueField(wireName: r'fcm_token')
  String? get fcmToken;

  @BuiltValueField(wireName: r'consent_version')
  String? get consentVersion;

  @BuiltValueField(wireName: r'display_name')
  String? get displayName;

  SessionIn._();

  factory SessionIn([void updates(SessionInBuilder b)]) = _$SessionIn;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionInBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionIn> get serializer => _$SessionInSerializer();
}

class _$SessionInSerializer implements PrimitiveSerializer<SessionIn> {
  @override
  final Iterable<Type> types = const [SessionIn, _$SessionIn];

  @override
  final String wireName = r'SessionIn';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionIn object, {
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
    if (object.displayName != null) {
      yield r'display_name';
      yield serializers.serialize(
        object.displayName,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionIn object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionInBuilder result,
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
        case r'display_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.displayName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionIn deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionInBuilder();
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


