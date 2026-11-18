// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_adjustment_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreditAdjustmentIn extends CreditAdjustmentIn {
  @override
  final String userId;
  @override
  final int amount;
  @override
  final String reason;

  factory _$CreditAdjustmentIn(
          [void Function(CreditAdjustmentInBuilder)? updates]) =>
      (CreditAdjustmentInBuilder()..update(updates))._build();

  _$CreditAdjustmentIn._(
      {required this.userId, required this.amount, required this.reason})
      : super._();
  @override
  CreditAdjustmentIn rebuild(
          void Function(CreditAdjustmentInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreditAdjustmentInBuilder toBuilder() =>
      CreditAdjustmentInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreditAdjustmentIn &&
        userId == other.userId &&
        amount == other.amount &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreditAdjustmentIn')
          ..add('userId', userId)
          ..add('amount', amount)
          ..add('reason', reason))
        .toString();
  }
}

class CreditAdjustmentInBuilder
    implements Builder<CreditAdjustmentIn, CreditAdjustmentInBuilder> {
  _$CreditAdjustmentIn? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  CreditAdjustmentInBuilder() {
    CreditAdjustmentIn._defaults(this);
  }

  CreditAdjustmentInBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _amount = $v.amount;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreditAdjustmentIn other) {
    _$v = other as _$CreditAdjustmentIn;
  }

  @override
  void update(void Function(CreditAdjustmentInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreditAdjustmentIn build() => _build();

  _$CreditAdjustmentIn _build() {
    final _$result = _$v ??
        _$CreditAdjustmentIn._(
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'CreditAdjustmentIn', 'userId'),
          amount: BuiltValueNullFieldError.checkNotNull(
              amount, r'CreditAdjustmentIn', 'amount'),
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'CreditAdjustmentIn', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
