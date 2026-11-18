// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionOut extends SessionOut {
  @override
  final String userId;
  @override
  final bool isNew;
  @override
  final String? planSlug;

  factory _$SessionOut([void Function(SessionOutBuilder)? updates]) =>
      (SessionOutBuilder()..update(updates))._build();

  _$SessionOut._({required this.userId, required this.isNew, this.planSlug})
      : super._();
  @override
  SessionOut rebuild(void Function(SessionOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionOutBuilder toBuilder() => SessionOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionOut &&
        userId == other.userId &&
        isNew == other.isNew &&
        planSlug == other.planSlug;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, isNew.hashCode);
    _$hash = $jc(_$hash, planSlug.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionOut')
          ..add('userId', userId)
          ..add('isNew', isNew)
          ..add('planSlug', planSlug))
        .toString();
  }
}

class SessionOutBuilder implements Builder<SessionOut, SessionOutBuilder> {
  _$SessionOut? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  bool? _isNew;
  bool? get isNew => _$this._isNew;
  set isNew(bool? isNew) => _$this._isNew = isNew;

  String? _planSlug;
  String? get planSlug => _$this._planSlug;
  set planSlug(String? planSlug) => _$this._planSlug = planSlug;

  SessionOutBuilder() {
    SessionOut._defaults(this);
  }

  SessionOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _isNew = $v.isNew;
      _planSlug = $v.planSlug;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionOut other) {
    _$v = other as _$SessionOut;
  }

  @override
  void update(void Function(SessionOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionOut build() => _build();

  _$SessionOut _build() {
    final _$result = _$v ??
        _$SessionOut._(
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'SessionOut', 'userId'),
          isNew: BuiltValueNullFieldError.checkNotNull(
              isNew, r'SessionOut', 'isNew'),
          planSlug: planSlug,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
