// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorksTable extends Works with TableInfo<$WorksTable, WorkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(WorkKind.paperBook.name),
      ).withConverter<WorkKind>($WorksTable.$converterkind);
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkpointsMeta = const VerificationMeta(
    'checkpoints',
  );
  @override
  late final GeneratedColumn<String> checkpoints = GeneratedColumn<String>(
    'checkpoints',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionAtMeta = const VerificationMeta(
    'positionAt',
  );
  @override
  late final GeneratedColumn<DateTime> positionAt = GeneratedColumn<DateTime>(
    'position_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedChangedAtMeta = const VerificationMeta(
    'deletedChangedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedChangedAt =
      GeneratedColumn<DateTime>(
        'deleted_changed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    kind,
    totalPages,
    checkpoints,
    position,
    updatedAt,
    positionAt,
    deleted,
    deletedChangedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'works';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPagesMeta);
    }
    if (data.containsKey('checkpoints')) {
      context.handle(
        _checkpointsMeta,
        checkpoints.isAcceptableOrUnknown(
          data['checkpoints']!,
          _checkpointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_checkpointsMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('position_at')) {
      context.handle(
        _positionAtMeta,
        positionAt.isAcceptableOrUnknown(data['position_at']!, _positionAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('deleted_changed_at')) {
      context.handle(
        _deletedChangedAtMeta,
        deletedChangedAt.isAcceptableOrUnknown(
          data['deleted_changed_at']!,
          _deletedChangedAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      kind: $WorksTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      checkpoints: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkpoints'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      positionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}position_at'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      deletedChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_changed_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $WorksTable createAlias(String alias) {
    return $WorksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkKind, String, String> $converterkind =
      const EnumNameConverter<WorkKind>(WorkKind.values);
}

class WorkRow extends DataClass implements Insertable<WorkRow> {
  final String id;
  final String title;
  final String author;
  final WorkKind kind;
  final int totalPages;
  final String checkpoints;
  final int position;
  final DateTime updatedAt;

  /// When [position] last changed. Sync keeps the later Position apart from
  /// the rest of the row, so a rename elsewhere can't move it back.
  /// Nullable only because SQLite can't add a NOT NULL column to old rows;
  /// the migration fills it in, and null reads as [updatedAt].
  final DateTime? positionAt;

  /// A deleted Work stays as a tombstone, so the delete syncs. Its
  /// Sessions and Notes stay too.
  final bool deleted;

  /// When [deleted] last changed: a delete or its Undo. Like [positionAt],
  /// sync keeps its own last write, so an edit or a Session elsewhere
  /// can't bring a deleted Work back. Null means never.
  final DateTime? deletedChangedAt;

  /// The [updatedAt] last sent to or taken from the sync server. Null or
  /// different when there's a change to send.
  final DateTime? syncedAt;
  const WorkRow({
    required this.id,
    required this.title,
    required this.author,
    required this.kind,
    required this.totalPages,
    required this.checkpoints,
    required this.position,
    required this.updatedAt,
    this.positionAt,
    required this.deleted,
    this.deletedChangedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    {
      map['kind'] = Variable<String>($WorksTable.$converterkind.toSql(kind));
    }
    map['total_pages'] = Variable<int>(totalPages);
    map['checkpoints'] = Variable<String>(checkpoints);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || positionAt != null) {
      map['position_at'] = Variable<DateTime>(positionAt);
    }
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || deletedChangedAt != null) {
      map['deleted_changed_at'] = Variable<DateTime>(deletedChangedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  WorksCompanion toCompanion(bool nullToAbsent) {
    return WorksCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      kind: Value(kind),
      totalPages: Value(totalPages),
      checkpoints: Value(checkpoints),
      position: Value(position),
      updatedAt: Value(updatedAt),
      positionAt: positionAt == null && nullToAbsent
          ? const Value.absent()
          : Value(positionAt),
      deleted: Value(deleted),
      deletedChangedAt: deletedChangedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedChangedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory WorkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      kind: $WorksTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      checkpoints: serializer.fromJson<String>(json['checkpoints']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      positionAt: serializer.fromJson<DateTime?>(json['positionAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      deletedChangedAt: serializer.fromJson<DateTime?>(
        json['deletedChangedAt'],
      ),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'kind': serializer.toJson<String>(
        $WorksTable.$converterkind.toJson(kind),
      ),
      'totalPages': serializer.toJson<int>(totalPages),
      'checkpoints': serializer.toJson<String>(checkpoints),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'positionAt': serializer.toJson<DateTime?>(positionAt),
      'deleted': serializer.toJson<bool>(deleted),
      'deletedChangedAt': serializer.toJson<DateTime?>(deletedChangedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  WorkRow copyWith({
    String? id,
    String? title,
    String? author,
    WorkKind? kind,
    int? totalPages,
    String? checkpoints,
    int? position,
    DateTime? updatedAt,
    Value<DateTime?> positionAt = const Value.absent(),
    bool? deleted,
    Value<DateTime?> deletedChangedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => WorkRow(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    kind: kind ?? this.kind,
    totalPages: totalPages ?? this.totalPages,
    checkpoints: checkpoints ?? this.checkpoints,
    position: position ?? this.position,
    updatedAt: updatedAt ?? this.updatedAt,
    positionAt: positionAt.present ? positionAt.value : this.positionAt,
    deleted: deleted ?? this.deleted,
    deletedChangedAt: deletedChangedAt.present
        ? deletedChangedAt.value
        : this.deletedChangedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  WorkRow copyWithCompanion(WorksCompanion data) {
    return WorkRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      kind: data.kind.present ? data.kind.value : this.kind,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      checkpoints: data.checkpoints.present
          ? data.checkpoints.value
          : this.checkpoints,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      positionAt: data.positionAt.present
          ? data.positionAt.value
          : this.positionAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      deletedChangedAt: data.deletedChangedAt.present
          ? data.deletedChangedAt.value
          : this.deletedChangedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('totalPages: $totalPages, ')
          ..write('checkpoints: $checkpoints, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('positionAt: $positionAt, ')
          ..write('deleted: $deleted, ')
          ..write('deletedChangedAt: $deletedChangedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    kind,
    totalPages,
    checkpoints,
    position,
    updatedAt,
    positionAt,
    deleted,
    deletedChangedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.kind == this.kind &&
          other.totalPages == this.totalPages &&
          other.checkpoints == this.checkpoints &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.positionAt == this.positionAt &&
          other.deleted == this.deleted &&
          other.deletedChangedAt == this.deletedChangedAt &&
          other.syncedAt == this.syncedAt);
}

class WorksCompanion extends UpdateCompanion<WorkRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> author;
  final Value<WorkKind> kind;
  final Value<int> totalPages;
  final Value<String> checkpoints;
  final Value<int> position;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> positionAt;
  final Value<bool> deleted;
  final Value<DateTime?> deletedChangedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const WorksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.kind = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.checkpoints = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.positionAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.deletedChangedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorksCompanion.insert({
    required String id,
    required String title,
    required String author,
    this.kind = const Value.absent(),
    required int totalPages,
    required String checkpoints,
    this.position = const Value.absent(),
    required DateTime updatedAt,
    this.positionAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.deletedChangedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       author = Value(author),
       totalPages = Value(totalPages),
       checkpoints = Value(checkpoints),
       updatedAt = Value(updatedAt);
  static Insertable<WorkRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? kind,
    Expression<int>? totalPages,
    Expression<String>? checkpoints,
    Expression<int>? position,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? positionAt,
    Expression<bool>? deleted,
    Expression<DateTime>? deletedChangedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (kind != null) 'kind': kind,
      if (totalPages != null) 'total_pages': totalPages,
      if (checkpoints != null) 'checkpoints': checkpoints,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (positionAt != null) 'position_at': positionAt,
      if (deleted != null) 'deleted': deleted,
      if (deletedChangedAt != null) 'deleted_changed_at': deletedChangedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? author,
    Value<WorkKind>? kind,
    Value<int>? totalPages,
    Value<String>? checkpoints,
    Value<int>? position,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? positionAt,
    Value<bool>? deleted,
    Value<DateTime?>? deletedChangedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return WorksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      totalPages: totalPages ?? this.totalPages,
      checkpoints: checkpoints ?? this.checkpoints,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      positionAt: positionAt ?? this.positionAt,
      deleted: deleted ?? this.deleted,
      deletedChangedAt: deletedChangedAt ?? this.deletedChangedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $WorksTable.$converterkind.toSql(kind.value),
      );
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (checkpoints.present) {
      map['checkpoints'] = Variable<String>(checkpoints.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (positionAt.present) {
      map['position_at'] = Variable<DateTime>(positionAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (deletedChangedAt.present) {
      map['deleted_changed_at'] = Variable<DateTime>(deletedChangedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('totalPages: $totalPages, ')
          ..write('checkpoints: $checkpoints, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('positionAt: $positionAt, ')
          ..write('deleted: $deleted, ')
          ..write('deletedChangedAt: $deletedChangedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionEventsTable extends SessionEvents
    with TableInfo<$SessionEventsTable, SessionEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionEventKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionEventKind>($SessionEventsTable.$converterkind);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    workId,
    kind,
    at,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      kind: $SessionEventsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $SessionEventsTable createAlias(String alias) {
    return $SessionEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionEventKind, String, String> $converterkind =
      const EnumNameConverter<SessionEventKind>(SessionEventKind.values);
}

class SessionEventRow extends DataClass implements Insertable<SessionEventRow> {
  final String id;
  final String sessionId;
  final String workId;
  final SessionEventKind kind;
  final DateTime at;

  /// Whether the sync server has it.
  final bool synced;
  const SessionEventRow({
    required this.id,
    required this.sessionId,
    required this.workId,
    required this.kind,
    required this.at,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['work_id'] = Variable<String>(workId);
    {
      map['kind'] = Variable<String>(
        $SessionEventsTable.$converterkind.toSql(kind),
      );
    }
    map['at'] = Variable<DateTime>(at);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  SessionEventsCompanion toCompanion(bool nullToAbsent) {
    return SessionEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      workId: Value(workId),
      kind: Value(kind),
      at: Value(at),
      synced: Value(synced),
    );
  }

  factory SessionEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionEventRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      workId: serializer.fromJson<String>(json['workId']),
      kind: $SessionEventsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      at: serializer.fromJson<DateTime>(json['at']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'workId': serializer.toJson<String>(workId),
      'kind': serializer.toJson<String>(
        $SessionEventsTable.$converterkind.toJson(kind),
      ),
      'at': serializer.toJson<DateTime>(at),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  SessionEventRow copyWith({
    String? id,
    String? sessionId,
    String? workId,
    SessionEventKind? kind,
    DateTime? at,
    bool? synced,
  }) => SessionEventRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    workId: workId ?? this.workId,
    kind: kind ?? this.kind,
    at: at ?? this.at,
    synced: synced ?? this.synced,
  );
  SessionEventRow copyWithCompanion(SessionEventsCompanion data) {
    return SessionEventRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      workId: data.workId.present ? data.workId.value : this.workId,
      kind: data.kind.present ? data.kind.value : this.kind,
      at: data.at.present ? data.at.value : this.at,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionEventRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('workId: $workId, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, workId, kind, at, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionEventRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.workId == this.workId &&
          other.kind == this.kind &&
          other.at == this.at &&
          other.synced == this.synced);
}

class SessionEventsCompanion extends UpdateCompanion<SessionEventRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> workId;
  final Value<SessionEventKind> kind;
  final Value<DateTime> at;
  final Value<bool> synced;
  final Value<int> rowid;
  const SessionEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.workId = const Value.absent(),
    this.kind = const Value.absent(),
    this.at = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionEventsCompanion.insert({
    required String id,
    required String sessionId,
    required String workId,
    required SessionEventKind kind,
    required DateTime at,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       workId = Value(workId),
       kind = Value(kind),
       at = Value(at);
  static Insertable<SessionEventRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? workId,
    Expression<String>? kind,
    Expression<DateTime>? at,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (workId != null) 'work_id': workId,
      if (kind != null) 'kind': kind,
      if (at != null) 'at': at,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? workId,
    Value<SessionEventKind>? kind,
    Value<DateTime>? at,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return SessionEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      workId: workId ?? this.workId,
      kind: kind ?? this.kind,
      at: at ?? this.at,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SessionEventsTable.$converterkind.toSql(kind.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('workId: $workId, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromPageMeta = const VerificationMeta(
    'fromPage',
  );
  @override
  late final GeneratedColumn<int> fromPage = GeneratedColumn<int>(
    'from_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toPageMeta = const VerificationMeta('toPage');
  @override
  late final GeneratedColumn<int> toPage = GeneratedColumn<int>(
    'to_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    workId,
    fromPage,
    toPage,
    body,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('from_page')) {
      context.handle(
        _fromPageMeta,
        fromPage.isAcceptableOrUnknown(data['from_page']!, _fromPageMeta),
      );
    } else if (isInserting) {
      context.missing(_fromPageMeta);
    }
    if (data.containsKey('to_page')) {
      context.handle(
        _toPageMeta,
        toPage.isAcceptableOrUnknown(data['to_page']!, _toPageMeta),
      );
    } else if (isInserting) {
      context.missing(_toPageMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      fromPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_page'],
      )!,
      toPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_page'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;
  final String sessionId;
  final String workId;
  final int fromPage;
  final int toPage;
  final String body;
  final DateTime updatedAt;

  /// As for Works: the [updatedAt] the sync server last saw.
  final DateTime? syncedAt;
  const NoteRow({
    required this.id,
    required this.sessionId,
    required this.workId,
    required this.fromPage,
    required this.toPage,
    required this.body,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['work_id'] = Variable<String>(workId);
    map['from_page'] = Variable<int>(fromPage);
    map['to_page'] = Variable<int>(toPage);
    map['body'] = Variable<String>(body);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      workId: Value(workId),
      fromPage: Value(fromPage),
      toPage: Value(toPage),
      body: Value(body),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      workId: serializer.fromJson<String>(json['workId']),
      fromPage: serializer.fromJson<int>(json['fromPage']),
      toPage: serializer.fromJson<int>(json['toPage']),
      body: serializer.fromJson<String>(json['body']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'workId': serializer.toJson<String>(workId),
      'fromPage': serializer.toJson<int>(fromPage),
      'toPage': serializer.toJson<int>(toPage),
      'body': serializer.toJson<String>(body),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  NoteRow copyWith({
    String? id,
    String? sessionId,
    String? workId,
    int? fromPage,
    int? toPage,
    String? body,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => NoteRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    workId: workId ?? this.workId,
    fromPage: fromPage ?? this.fromPage,
    toPage: toPage ?? this.toPage,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      workId: data.workId.present ? data.workId.value : this.workId,
      fromPage: data.fromPage.present ? data.fromPage.value : this.fromPage,
      toPage: data.toPage.present ? data.toPage.value : this.toPage,
      body: data.body.present ? data.body.value : this.body,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('workId: $workId, ')
          ..write('fromPage: $fromPage, ')
          ..write('toPage: $toPage, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    workId,
    fromPage,
    toPage,
    body,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.workId == this.workId &&
          other.fromPage == this.fromPage &&
          other.toPage == this.toPage &&
          other.body == this.body &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> workId;
  final Value<int> fromPage;
  final Value<int> toPage;
  final Value<String> body;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.workId = const Value.absent(),
    this.fromPage = const Value.absent(),
    this.toPage = const Value.absent(),
    this.body = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String sessionId,
    required String workId,
    required int fromPage,
    required int toPage,
    required String body,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       workId = Value(workId),
       fromPage = Value(fromPage),
       toPage = Value(toPage),
       body = Value(body),
       updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? workId,
    Expression<int>? fromPage,
    Expression<int>? toPage,
    Expression<String>? body,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (workId != null) 'work_id': workId,
      if (fromPage != null) 'from_page': fromPage,
      if (toPage != null) 'to_page': toPage,
      if (body != null) 'body': body,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? workId,
    Value<int>? fromPage,
    Value<int>? toPage,
    Value<String>? body,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      workId: workId ?? this.workId,
      fromPage: fromPage ?? this.fromPage,
      toPage: toPage ?? this.toPage,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (fromPage.present) {
      map['from_page'] = Variable<int>(fromPage.value);
    }
    if (toPage.present) {
      map['to_page'] = Variable<int>(toPage.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('workId: $workId, ')
          ..write('fromPage: $fromPage, ')
          ..write('toPage: $toPage, ')
          ..write('body: $body, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $WorksTable works = $WorksTable(this);
  late final $SessionEventsTable sessionEvents = $SessionEventsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    works,
    sessionEvents,
    notes,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$WorksTableCreateCompanionBuilder = WorksCompanion Function({
  required String id,
  required String title,
  required String author,
  Value<WorkKind> kind,
  required int totalPages,
  required String checkpoints,
  Value<int> position,
  required DateTime updatedAt,
  Value<DateTime?> positionAt,
  Value<bool> deleted,
  Value<DateTime?> deletedChangedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$WorksTableUpdateCompanionBuilder = WorksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> author,
  Value<WorkKind> kind,
  Value<int> totalPages,
  Value<String> checkpoints,
  Value<int> position,
  Value<DateTime> updatedAt,
  Value<DateTime?> positionAt,
  Value<bool> deleted,
  Value<DateTime?> deletedChangedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$WorksTableFilterComposer extends Composer<_$AppDatabase, $WorksTable> {
  $$WorksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkKind, WorkKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkpoints => $composableBuilder(
    column: $table.checkpoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get positionAt => $composableBuilder(
    column: $table.positionAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedChangedAt => $composableBuilder(
    column: $table.deletedChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorksTableOrderingComposer
    extends Composer<_$AppDatabase, $WorksTable> {
  $$WorksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkpoints => $composableBuilder(
    column: $table.checkpoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get positionAt => $composableBuilder(
    column: $table.positionAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedChangedAt => $composableBuilder(
    column: $table.deletedChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorksTable> {
  $$WorksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkpoints => $composableBuilder(
    column: $table.checkpoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get positionAt => $composableBuilder(
    column: $table.positionAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedChangedAt => $composableBuilder(
    column: $table.deletedChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$WorksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorksTable,
          WorkRow,
          $$WorksTableFilterComposer,
          $$WorksTableOrderingComposer,
          $$WorksTableAnnotationComposer,
          $$WorksTableCreateCompanionBuilder,
          $$WorksTableUpdateCompanionBuilder,
          (WorkRow, BaseReferences<_$AppDatabase, $WorksTable, WorkRow>),
          WorkRow,
          PrefetchHooks Function()
        > {
  $$WorksTableTableManager(_$AppDatabase db, $WorksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<WorkKind> kind = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<String> checkpoints = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> positionAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime?> deletedChangedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorksCompanion(
                id: id,
                title: title,
                author: author,
                kind: kind,
                totalPages: totalPages,
                checkpoints: checkpoints,
                position: position,
                updatedAt: updatedAt,
                positionAt: positionAt,
                deleted: deleted,
                deletedChangedAt: deletedChangedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String author,
                Value<WorkKind> kind = const Value.absent(),
                required int totalPages,
                required String checkpoints,
                Value<int> position = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> positionAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime?> deletedChangedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorksCompanion.insert(
                id: id,
                title: title,
                author: author,
                kind: kind,
                totalPages: totalPages,
                checkpoints: checkpoints,
                position: position,
                updatedAt: updatedAt,
                positionAt: positionAt,
                deleted: deleted,
                deletedChangedAt: deletedChangedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorksTable, WorkRow>(table),
                  BaseReferences<_$AppDatabase, $WorksTable, WorkRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorksTable,
      WorkRow,
      $$WorksTableFilterComposer,
      $$WorksTableOrderingComposer,
      $$WorksTableAnnotationComposer,
      $$WorksTableCreateCompanionBuilder,
      $$WorksTableUpdateCompanionBuilder,
      (WorkRow, BaseReferences<_$AppDatabase, $WorksTable, WorkRow>),
      WorkRow,
      PrefetchHooks Function()
    >;
typedef $$SessionEventsTableCreateCompanionBuilder =
    SessionEventsCompanion Function({
      required String id,
      required String sessionId,
      required String workId,
      required SessionEventKind kind,
      required DateTime at,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$SessionEventsTableUpdateCompanionBuilder =
    SessionEventsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> workId,
      Value<SessionEventKind> kind,
      Value<DateTime> at,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$SessionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionEventsTable> {
  $$SessionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workId => $composableBuilder(
    column: $table.workId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionEventKind, SessionEventKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionEventsTable> {
  $$SessionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workId => $composableBuilder(
    column: $table.workId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionEventsTable> {
  $$SessionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get workId =>
      $composableBuilder(column: $table.workId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionEventKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$SessionEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionEventsTable,
          SessionEventRow,
          $$SessionEventsTableFilterComposer,
          $$SessionEventsTableOrderingComposer,
          $$SessionEventsTableAnnotationComposer,
          $$SessionEventsTableCreateCompanionBuilder,
          $$SessionEventsTableUpdateCompanionBuilder,
          (
            SessionEventRow,
            BaseReferences<_$AppDatabase, $SessionEventsTable, SessionEventRow>,
          ),
          SessionEventRow,
          PrefetchHooks Function()
        > {
  $$SessionEventsTableTableManager(_$AppDatabase db, $SessionEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<SessionEventKind> kind = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionEventsCompanion(
                id: id,
                sessionId: sessionId,
                workId: workId,
                kind: kind,
                at: at,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String workId,
                required SessionEventKind kind,
                required DateTime at,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionEventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                workId: workId,
                kind: kind,
                at: at,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionEventsTable, SessionEventRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SessionEventsTable,
                    SessionEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionEventsTable,
      SessionEventRow,
      $$SessionEventsTableFilterComposer,
      $$SessionEventsTableOrderingComposer,
      $$SessionEventsTableAnnotationComposer,
      $$SessionEventsTableCreateCompanionBuilder,
      $$SessionEventsTableUpdateCompanionBuilder,
      (
        SessionEventRow,
        BaseReferences<_$AppDatabase, $SessionEventsTable, SessionEventRow>,
      ),
      SessionEventRow,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  required String sessionId,
  required String workId,
  required int fromPage,
  required int toPage,
  required String body,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> workId,
  Value<int> fromPage,
  Value<int> toPage,
  Value<String> body,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workId => $composableBuilder(
    column: $table.workId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromPage => $composableBuilder(
    column: $table.fromPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toPage => $composableBuilder(
    column: $table.toPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workId => $composableBuilder(
    column: $table.workId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromPage => $composableBuilder(
    column: $table.fromPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toPage => $composableBuilder(
    column: $table.toPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get workId =>
      $composableBuilder(column: $table.workId, builder: (column) => column);

  GeneratedColumn<int> get fromPage =>
      $composableBuilder(column: $table.fromPage, builder: (column) => column);

  GeneratedColumn<int> get toPage =>
      $composableBuilder(column: $table.toPage, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<int> fromPage = const Value.absent(),
                Value<int> toPage = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                sessionId: sessionId,
                workId: workId,
                fromPage: fromPage,
                toPage: toPage,
                body: body,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String workId,
                required int fromPage,
                required int toPage,
                required String body,
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                sessionId: sessionId,
                workId: workId,
                fromPage: fromPage,
                toPage: toPage,
                body: body,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, NoteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$WorksTableTableManager get works =>
      $$WorksTableTableManager(_db, _db.works);
  $$SessionEventsTableTableManager get sessionEvents =>
      $$SessionEventsTableTableManager(_db, _db.sessionEvents);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
}
