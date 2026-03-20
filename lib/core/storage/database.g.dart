// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ServersTableTable extends ServersTable
    with TableInfo<$ServersTableTable, ServerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultReadingModeMeta =
      const VerificationMeta('defaultReadingMode');
  @override
  late final GeneratedColumn<String> defaultReadingMode =
      GeneratedColumn<String>(
        'default_reading_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('single'),
      );
  static const VerificationMeta _autoDoublePageMeta = const VerificationMeta(
    'autoDoublePage',
  );
  @override
  late final GeneratedColumn<bool> autoDoublePage = GeneratedColumn<bool>(
    'auto_double_page',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_double_page" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _opdsVersionMeta = const VerificationMeta(
    'opdsVersion',
  );
  @override
  late final GeneratedColumn<String> opdsVersion = GeneratedColumn<String>(
    'opds_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    url,
    username,
    defaultReadingMode,
    autoDoublePage,
    opdsVersion,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('default_reading_mode')) {
      context.handle(
        _defaultReadingModeMeta,
        defaultReadingMode.isAcceptableOrUnknown(
          data['default_reading_mode']!,
          _defaultReadingModeMeta,
        ),
      );
    }
    if (data.containsKey('auto_double_page')) {
      context.handle(
        _autoDoublePageMeta,
        autoDoublePage.isAcceptableOrUnknown(
          data['auto_double_page']!,
          _autoDoublePageMeta,
        ),
      );
    }
    if (data.containsKey('opds_version')) {
      context.handle(
        _opdsVersionMeta,
        opdsVersion.isAcceptableOrUnknown(
          data['opds_version']!,
          _opdsVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_opdsVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      defaultReadingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_reading_mode'],
      )!,
      autoDoublePage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_double_page'],
      )!,
      opdsVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opds_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ServersTableTable createAlias(String alias) {
    return $ServersTableTable(attachedDatabase, alias);
  }
}

