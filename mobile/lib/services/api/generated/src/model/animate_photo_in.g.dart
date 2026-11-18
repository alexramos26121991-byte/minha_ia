// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'animate_photo_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AnimatePhotoIn extends AnimatePhotoIn {
  @override
  final String imageUrl;
  @override
  final String? motion;
  @override
  final String idempotencyKey;

  factory _$AnimatePhotoIn([void Function(AnimatePhotoInBuilder)? updates]) =>
      (AnimatePhotoInBuilder()..update(updates))._build();

  _$AnimatePhotoIn._(
      {required this.imageUrl, this.motion, required this.idempotencyKey})
      : super._();
  @override
  AnimatePhotoIn rebuild(void Function(AnimatePhotoInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AnimatePhotoInBuilder toBuilder() => AnimatePhotoInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnimatePhotoIn &&
        imageUrl == other.imageUrl &&
        motion == other.motion &&
        idempotencyKey == other.idempotencyKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, imageUrl.hashCode);
    _$hash = $jc(_$hash, motion.hashCode);
    _$hash = $jc(_$hash, idempotencyKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AnimatePhotoIn')
          ..add('imageUrl', imageUrl)
          ..add('motion', motion)
          ..add('idempotencyKey', idempotencyKey))
        .toString();
  }
}

class AnimatePhotoInBuilder
    implements Builder<AnimatePhotoIn, AnimatePhotoInBuilder> {
  _$AnimatePhotoIn? _$v;

  String? _imageUrl;
  String? get imageUrl => _$this._imageUrl;
  set imageUrl(String? imageUrl) => _$this._imageUrl = imageUrl;

  String? _motion;
  String? get motion => _$this._motion;
  set motion(String? motion) => _$this._motion = motion;

  String? _idempotencyKey;
  String? get idempotencyKey => _$this._idempotencyKey;
  set idempotencyKey(String? idempotencyKey) =>
      _$this._idempotencyKey = idempotencyKey;

  AnimatePhotoInBuilder() {
    AnimatePhotoIn._defaults(this);
  }

  AnimatePhotoInBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _imageUrl = $v.imageUrl;
      _motion = $v.motion;
      _idempotencyKey = $v.idempotencyKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnimatePhotoIn other) {
    _$v = other as _$AnimatePhotoIn;
  }

  @override
  void update(void Function(AnimatePhotoInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnimatePhotoIn build() => _build();

  _$AnimatePhotoIn _build() {
    final _$result = _$v ??
        _$AnimatePhotoIn._(
          imageUrl: BuiltValueNullFieldError.checkNotNull(
              imageUrl, r'AnimatePhotoIn', 'imageUrl'),
          motion: motion,
          idempotencyKey: BuiltValueNullFieldError.checkNotNull(
              idempotencyKey, r'AnimatePhotoIn', 'idempotencyKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
