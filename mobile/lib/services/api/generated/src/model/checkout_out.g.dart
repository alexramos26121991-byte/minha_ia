// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CheckoutOut extends CheckoutOut {
  @override
  final String checkoutId;
  @override
  final String provider;
  @override
  final String checkoutUrl;
  @override
  final DateTime? expiresAt;

  factory _$CheckoutOut([void Function(CheckoutOutBuilder)? updates]) =>
      (CheckoutOutBuilder()..update(updates))._build();

  _$CheckoutOut._(
      {required this.checkoutId,
      required this.provider,
      required this.checkoutUrl,
      this.expiresAt})
      : super._();
  @override
  CheckoutOut rebuild(void Function(CheckoutOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CheckoutOutBuilder toBuilder() => CheckoutOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CheckoutOut &&
        checkoutId == other.checkoutId &&
        provider == other.provider &&
        checkoutUrl == other.checkoutUrl &&
        expiresAt == other.expiresAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, checkoutId.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, checkoutUrl.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CheckoutOut')
          ..add('checkoutId', checkoutId)
          ..add('provider', provider)
          ..add('checkoutUrl', checkoutUrl)
          ..add('expiresAt', expiresAt))
        .toString();
  }
}

class CheckoutOutBuilder implements Builder<CheckoutOut, CheckoutOutBuilder> {
  _$CheckoutOut? _$v;

  String? _checkoutId;
  String? get checkoutId => _$this._checkoutId;
  set checkoutId(String? checkoutId) => _$this._checkoutId = checkoutId;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _checkoutUrl;
  String? get checkoutUrl => _$this._checkoutUrl;
  set checkoutUrl(String? checkoutUrl) => _$this._checkoutUrl = checkoutUrl;

  DateTime? _expiresAt;
  DateTime? get expiresAt => _$this._expiresAt;
  set expiresAt(DateTime? expiresAt) => _$this._expiresAt = expiresAt;

  CheckoutOutBuilder() {
    CheckoutOut._defaults(this);
  }

  CheckoutOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _checkoutId = $v.checkoutId;
      _provider = $v.provider;
      _checkoutUrl = $v.checkoutUrl;
      _expiresAt = $v.expiresAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CheckoutOut other) {
    _$v = other as _$CheckoutOut;
  }

  @override
  void update(void Function(CheckoutOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CheckoutOut build() => _build();

  _$CheckoutOut _build() {
    final _$result = _$v ??
        _$CheckoutOut._(
          checkoutId: BuiltValueNullFieldError.checkNotNull(
              checkoutId, r'CheckoutOut', 'checkoutId'),
          provider: BuiltValueNullFieldError.checkNotNull(
              provider, r'CheckoutOut', 'provider'),
          checkoutUrl: BuiltValueNullFieldError.checkNotNull(
              checkoutUrl, r'CheckoutOut', 'checkoutUrl'),
          expiresAt: expiresAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