class ServerRecord extends DataClass implements Insertable<ServerRecord> {
  final int id;
  final String name;
  final String url;
  final String? username;
  final String defaultReadingMode;
  final bool autoDoublePage;
  final String opdsVersion;
  final DateTime createdAt;
  const ServerRecord({
    required this.id,
    required this.name,
    required this.url,
    this.username,
    required this.defaultReadingMode,
    required this.autoDoublePage,
    required this.opdsVersion,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    map['default_reading_mode'] = Variable<String>(defaultReadingMode);
    map['auto_double_page'] = Variable<bool>(autoDoublePage);
    map['opds_version'] = Variable<String>(opdsVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ServersTableCompanion toCompanion(bool nullToAbsent) {
    return ServersTableCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      defaultReadingMode: Value(defaultReadingMode),
      autoDoublePage: Value(autoDoublePage),
      opdsVersion: Value(opdsVersion),
      createdAt: Value(createdAt),
    );
  }

  factory ServerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerRecord(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String?>(json['username']),
      defaultReadingMode: serializer.fromJson<String>(
        json['defaultReadingMode'],
      ),
      autoDoublePage: serializer.fromJson<bool>(json['autoDoublePage']),
      opdsVersion: serializer.fromJson<String>(json['opdsVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String?>(username),
      'defaultReadingMode': serializer.toJson<String>(defaultReadingMode),
      'autoDoublePage': serializer.toJson<bool>(autoDoublePage),
      'opdsVersion': serializer.toJson<String>(opdsVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ServerRecord copyWith({
    int? id,
    String? name,
    String? url,
    Value<String?> username = const Value.absent(),
    String? defaultReadingMode,
    bool? autoDoublePage,
    String? opdsVersion,
    DateTime? createdAt,
  }) => ServerRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    username: username.present ? username.value : this.username,
    defaultReadingMode: defaultReadingMode ?? this.defaultReadingMode,
    autoDoublePage: autoDoublePage ?? this.autoDoublePage,
    opdsVersion: opdsVersion ?? this.opdsVersion,
    createdAt: createdAt ?? this.createdAt,
  );
  ServerRecord copyWithCompanion(ServersTableCompanion data) {
    return ServerRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      defaultReadingMode: data.defaultReadingMode.present
          ? data.defaultReadingMode.value
          : this.defaultReadingMode,
      autoDoublePage: data.autoDoublePage.present
          ? data.autoDoublePage.value
          : this.autoDoublePage,
      opdsVersion: data.opdsVersion.present
          ? data.opdsVersion.value
          : this.opdsVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('defaultReadingMode: $defaultReadingMode, ')
          ..write('autoDoublePage: $autoDoublePage, ')
          ..write('opdsVersion: $opdsVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    url,
    username,
    defaultReadingMode,
    autoDoublePage,
    opdsVersion,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.username == this.username &&
          other.defaultReadingMode == this.defaultReadingMode &&
          other.autoDoublePage == this.autoDoublePage &&
          other.opdsVersion == this.opdsVersion &&
          other.createdAt == this.createdAt);
}

class ServersTableCompanion extends UpdateCompanion<ServerRecord> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> username;
  final Value<String> defaultReadingMode;
  final Value<bool> autoDoublePage;
  final Value<String> opdsVersion;
  final Value<DateTime> createdAt;
  const ServersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.defaultReadingMode = const Value.absent(),
    this.autoDoublePage = const Value.absent(),
    this.opdsVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ServersTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String url,
    this.username = const Value.absent(),
    this.defaultReadingMode = const Value.absent(),
    this.autoDoublePage = const Value.absent(),
    required String opdsVersion,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       url = Value(url),
       opdsVersion = Value(opdsVersion);
  static Insertable<ServerRecord> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? username,
    Expression<String>? defaultReadingMode,
    Expression<bool>? autoDoublePage,
    Expression<String>? opdsVersion,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (defaultReadingMode != null)
        'default_reading_mode': defaultReadingMode,
      if (autoDoublePage != null) 'auto_double_page': autoDoublePage,
      if (opdsVersion != null) 'opds_version': opdsVersion,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ServersTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? username,
    Value<String>? defaultReadingMode,
    Value<bool>? autoDoublePage,
    Value<String>? opdsVersion,
    Value<DateTime>? createdAt,
  }) {
    return ServersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      username: username ?? this.username,
      defaultReadingMode: defaultReadingMode ?? this.defaultReadingMode,
      autoDoublePage: autoDoublePage ?? this.autoDoublePage,
      opdsVersion: opdsVersion ?? this.opdsVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (defaultReadingMode.present) {
      map['default_reading_mode'] = Variable<String>(defaultReadingMode.value);
    }
    if (autoDoublePage.present) {
      map['auto_double_page'] = Variable<bool>(autoDoublePage.value);
    }
    if (opdsVersion.present) {
      map['opds_version'] = Variable<String>(opdsVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('defaultReadingMode: $defaultReadingMode, ')
          ..write('autoDoublePage: $autoDoublePage, ')
          ..write('opdsVersion: $opdsVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReadProgressTableTable extends ReadProgressTable
    with TableInfo<$ReadProgressTableTable, ReadProgressRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationUrlMeta = const VerificationMeta(
    'publicationUrl',
  );
  @override
  late final GeneratedColumn<String> publicationUrl = GeneratedColumn<String>(
    'publication_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    publicationUrl,
    currentPage,
    totalPages,
    lastReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'read_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadProgressRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('publication_url')) {
      context.handle(
        _publicationUrlMeta,
        publicationUrl.isAcceptableOrUnknown(
          data['publication_url']!,
          _publicationUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationUrlMeta);
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadProgressRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadProgressRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      publicationUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_url'],
      )!,
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
      )!,
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      )!,
    );
  }

  @override
  $ReadProgressTableTable createAlias(String alias) {
    return $ReadProgressTableTable(attachedDatabase, alias);
  }
}

class ReadProgressRecord extends DataClass
    implements Insertable<ReadProgressRecord> {
  final int id;
  final int serverId;
  final String publicationUrl;
  final int currentPage;
  final int totalPages;
  final DateTime lastReadAt;
  const ReadProgressRecord({
    required this.id,
    required this.serverId,
    required this.publicationUrl,
    required this.currentPage,
    required this.totalPages,
    required this.lastReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['publication_url'] = Variable<String>(publicationUrl);
    map['current_page'] = Variable<int>(currentPage);
    map['total_pages'] = Variable<int>(totalPages);
    map['last_read_at'] = Variable<DateTime>(lastReadAt);
    return map;
  }

  ReadProgressTableCompanion toCompanion(bool nullToAbsent) {
    return ReadProgressTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      publicationUrl: Value(publicationUrl),
      currentPage: Value(currentPage),
      totalPages: Value(totalPages),
      lastReadAt: Value(lastReadAt),
    );
  }

  factory ReadProgressRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadProgressRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      publicationUrl: serializer.fromJson<String>(json['publicationUrl']),
      currentPage: serializer.fromJson<int>(json['currentPage']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      lastReadAt: serializer.fromJson<DateTime>(json['lastReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'publicationUrl': serializer.toJson<String>(publicationUrl),
      'currentPage': serializer.toJson<int>(currentPage),
      'totalPages': serializer.toJson<int>(totalPages),
      'lastReadAt': serializer.toJson<DateTime>(lastReadAt),
    };
  }

  ReadProgressRecord copyWith({
    int? id,
    int? serverId,
    String? publicationUrl,
    int? currentPage,
    int? totalPages,
    DateTime? lastReadAt,
  }) => ReadProgressRecord(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    publicationUrl: publicationUrl ?? this.publicationUrl,
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    lastReadAt: lastReadAt ?? this.lastReadAt,
  );
  ReadProgressRecord copyWithCompanion(ReadProgressTableCompanion data) {
    return ReadProgressRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      publicationUrl: data.publicationUrl.present
          ? data.publicationUrl.value
          : this.publicationUrl,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadProgressRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('publicationUrl: $publicationUrl, ')
          ..write('currentPage: $currentPage, ')
          ..write('totalPages: $totalPages, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    publicationUrl,
    currentPage,
    totalPages,
    lastReadAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadProgressRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.publicationUrl == this.publicationUrl &&
          other.currentPage == this.currentPage &&
          other.totalPages == this.totalPages &&
          other.lastReadAt == this.lastReadAt);
}

class ReadProgressTableCompanion extends UpdateCompanion<ReadProgressRecord> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<String> publicationUrl;
  final Value<int> currentPage;
  final Value<int> totalPages;
  final Value<DateTime> lastReadAt;
  const ReadProgressTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.publicationUrl = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  });
  ReadProgressTableCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required String publicationUrl,
    this.currentPage = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  }) : serverId = Value(serverId),
       publicationUrl = Value(publicationUrl);
  static Insertable<ReadProgressRecord> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? publicationUrl,
    Expression<int>? currentPage,
    Expression<int>? totalPages,
    Expression<DateTime>? lastReadAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (publicationUrl != null) 'publication_url': publicationUrl,
      if (currentPage != null) 'current_page': currentPage,
      if (totalPages != null) 'total_pages': totalPages,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
    });
  }

  ReadProgressTableCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<String>? publicationUrl,
    Value<int>? currentPage,
    Value<int>? totalPages,
    Value<DateTime>? lastReadAt,
  }) {
    return ReadProgressTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      publicationUrl: publicationUrl ?? this.publicationUrl,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (publicationUrl.present) {
      map['publication_url'] = Variable<String>(publicationUrl.value);
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadProgressTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('publicationUrl: $publicationUrl, ')
          ..write('currentPage: $currentPage, ')
          ..write('totalPages: $totalPages, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTableTable extends DownloadsTable
    with TableInfo<$DownloadsTableTable, DownloadRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicationUrlMeta = const VerificationMeta(
    'publicationUrl',
  );
  @override
  late final GeneratedColumn<String> publicationUrl = GeneratedColumn<String>(
    'publication_url',
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
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    publicationUrl,
    title,
    filePath,
    thumbnailUrl,
    fileSize,
    progress,
    status,
    createdAt,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('publication_url')) {
      context.handle(
        _publicationUrlMeta,
        publicationUrl.isAcceptableOrUnknown(
          data['publication_url']!,
          _publicationUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publicationUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      publicationUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publication_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
    );
  }

  @override
  $DownloadsTableTable createAlias(String alias) {
    return $DownloadsTableTable(attachedDatabase, alias);
  }
}

class DownloadRecord extends DataClass implements Insertable<DownloadRecord> {
  final int id;
  final int serverId;
  final String publicationUrl;
  final String title;
  final String? filePath;
  final String? thumbnailUrl;
  final int fileSize;
  final double progress;
  final String status;
  final DateTime createdAt;
  final DateTime? downloadedAt;
  const DownloadRecord({
    required this.id,
    required this.serverId,
    required this.publicationUrl,
    required this.title,
    this.filePath,
    this.thumbnailUrl,
    required this.fileSize,
    required this.progress,
    required this.status,
    required this.createdAt,
    this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<int>(serverId);
    map['publication_url'] = Variable<String>(publicationUrl);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['progress'] = Variable<double>(progress);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    return map;
  }

  DownloadsTableCompanion toCompanion(bool nullToAbsent) {
    return DownloadsTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      publicationUrl: Value(publicationUrl),
      title: Value(title),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      fileSize: Value(fileSize),
      progress: Value(progress),
      status: Value(status),
      createdAt: Value(createdAt),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
    );
  }

  factory DownloadRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRecord(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      publicationUrl: serializer.fromJson<String>(json['publicationUrl']),
      title: serializer.fromJson<String>(json['title']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      progress: serializer.fromJson<double>(json['progress']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int>(serverId),
      'publicationUrl': serializer.toJson<String>(publicationUrl),
      'title': serializer.toJson<String>(title),
      'filePath': serializer.toJson<String?>(filePath),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'fileSize': serializer.toJson<int>(fileSize),
      'progress': serializer.toJson<double>(progress),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
    };
  }

  DownloadRecord copyWith({
    int? id,
    int? serverId,
    String? publicationUrl,
    String? title,
    Value<String?> filePath = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    int? fileSize,
    double? progress,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> downloadedAt = const Value.absent(),
  }) => DownloadRecord(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    publicationUrl: publicationUrl ?? this.publicationUrl,
    title: title ?? this.title,
    filePath: filePath.present ? filePath.value : this.filePath,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    fileSize: fileSize ?? this.fileSize,
    progress: progress ?? this.progress,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
  );
  DownloadRecord copyWithCompanion(DownloadsTableCompanion data) {
    return DownloadRecord(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      publicationUrl: data.publicationUrl.present
          ? data.publicationUrl.value
          : this.publicationUrl,
      title: data.title.present ? data.title.value : this.title,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      progress: data.progress.present ? data.progress.value : this.progress,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRecord(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('publicationUrl: $publicationUrl, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('fileSize: $fileSize, ')
          ..write('progress: $progress, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    publicationUrl,
    title,
    filePath,
    thumbnailUrl,
    fileSize,
    progress,
    status,
    createdAt,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRecord &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.publicationUrl == this.publicationUrl &&
          other.title == this.title &&
          other.filePath == this.filePath &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.fileSize == this.fileSize &&
          other.progress == this.progress &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.downloadedAt == this.downloadedAt);
}

class DownloadsTableCompanion extends UpdateCompanion<DownloadRecord> {
  final Value<int> id;
  final Value<int> serverId;
  final Value<String> publicationUrl;
  final Value<String> title;
  final Value<String?> filePath;
  final Value<String?> thumbnailUrl;
  final Value<int> fileSize;
  final Value<double> progress;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> downloadedAt;
  const DownloadsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.publicationUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.progress = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  DownloadsTableCompanion.insert({
    this.id = const Value.absent(),
    required int serverId,
    required String publicationUrl,
    required String title,
    this.filePath = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.progress = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  }) : serverId = Value(serverId),
       publicationUrl = Value(publicationUrl),
       title = Value(title);
  static Insertable<DownloadRecord> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? publicationUrl,
    Expression<String>? title,
    Expression<String>? filePath,
    Expression<String>? thumbnailUrl,
    Expression<int>? fileSize,
    Expression<double>? progress,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (publicationUrl != null) 'publication_url': publicationUrl,
      if (title != null) 'title': title,
      if (filePath != null) 'file_path': filePath,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (fileSize != null) 'file_size': fileSize,
      if (progress != null) 'progress': progress,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  DownloadsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? serverId,
    Value<String>? publicationUrl,
    Value<String>? title,
    Value<String?>? filePath,
    Value<String?>? thumbnailUrl,
    Value<int>? fileSize,
    Value<double>? progress,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? downloadedAt,
  }) {
    return DownloadsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      publicationUrl: publicationUrl ?? this.publicationUrl,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (publicationUrl.present) {
      map['publication_url'] = Variable<String>(publicationUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('publicationUrl: $publicationUrl, ')
          ..write('title: $title, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('fileSize: $fileSize, ')
          ..write('progress: $progress, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ServersTableTable serversTable = $ServersTableTable(this);
  late final $ReadProgressTableTable readProgressTable =
      $ReadProgressTableTable(this);
  late final $DownloadsTableTable downloadsTable = $DownloadsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    serversTable,
    readProgressTable,
    downloadsTable,
  ];
}

typedef $$ServersTableTableCreateCompanionBuilder =
    ServersTableCompanion Function({
      Value<int> id,
      required String name,
      required String url,
      Value<String?> username,
      Value<String> defaultReadingMode,
      Value<bool> autoDoublePage,
      required String opdsVersion,
      Value<DateTime> createdAt,
    });
typedef $$ServersTableTableUpdateCompanionBuilder =
    ServersTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> url,
      Value<String?> username,
      Value<String> defaultReadingMode,
      Value<bool> autoDoublePage,
      Value<String> opdsVersion,
      Value<DateTime> createdAt,
    });

class $$ServersTableTableFilterComposer
    extends Composer<_$AppDatabase, $ServersTableTable> {
  $$ServersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultReadingMode => $composableBuilder(
    column: $table.defaultReadingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoDoublePage => $composableBuilder(
    column: $table.autoDoublePage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opdsVersion => $composableBuilder(
    column: $table.opdsVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ServersTableTable> {
  $$ServersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultReadingMode => $composableBuilder(
    column: $table.defaultReadingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoDoublePage => $composableBuilder(
    column: $table.autoDoublePage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opdsVersion => $composableBuilder(
    column: $table.opdsVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServersTableTable> {
  $$ServersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get defaultReadingMode => $composableBuilder(
    column: $table.defaultReadingMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoDoublePage => $composableBuilder(
    column: $table.autoDoublePage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get opdsVersion => $composableBuilder(
    column: $table.opdsVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ServersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServersTableTable,
          ServerRecord,
          $$ServersTableTableFilterComposer,
          $$ServersTableTableOrderingComposer,
          $$ServersTableTableAnnotationComposer,
          $$ServersTableTableCreateCompanionBuilder,
          $$ServersTableTableUpdateCompanionBuilder,
          (
            ServerRecord,
            BaseReferences<_$AppDatabase, $ServersTableTable, ServerRecord>,
          ),
          ServerRecord,
          PrefetchHooks Function()
        > {
  $$ServersTableTableTableManager(_$AppDatabase db, $ServersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String> defaultReadingMode = const Value.absent(),
                Value<bool> autoDoublePage = const Value.absent(),
                Value<String> opdsVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ServersTableCompanion(
                id: id,
                name: name,
                url: url,
                username: username,
                defaultReadingMode: defaultReadingMode,
                autoDoublePage: autoDoublePage,
                opdsVersion: opdsVersion,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String url,
                Value<String?> username = const Value.absent(),
                Value<String> defaultReadingMode = const Value.absent(),
                Value<bool> autoDoublePage = const Value.absent(),
                required String opdsVersion,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ServersTableCompanion.insert(
                id: id,
                name: name,
                url: url,
                username: username,
                defaultReadingMode: defaultReadingMode,
                autoDoublePage: autoDoublePage,
                opdsVersion: opdsVersion,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServersTableTable,
      ServerRecord,
      $$ServersTableTableFilterComposer,
      $$ServersTableTableOrderingComposer,
      $$ServersTableTableAnnotationComposer,
      $$ServersTableTableCreateCompanionBuilder,
      $$ServersTableTableUpdateCompanionBuilder,
      (
        ServerRecord,
        BaseReferences<_$AppDatabase, $ServersTableTable, ServerRecord>,
      ),
      ServerRecord,
      PrefetchHooks Function()
    >;
typedef $$ReadProgressTableTableCreateCompanionBuilder =
    ReadProgressTableCompanion Function({
      Value<int> id,
      required int serverId,
      required String publicationUrl,
      Value<int> currentPage,
      Value<int> totalPages,
      Value<DateTime> lastReadAt,
    });
typedef $$ReadProgressTableTableUpdateCompanionBuilder =
    ReadProgressTableCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<String> publicationUrl,
      Value<int> currentPage,
      Value<int> totalPages,
      Value<DateTime> lastReadAt,
    });

class $$ReadProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReadProgressTableTable> {
  $$ReadProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicationUrl => $composableBuilder(
    column: $table.publicationUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadProgressTableTable> {
  $$ReadProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicationUrl => $composableBuilder(
    column: $table.publicationUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadProgressTableTable> {
  $$ReadProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get publicationUrl => $composableBuilder(
    column: $table.publicationUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );
}

class $$ReadProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadProgressTableTable,
          ReadProgressRecord,
          $$ReadProgressTableTableFilterComposer,
          $$ReadProgressTableTableOrderingComposer,
          $$ReadProgressTableTableAnnotationComposer,
          $$ReadProgressTableTableCreateCompanionBuilder,
          $$ReadProgressTableTableUpdateCompanionBuilder,
          (
            ReadProgressRecord,
            BaseReferences<
              _$AppDatabase,
              $ReadProgressTableTable,
              ReadProgressRecord
            >,
          ),
          ReadProgressRecord,
          PrefetchHooks Function()
        > {
  $$ReadProgressTableTableTableManager(
    _$AppDatabase db,
    $ReadProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadProgressTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> publicationUrl = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<DateTime> lastReadAt = const Value.absent(),
              }) => ReadProgressTableCompanion(
                id: id,
                serverId: serverId,
                publicationUrl: publicationUrl,
                currentPage: currentPage,
                totalPages: totalPages,
                lastReadAt: lastReadAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required String publicationUrl,
                Value<int> currentPage = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<DateTime> lastReadAt = const Value.absent(),
              }) => ReadProgressTableCompanion.insert(
                id: id,
                serverId: serverId,
                publicationUrl: publicationUrl,
                currentPage: currentPage,
                totalPages: totalPages,
                lastReadAt: lastReadAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadProgressTableTable,
      ReadProgressRecord,
      $$ReadProgressTableTableFilterComposer,
      $$ReadProgressTableTableOrderingComposer,
      $$ReadProgressTableTableAnnotationComposer,
      $$ReadProgressTableTableCreateCompanionBuilder,
      $$ReadProgressTableTableUpdateCompanionBuilder,
      (
        ReadProgressRecord,
        BaseReferences<
          _$AppDatabase,
          $ReadProgressTableTable,
          ReadProgressRecord
        >,
      ),
      ReadProgressRecord,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableTableCreateCompanionBuilder =
    DownloadsTableCompanion Function({
      Value<int> id,
      required int serverId,
      required String publicationUrl,
      required String title,
      Value<String?> filePath,
      Value<String?> thumbnailUrl,
      Value<int> fileSize,
      Value<double> progress,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> downloadedAt,
    });
typedef $$DownloadsTableTableUpdateCompanionBuilder =
    DownloadsTableCompanion Function({
      Value<int> id,
      Value<int> serverId,
      Value<String> publicationUrl,
      Value<String> title,
      Value<String?> filePath,
      Value<String?> thumbnailUrl,
      Value<int> fileSize,
      Value<double> progress,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> downloadedAt,
    });

class $$DownloadsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTableTable> {
  $$DownloadsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicationUrl => $composableBuilder(
    column: $table.publicationUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTableTable> {
  $$DownloadsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicationUrl => $composableBuilder(
    column: $table.publicationUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTableTable> {
  $$DownloadsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get publicationUrl => $composableBuilder(
    column: $table.publicationUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$DownloadsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTableTable,
          DownloadRecord,
          $$DownloadsTableTableFilterComposer,
          $$DownloadsTableTableOrderingComposer,
          $$DownloadsTableTableAnnotationComposer,
          $$DownloadsTableTableCreateCompanionBuilder,
          $$DownloadsTableTableUpdateCompanionBuilder,
          (
            DownloadRecord,
            BaseReferences<_$AppDatabase, $DownloadsTableTable, DownloadRecord>,
          ),
          DownloadRecord,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableTableManager(
    _$AppDatabase db,
    $DownloadsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> publicationUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
              }) => DownloadsTableCompanion(
                id: id,
                serverId: serverId,
                publicationUrl: publicationUrl,
                title: title,
                filePath: filePath,
                thumbnailUrl: thumbnailUrl,
                fileSize: fileSize,
                progress: progress,
                status: status,
                createdAt: createdAt,
                downloadedAt: downloadedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int serverId,
                required String publicationUrl,
                required String title,
                Value<String?> filePath = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
              }) => DownloadsTableCompanion.insert(
                id: id,
                serverId: serverId,
                publicationUrl: publicationUrl,
                title: title,
                filePath: filePath,
                thumbnailUrl: thumbnailUrl,
                fileSize: fileSize,
                progress: progress,
                status: status,
                createdAt: createdAt,
                downloadedAt: downloadedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTableTable,
      DownloadRecord,
      $$DownloadsTableTableFilterComposer,
      $$DownloadsTableTableOrderingComposer,
      $$DownloadsTableTableAnnotationComposer,
      $$DownloadsTableTableCreateCompanionBuilder,
      $$DownloadsTableTableUpdateCompanionBuilder,
      (
        DownloadRecord,
        BaseReferences<_$AppDatabase, $DownloadsTableTable, DownloadRecord>,
      ),
      DownloadRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ServersTableTableTableManager get serversTable =>
      $$ServersTableTableTableManager(_db, _db.serversTable);
  $$ReadProgressTableTableTableManager get readProgressTable =>
      $$ReadProgressTableTableTableManager(_db, _db.readProgressTable);
  $$DownloadsTableTableTableManager get downloadsTable =>
      $$DownloadsTableTableTableManager(_db, _db.downloadsTable);
}
