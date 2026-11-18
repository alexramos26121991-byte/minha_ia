// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CheckoutIn extends CheckoutIn {
  @override
  final String planSlug;
  @override
  final String provider;
  @override
  final String? successUrl;

  factory _$CheckoutIn([void Function(CheckoutInBuilder)? updates]) =>
      (CheckoutInBuilder()..update(updates))._build();

  _$CheckoutIn._(
      {required this.planSlug, required this.provider, this.successUrl})
      : super._();
  @override
  CheckoutIn rebuild(void Function(CheckoutInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CheckoutInBuilder toBuilder() => CheckoutInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CheckoutIn &&
        planSlug == other.planSlug &&
        provider == other.provider &&
        successUrl == other.successUrl;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, planSlug.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, successUrl.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CheckoutIn')
          ..add('planSlug', planSlug)
          ..add('provider', provider)
          ..add('successUrl', successUrl))
        .toString();
  }
}

class CheckoutInBuilder implements Builder<CheckoutIn, CheckoutInBuilder> {
  _$CheckoutIn? _$v;

  String? _planSlug;
  String? get planSlug => _$this._planSlug;
  set planSlug(String? planSlug) => _$this._planSlug = planSlug;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  String? _successUrl;
  String? get successUrl => _$this._successUrl;
  set successUrl(String? successUrl) => _$this._successUrl = successUrl;

  CheckoutInBuilder() {
    CheckoutIn._defaults(this);
  }

  CheckoutInBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _planSlug = $v.planSlug;
      _provider = $v.provider;
      _successUrl = $v.successUrl;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CheckoutIn other) {
    _$v = other as _$CheckoutIn;
  }

  @override
  void update(void Function(CheckoutInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CheckoutIn build() => _build();

  _$CheckoutIn _build() {
    final _$result = _$v ??
        _$CheckoutIn._(
          planSlug: BuiltValueNullFieldError.checkNotNull(
              planSlug, r'CheckoutIn', 'planSlug'),
          provider: BuiltValueNullFieldError.checkNotNull(
              provider, r'CheckoutIn', 'provider'),
          successUrl: successUrl,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
