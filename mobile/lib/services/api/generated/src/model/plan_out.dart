//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'plan_out.g.dart';

/// PlanOut
///
/// Properties:
/// * [id] 
/// * [slug] 
/// * [name] 
/// * [monthlyCredits] 
/// * [priceBrl] 
/// * [recurrence] 
/// * [isActive] 
@BuiltValue()
abstract class PlanOut implements Built<PlanOut, PlanOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'monthly_credits')
  int get monthlyCredits;

  @BuiltValueField(wireName: r'price_brl')
  num get priceBrl;

  @BuiltValueField(wireName: r'recurrence')
  String get recurrence;

  @BuiltValueField(wireName: r'is_active')
  bool get isActive;

  PlanOut._();

  factory PlanOut([void updates(PlanOutBuilder b)]) = _$PlanOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PlanOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PlanOut> get serializer => _$PlanOutSerializer();
}

class _$PlanOutSerializer implements PrimitiveSerializer<PlanOut> {
  @override
  final Iterable<Type> types = const [PlanOut, _$PlanOut];

  @override
  final String wireName = r'PlanOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PlanOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'monthly_credits';
    yield serializers.serialize(
      object.monthlyCredits,
      specifiedType: const FullType(int),
    );
    yield r'price_brl';
    yield serializers.serialize(
      object.priceBrl,
      specifiedType: const FullType(num),
    );
    yield r'recurrence';
    yield serializers.serialize(
      object.recurrence,
      specifiedType: const FullType(String),
    );
    yield r'is_active';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PlanOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PlanOutBuilder result,
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
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'monthly_credits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.monthlyCredits = valueDes;
          break;
        case r'price_brl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.priceBrl = valueDes;
          break;
        case r'recurrence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.recurrence = valueDes;
          break;
        case r'is_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PlanOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PlanOutBuilder();
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


