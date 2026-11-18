// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_entry_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LedgerEntryOut extends LedgerEntryOut {
  @override
  final String id;
  @override
  final int amount;
  @override
  final String reason;
  @override
  final int balanceAfter;
  @override
  final DateTime createdAt;

  factory _$LedgerEntryOut([void Function(LedgerEntryOutBuilder)? updates]) =>
      (LedgerEntryOutBuilder()..update(updates))._build();

  _$LedgerEntryOut._(
      {required this.id,
      required this.amount,
      required this.reason,
      required this.balanceAfter,
      required this.createdAt})
      : super._();
  @override
  LedgerEntryOut rebuild(void Function(LedgerEntryOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LedgerEntryOutBuilder toBuilder() => LedgerEntryOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LedgerEntryOut &&
        id == other.id &&
        amount == other.amount &&
        reason == other.reason &&
        balanceAfter == other.balanceAfter &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jc(_$hash, balanceAfter.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LedgerEntryOut')
          ..add('id', id)
          ..add('amount', amount)
          ..add('reason', reason)
          ..add('balanceAfter', balanceAfter)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class LedgerEntryOutBuilder
    implements Builder<LedgerEntryOut, LedgerEntryOutBuilder> {
  _$LedgerEntryOut? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  int? _balanceAfter;
  int? get balanceAfter => _$this._balanceAfter;
  set balanceAfter(int? balanceAfter) => _$this._balanceAfter = balanceAfter;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  LedgerEntryOutBuilder() {
    LedgerEntryOut._defaults(this);
  }

  LedgerEntryOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _amount = $v.amount;
      _reason = $v.reason;
      _balanceAfter = $v.balanceAfter;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LedgerEntryOut other) {
    _$v = other as _$LedgerEntryOut;
  }

  @override
  void update(void Function(LedgerEntryOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LedgerEntryOut build() => _build();

  _$LedgerEntryOut _build() {
    final _$result = _$v ??
        _$LedgerEntryOut._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'LedgerEntryOut', 'id'),
          amount: BuiltValueNullFieldError.checkNotNull(
              amount, r'LedgerEntryOut', 'amount'),
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'LedgerEntryOut', 'reason'),
          balanceAfter: BuiltValueNullFieldError.checkNotNull(
              balanceAfter, r'LedgerEntryOut', 'balanceAfter'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'LedgerEntryOut', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
