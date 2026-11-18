// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionIn extends SessionIn {
  @override
  final String? fcmToken;
  @override
  final String? consentVersion;
  @override
  final String? displayName;

  factory _$SessionIn([void Function(SessionInBuilder)? updates]) =>
      (SessionInBuilder()..update(updates))._build();

  _$SessionIn._({this.fcmToken, this.consentVersion, this.displayName})
      : super._();
  @override
  SessionIn rebuild(void Function(SessionInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionInBuilder toBuilder() => SessionInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionIn &&
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
    return (newBuiltValueToStringHelper(r'SessionIn')
          ..add('fcmToken', fcmToken)
          ..add('consentVersion', consentVersion)
          ..add('displayName', displayName))
        .toString();
  }
}

class SessionInBuilder implements Builder<SessionIn, SessionInBuilder> {
  _$SessionIn? _$v;

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

  SessionInBuilder() {
    SessionIn._defaults(this);
  }

  SessionInBuilder get _$this {
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
  void replace(SessionIn other) {
    _$v = other as _$SessionIn;
  }

  @override
  void update(void Function(SessionInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionIn build() => _build();

  _$SessionIn _build() {
    final _$result = _$v ??
        _$SessionIn._(
          fcmToken: fcmToken,
          consentVersion: consentVersion,
          displayName: displayName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
