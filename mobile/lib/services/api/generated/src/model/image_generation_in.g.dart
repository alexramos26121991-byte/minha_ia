// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_generation_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ImageGenerationIn extends ImageGenerationIn {
  @override
  final String prompt;
  @override
  final String? style;
  @override
  final String? size;
  @override
  final String idempotencyKey;

  factory _$ImageGenerationIn(
          [void Function(ImageGenerationInBuilder)? updates]) =>
      (ImageGenerationInBuilder()..update(updates))._build();

  _$ImageGenerationIn._(
      {required this.prompt,
      this.style,
      this.size,
      required this.idempotencyKey})
      : super._();
  @override
  ImageGenerationIn rebuild(void Function(ImageGenerationInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ImageGenerationInBuilder toBuilder() =>
      ImageGenerationInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImageGenerationIn &&
        prompt == other.prompt &&
        style == other.style &&
        size == other.size &&
        idempotencyKey == other.idempotencyKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, prompt.hashCode);
    _$hash = $jc(_$hash, style.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jc(_$hash, idempotencyKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImageGenerationIn')
          ..add('prompt', prompt)
          ..add('style', style)
          ..add('size', size)
          ..add('idempotencyKey', idempotencyKey))
        .toString();
  }
}

class ImageGenerationInBuilder
    implements Builder<ImageGenerationIn, ImageGenerationInBuilder> {
  _$ImageGenerationIn? _$v;

  String? _prompt;
  String? get prompt => _$this._prompt;
  set prompt(String? prompt) => _$this._prompt = prompt;

  String? _style;
  String? get style => _$this._style;
  set style(String? style) => _$this._style = style;

  String? _size;
  String? get size => _$this._size;
  set size(String? size) => _$this._size = size;

  String? _idempotencyKey;
  String? get idempotencyKey => _$this._idempotencyKey;
  set idempotencyKey(String? idempotencyKey) =>
      _$this._idempotencyKey = idempotencyKey;

  ImageGenerationInBuilder() {
    ImageGenerationIn._defaults(this);
  }

  ImageGenerationInBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _prompt = $v.prompt;
      _style = $v.style;
      _size = $v.size;
      _idempotencyKey = $v.idempotencyKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImageGenerationIn other) {
    _$v = other as _$ImageGenerationIn;
  }

  @override
  void update(void Function(ImageGenerationInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImageGenerationIn build() => _build();

  _$ImageGenerationIn _build() {
    final _$result = _$v ??
        _$ImageGenerationIn._(
          prompt: BuiltValueNullFieldError.checkNotNull(
              prompt, r'ImageGenerationIn', 'prompt'),
          style: style,
          size: size,
          idempotencyKey: BuiltValueNullFieldError.checkNotNull(
              idempotencyKey, r'ImageGenerationIn', 'idempotencyKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
