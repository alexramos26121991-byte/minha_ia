// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_generation_in.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VideoGenerationIn extends VideoGenerationIn {
  @override
  final String prompt;
  @override
  final int? durationSeconds;
  @override
  final String? resolution;
  @override
  final String idempotencyKey;

  factory _$VideoGenerationIn(
          [void Function(VideoGenerationInBuilder)? updates]) =>
      (VideoGenerationInBuilder()..update(updates))._build();

  _$VideoGenerationIn._(
      {required this.prompt,
      this.durationSeconds,
      this.resolution,
      required this.idempotencyKey})
      : super._();
  @override
  VideoGenerationIn rebuild(void Function(VideoGenerationInBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VideoGenerationInBuilder toBuilder() =>
      VideoGenerationInBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VideoGenerationIn &&
        prompt == other.prompt &&
        durationSeconds == other.durationSeconds &&
        resolution == other.resolution &&
        idempotencyKey == other.idempotencyKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, prompt.hashCode);
    _$hash = $jc(_$hash, durationSeconds.hashCode);
    _$hash = $jc(_$hash, resolution.hashCode);
    _$hash = $jc(_$hash, idempotencyKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VideoGenerationIn')
          ..add('prompt', prompt)
          ..add('durationSeconds', durationSeconds)
          ..add('resolution', resolution)
          ..add('idempotencyKey', idempotencyKey))
        .toString();
  }
}

class VideoGenerationInBuilder
    implements Builder<VideoGenerationIn, VideoGenerationInBuilder> {
  _$VideoGenerationIn? _$v;

  String? _prompt;
  String? get prompt => _$this._prompt;
  set prompt(String? prompt) => _$this._prompt = prompt;

  int? _durationSeconds;
  int? get durationSeconds => _$this._durationSeconds;
  set durationSeconds(int? durationSeconds) =>
      _$this._durationSeconds = durationSeconds;

  String? _resolution;
  String? get resolution => _$this._resolution;
  set resolution(String? resolution) => _$this._resolution = resolution;

  String? _idempotencyKey;
  String? get idempotencyKey => _$this._idempotencyKey;
  set idempotencyKey(String? idempotencyKey) =>
      _$this._idempotencyKey = idempotencyKey;

  VideoGenerationInBuilder() {
    VideoGenerationIn._defaults(this);
  }

  VideoGenerationInBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _prompt = $v.prompt;
      _durationSeconds = $v.durationSeconds;
      _resolution = $v.resolution;
      _idempotencyKey = $v.idempotencyKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VideoGenerationIn other) {
    _$v = other as _$VideoGenerationIn;
  }

  @override
  void update(void Function(VideoGenerationInBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VideoGenerationIn build() => _build();

  _$VideoGenerationIn _build() {
    final _$result = _$v ??
        _$VideoGenerationIn._(
          prompt: BuiltValueNullFieldError.checkNotNull(
              prompt, r'VideoGenerationIn', 'prompt'),
          durationSeconds: durationSeconds,
          resolution: resolution,
          idempotencyKey: BuiltValueNullFieldError.checkNotNull(
              idempotencyKey, r'VideoGenerationIn', 'idempotencyKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
