// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaymentOut extends PaymentOut {
  @override
  final String id;
  @override
  final String provider;
  @override
  final String externalId;
  @override
  final num amountBrl;
  @override
  final String status;
  @override
  final DateTime createdAt;

  factory _$PaymentOut([void Function(PaymentOutBuilder)? updates]) =>
      (PaymentOutBuilder()..update(updates))._build();

  _$PaymentOut._(
      {required this.id,
      required this.provider,
      required this.externalId,
      required this.amountBrl,
      required this.status,
      required this.createdAt})
      : super._();
  @override
  PaymentOut rebuild(void Function(PaymentOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentOutBuilder toBuilder() => PaymentOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaymentOut &&
        id == other.id &&
        provider == other.provider &&
        externalId == other.externalId &&
        amountBrl == other.amountBrl &&
        status == other.status &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, externalId.hashCode);
    _$hash = $jc(_$hash, amountBrl.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaymentOut')
          ..add('id', id)
          ..add('provider', provider)
          ..add('externalId', externalId)
          ..add('amountBrl', amountBrl)
          ..add('status', status)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class PaymentOutBuilder implements Builder<PaymentOut, PaymentOutBuilder> {
  _$PaymentOut? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _externalId;
  String? get externalId => _$this._externalId;
  set externalId(String? externalId) => _$this._externalId = externalId;

  num? _amountBrl;
  num? get amountBrl => _$this._amountBrl;
  set amountBrl(num? amountBrl) => _$this._amountBrl = amountBrl;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  PaymentOutBuilder() {
    PaymentOut._defaults(this);
  }

  PaymentOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _provider = $v.provider;
      _externalId = $v.externalId;
      _amountBrl = $v.amountBrl;
      _status = $v.status;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaymentOut other) {
    _$v = other as _$PaymentOut;
  }

  @override
  void update(void Function(PaymentOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaymentOut build() => _build();

  _$PaymentOut _build() {
    final _$result = _$v ??
        _$PaymentOut._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PaymentOut', 'id'),
          provider: BuiltValueNullFieldError.checkNotNull(
              provider, r'PaymentOut', 'provider'),
          externalId: BuiltValueNullFieldError.checkNotNull(
              externalId, r'PaymentOut', 'externalId'),
          amountBrl: BuiltValueNullFieldError.checkNotNull(
              amountBrl, r'PaymentOut', 'amountBrl'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PaymentOut', 'status'),
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'PaymentOut', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
