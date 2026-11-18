// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserOut extends UserOut {
  @override
  final String id;
  @override
  final String firebaseUid;
  @override
  final String email;
  @override
  final String? planSlug;
  @override
  final String status;
  @override
  final String? consentVersion;
  @override
  final DateTime createdAt;

  factory _$UserOut([void Function(UserOutBuilder)? updates]) =>
      (UserOutBuilder()..update(updates))._build();

  _$UserOut._(
      {required this.id,
      required this.firebaseUid,
      required this.email,
      this.planSlug,
      required this.status,
      this.consentVersion,
      required this.createdAt})
      : super._();
  @override
  UserOut rebuild(void Function(UserOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserOutBuilder toBuilder() => UserOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserOut &&
        id == other.id &&
        firebaseUid == other.firebaseUid &&
        email == other.email &&
        planSlug == other.planSlug &&
        status == other.status &&
        consentVersion == other.consentVersion &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, firebaseUid.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, planSlug.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, consentVersion.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserOut')
          ..add('id', id)
          ..add('firebaseUid', firebaseUid)
          ..add('email', email)
          ..add('planSlug', planSlug)
          ..add('status', status)
          ..add('consentVersion', consentVersion)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class UserOutBuilder implements Builder<UserOut, UserOutBuilder> {
  _$UserOut? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _firebaseUid;
  String? get firebaseUid => _$this._firebaseUid;
  set firebaseUid(String? firebaseUid) => _$this._firebaseUid = firebaseUid;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _planSlug;
  String? get planSlug => _$this._planSlug;
  set planSlug(String? planSlug) => _$this._planSlug = planSlug;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _consentVersion;
  String? get consentVersion => _$this._consentVersion;
  set consentVersion(String? consentVersion) =>
      _$this._consentVersion = consentVersion;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  UserOutBuilder() {
    UserOut._defaults(this);
  }

  UserOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _firebaseUid = $v.firebaseUid;
      _email = $v.email;
      _planSlug = $v.planSlug;
      _status = $v.status;
      _consentVersion = $v.consentVersion;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserOut other) {
    _$v = other as _$UserOut;
  }

  @override
  void update(void Function(UserOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserOut build() => _build();

  _$UserOut _build() {
    final _$result = _$v ??
        _$UserOut._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'UserOut', 'id'),
          firebaseUid: BuiltValueNullFieldError.checkNotNull(
              firebaseUid, r'UserOut', 'firebaseUid'),
          email:
              BuiltValueNullFieldError.checkNotNull(email, r'UserOut', 'email'),
          planSlug: planSlug,
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'UserOut', 'status'),
          consentVersion: consentVersion,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'UserOut', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
