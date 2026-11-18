// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_out.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GenerationOut extends GenerationOut {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String type;
  @override
  final String status;
  @override
  final String? provider;
  @override
  final int costCredits;
  @override
  final String? storagePath;
  @override
  final DateTime createdAt;

  factory _$GenerationOut([void Function(GenerationOutBuilder)? updates]) =>
      (GenerationOutBuilder()..update(updates))._build();

  _$GenerationOut._(
      {required this.id,
      required this.userId,
      required this.type,
      required this.status,
      this.provider,
      required this.costCredits,
      this.storagePath,
      required this.createdAt})
      : super._();
  @override
  GenerationOut rebuild(void Function(GenerationOutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GenerationOutBuilder toBuilder() => GenerationOutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GenerationOut &&
        id == other.id &&
        userId == other.userId &&
        type == other.type &&
        status == other.status &&
        provider == other.provider &&
        costCredits == other.costCredits &&
        storagePath == other.storagePath &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, provider.hashCode);
    _$hash = $jc(_$hash, costCredits.hashCode);
    _$hash = $jc(_$hash, storagePath.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GenerationOut')
          ..add('id', id)
          ..add('userId', userId)
          ..add('type', type)
          ..add('status', status)
          ..add('provider', provider)
          ..add('costCredits', costCredits)
          ..add('storagePath', storagePath)
          ..add('createdAt', createdAt))
        .toString();
  }
}

class GenerationOutBuilder
    implements Builder<GenerationOut, GenerationOutBuilder> {
  _$GenerationOut? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _provider;
  String? get provider => _$this._provider;
  set provider(String? provider) => _$this._provider = provider;

  int? _costCredits;
  int? get costCredits => _$this._costCredits;
  set costCredits(int? costCredits) => _$this._costCredits = costCredits;

  String? _storagePath;
  String? get storagePath => _$this._storagePath;
  set storagePath(String? storagePath) => _$this._storagePath = storagePath;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  GenerationOutBuilder() {
    GenerationOut._defaults(this);
  }

  GenerationOutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _type = $v.type;
      _status = $v.status;
      _provider = $v.provider;
      _costCredits = $v.costCredits;
      _storagePath = $v.storagePath;
      _createdAt = $v.createdAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GenerationOut other) {
    _$v = other as _$GenerationOut;
  }

  @override
  void update(void Function(GenerationOutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GenerationOut build() => _build();

  _$GenerationOut _build() {
    final _$result = _$v ??
        _$GenerationOut._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'GenerationOut', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
              userId, r'GenerationOut', 'userId'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'GenerationOut', 'type'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'GenerationOut', 'status'),
          provider: provider,
          costCredits: BuiltValueNullFieldError.checkNotNull(
              costCredits, r'GenerationOut', 'costCredits'),
          storagePath: storagePath,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'GenerationOut', 'createdAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
