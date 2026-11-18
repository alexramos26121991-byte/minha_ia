// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$HealthOut extends HealthOut {
  @override
  final String status;
  @override
  final String app;
  @override
  final String version;
  @override
  final String environment;

  factory _$HealthOut([void Function(HealthOutBuilder)? updates]) =>
      (HealthOutBuilder()..update(updates))._build();

  _$HealthOut._(
      {required this.status,
      required this.app,
      required this.version,
      required this.environment})
      : super._();
  @override
  HealthOut rebuild(void Function(HealthOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HealthOutBuilder toBuilder() => HealthOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HealthOut &&
        status == other.status &&
        app == other.app &&
        version == other.version &&
        environment == other.environment;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, app.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, environment.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'HealthOut')
          ..add('status', status)
          ..add('app', app)
          ..add('version', version)
          ..add('environment', environment))
        .toString();
  }
}

class HealthOutBuilder implements Builder<HealthOut, HealthOutBuilder> {
  _$HealthOut? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _app;
  String? get app => _$this._app;
  set app(String? app) => _$this._app = app;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  String? _environment;
  String? get environment => _$this._environment;
  set environment(String? environment) => _$this._environment = environment;

  HealthOutBuilder() {
    HealthOut._defaults(this);
  }

  HealthOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _app = $v.app;
      _version = $v.version;
      _environment = $v.environment;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HealthOut other) {
    _$v = other as _$HealthOut;
  }

  @override
  void update(void Function(HealthOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HealthOut build() => _build();

  _$HealthOut _build() {
    final _$result = _$v ??
        _$HealthOut._(
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'HealthOut', 'status'),
          app: BuiltValueNullFieldError.checkNotNull(app, r'HealthOut', 'app'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'HealthOut', 'version'),
          environment: BuiltValueNullFieldError.checkNotNull(
              environment, r'HealthOut', 'environment'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
