// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BalanceOut extends BalanceOut {
  @override
  final String userId;
  @override
  final int balance;
  @override
  final int? reserved;
  @override
  final int available;

  factory _$BalanceOut([void Function(BalanceOutBuilder)? updates]) =>
      (BalanceOutBuilder()..update(updates))._build();

  _$BalanceOut._(
      {required this.userId,
      required this.balance,
      this.reserved,
      required this.available})
      : super._();
  @override
  BalanceOut rebuild(void Function(BalanceOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BalanceOutBuilder toBuilder() => BalanceOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BalanceOut &&
        userId == other.userId &&
        balance == other.balance &&
        reserved == other.reserved &&
        available == other.available;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, balance.hashCode);
    _$hash = $jc(_$hash, reserved.hashCode);
    _$hash = $jc(_$hash, available.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BalanceOut')
          ..add('userId', userId)
          ..add('balance', balance)
          ..add('reserved', reserved)
          ..add('available', available))
        .toString();
  }
}

class BalanceOutBuilder implements Builder<BalanceOut, BalanceOutBuilder> {
  _$BalanceOut? _$v;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  int? _balance;
  int? get balance => _$this._balance;
  set balance(int? balance) => _$this._balance = balance;

  int? _reserved;
  int? get reserved => _$this._reserved;
  set reserved(int? reserved) => _$this._reserved = reserved;

  int? _available;
  int? get available => _$this._available;
  set available(int? available) => _$this._available = available;

  BalanceOutBuilder() {
    BalanceOut._defaults(this);
  }

  BalanceOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userId = $v.userId;
      _balance = $v.balance;
      _reserved = $v.reserved;
      _available = $v.available;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BalanceOut other) {
    _$v = other as _$BalanceOut;
  }

  @override
  void update(void Function(BalanceOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BalanceOut build() => _build();

  _$BalanceOut _build() {
    final _$result = _$v ??
        _$BalanceOut._(
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'BalanceOut', 'userId'),
          balance: BuiltValueNullFieldError.checkNotNull(
              balance, r'BalanceOut', 'balance'),
          reserved: reserved,
          available: BuiltValueNullFieldError.checkNotNull(
              available, r'BalanceOut', 'available'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
