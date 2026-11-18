// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_update_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UserUpdateIn extends UserUpdateIn {
  @override
  final String? fcmToken;
  @override
  final String? consentVersion;
  @override
  final String? displayName;

  factory _$UserUpdateIn([void Function(UserUpdateInBuilder)? updates]) =>
      (UserUpdateInBuilder()..update(updates))._build();

  _$UserUpdateIn._({this.fcmToken, this.consentVersion, this.displayName})
      : super._();
  @override
  UserUpdateIn rebuild(void Function(UserUpdateInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserUpdateInBuilder toBuilder() => UserUpdateInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserUpdateIn &&
        fcmToken == other.fcmToken &&
        consentVersion == other.consentVersion &&
        displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fcmToken.hashCode);
    _$hash = $jc(_$hash, consentVersion.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UserUpdateIn')
          ..add('fcmToken', fcmToken)
          ..add('consentVersion', consentVersion)
          ..add('displayName', displayName))
        .toString();
  }
}

class UserUpdateInBuilder
    implements Builder<UserUpdateIn, UserUpdateInBuilder> {
  _$UserUpdateIn? _$v;

  String? _fcmToken;
  String? get fcmToken => _$this._fcmToken;
  set fcmToken(String? fcmToken) => _$this._fcmToken = fcmToken;

  String? _consentVersion;
  String? get consentVersion => _$this._consentVersion;
  set consentVersion(String? consentVersion) =>
      _$this._consentVersion = consentVersion;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  UserUpdateInBuilder() {
    UserUpdateIn._defaults(this);
  }

  UserUpdateInBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fcmToken = $v.fcmToken;
      _consentVersion = $v.consentVersion;
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserUpdateIn other) {
    _$v = other as _$UserUpdateIn;
  }

  @override
  void update(void Function(UserUpdateInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UserUpdateIn build() => _build();

  _$UserUpdateIn _build() {
    final _$result = _$v ??
        _$UserUpdateIn._(
          fcmToken: fcmToken,
          consentVersion: consentVersion,
          displayName: displayName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
