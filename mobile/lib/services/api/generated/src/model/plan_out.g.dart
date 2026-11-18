// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlanOut extends PlanOut {
  @override
  final String id;
  @override
  final String slug;
  @override
  final String name;
  @override
  final int monthlyCredits;
  @override
  final num priceBrl;
  @override
  final String recurrence;
  @override
  final bool isActive;

  factory _$PlanOut([void Function(PlanOutBuilder)? updates]) =>
      (PlanOutBuilder()..update(updates))._build();

  _$PlanOut._(
      {required this.id,
      required this.slug,
      required this.name,
      required this.monthlyCredits,
      required this.priceBrl,
      required this.recurrence,
      required this.isActive})
      : super._();
  @override
  PlanOut rebuild(void Function(PlanOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlanOutBuilder toBuilder() => PlanOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlanOut &&
        id == other.id &&
        slug == other.slug &&
        name == other.name &&
        monthlyCredits == other.monthlyCredits &&
        priceBrl == other.priceBrl &&
        recurrence == other.recurrence &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, monthlyCredits.hashCode);
    _$hash = $jc(_$hash, priceBrl.hashCode);
    _$hash = $jc(_$hash, recurrence.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlanOut')
          ..add('id', id)
          ..add('slug', slug)
          ..add('name', name)
          ..add('monthlyCredits', monthlyCredits)
          ..add('priceBrl', priceBrl)
          ..add('recurrence', recurrence)
          ..add('isActive', isActive))
        .toString();
  }
}

class PlanOutBuilder implements Builder<PlanOut, PlanOutBuilder> {
  _$PlanOut? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _monthlyCredits;
  int? get monthlyCredits => _$this._monthlyCredits;
  set monthlyCredits(int? monthlyCredits) =>
      _$this._monthlyCredits = monthlyCredits;

  num? _priceBrl;
  num? get priceBrl => _$this._priceBrl;
  set priceBrl(num? priceBrl) => _$this._priceBrl = priceBrl;

  String? _recurrence;
  String? get recurrence => _$this._recurrence;
  set recurrence(String? recurrence) => _$this._recurrence = recurrence;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  PlanOutBuilder() {
    PlanOut._defaults(this);
  }

  PlanOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _slug = $v.slug;
      _name = $v.name;
      _monthlyCredits = $v.monthlyCredits;
      _priceBrl = $v.priceBrl;
      _recurrence = $v.recurrence;
      _isActive = $v.isActive;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlanOut other) {
    _$v = other as _$PlanOut;
  }

  @override
  void update(void Function(PlanOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlanOut build() => _build();

  _$PlanOut _build() {
    final _$result = _$v ??
        _$PlanOut._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PlanOut', 'id'),
          slug: BuiltValueNullFieldError.checkNotNull(slug, r'PlanOut', 'slug'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'PlanOut', 'name'),
          monthlyCredits: BuiltValueNullFieldError.checkNotNull(
              monthlyCredits, r'PlanOut', 'monthlyCredits'),
          priceBrl: BuiltValueNullFieldError.checkNotNull(
              priceBrl, r'PlanOut', 'priceBrl'),
          recurrence: BuiltValueNullFieldError.checkNotNull(
              recurrence, r'PlanOut', 'recurrence'),
          isActive: BuiltValueNullFieldError.checkNotNull(
              isActive, r'PlanOut', 'isActive'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
