// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_config_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CostConfigOut extends CostConfigOut {
  @override
  final String operation;
  @override
  final int credits;
  @override
  final bool enabled;

  factory _$CostConfigOut([void Function(CostConfigOutBuilder)? updates]) =>
      (CostConfigOutBuilder()..update(updates))._build();

  _$CostConfigOut._(
      {required this.operation, required this.credits, required this.enabled})
      : super._();
  @override
  CostConfigOut rebuild(void Function(CostConfigOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CostConfigOutBuilder toBuilder() => CostConfigOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CostConfigOut &&
        operation == other.operation &&
        credits == other.credits &&
        enabled == other.enabled;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, operation.hashCode);
    _$hash = $jc(_$hash, credits.hashCode);
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CostConfigOut')
          ..add('operation', operation)
          ..add('credits', credits)
          ..add('enabled', enabled))
        .toString();
  }
}

class CostConfigOutBuilder
    implements Builder<CostConfigOut, CostConfigOutBuilder> {
  _$CostConfigOut? _$v;

  String? _operation;
  String? get operation => _$this._operation;
  set operation(String? operation) => _$this._operation = operation;

  int? _credits;
  int? get credits => _$this._credits;
  set credits(int? credits) => _$this._credits = credits;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  CostConfigOutBuilder() {
    CostConfigOut._defaults(this);
  }

  CostConfigOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _operation = $v.operation;
      _credits = $v.credits;
      _enabled = $v.enabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CostConfigOut other) {
    _$v = other as _$CostConfigOut;
  }

  @override
  void update(void Function(CostConfigOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CostConfigOut build() => _build();

  _$CostConfigOut _build() {
    final _$result = _$v ??
        _$CostConfigOut._(
          operation: BuiltValueNullFieldError.checkNotNull(
              operation, r'CostConfigOut', 'operation'),
          credits: BuiltValueNullFieldError.checkNotNull(
              credits, r'CostConfigOut', 'credits'),
          enabled: BuiltValueNullFieldError.checkNotNull(
              enabled, r'CostConfigOut', 'enabled'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
