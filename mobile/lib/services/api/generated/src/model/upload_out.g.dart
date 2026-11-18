// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UploadOut extends UploadOut {
  @override
  final String imageUrl;
  @override
  final String mediaType;

  factory _$UploadOut([void Function(UploadOutBuilder)? updates]) =>
      (UploadOutBuilder()..update(updates))._build();

  _$UploadOut._({required this.imageUrl, required this.mediaType}) : super._();
  @override
  UploadOut rebuild(void Function(UploadOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UploadOutBuilder toBuilder() => UploadOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UploadOut &&
        imageUrl == other.imageUrl &&
        mediaType == other.mediaType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, imageUrl.hashCode);
    _$hash = $jc(_$hash, mediaType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UploadOut')
          ..add('imageUrl', imageUrl)
          ..add('mediaType', mediaType))
        .toString();
  }
}

class UploadOutBuilder implements Builder<UploadOut, UploadOutBuilder> {
  _$UploadOut? _$v;

  String? _imageUrl;
  String? get imageUrl => _$this._imageUrl;
  set imageUrl(String? imageUrl) => _$this._imageUrl = imageUrl;

  String? _mediaType;
  String? get mediaType => _$this._mediaType;
  set mediaType(String? mediaType) => _$this._mediaType = mediaType;

  UploadOutBuilder() {
    UploadOut._defaults(this);
  }

  UploadOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _imageUrl = $v.imageUrl;
      _mediaType = $v.mediaType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UploadOut other) {
    _$v = other as _$UploadOut;
  }

  @override
  void update(void Function(UploadOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UploadOut build() => _build();

  _$UploadOut _build() {
    final _$result = _$v ??
        _$UploadOut._(
          imageUrl: BuiltValueNullFieldError.checkNotNull(
              imageUrl, r'UploadOut', 'imageUrl'),
          mediaType: BuiltValueNullFieldError.checkNotNull(
              mediaType, r'UploadOut', 'mediaType'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
