import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:maltto/src/infrastructure/database/generated/local_storage_api.g.dart';
import 'package:maltto/src/infrastructure/database/migrations/schema_migration.dart';
import 'package:maltto/src/infrastructure/database/tables/scripts.dart';
import 'package:maltto/src/infrastructure/database/tutorial_script_seed.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ScriptRows])
final class AppDatabase extends _$AppDatabase {
  static final _localStorageApi = LocalStorageHostApi();

  AppDatabase(super.executor, {this._seedTutorialOnCreate = false});

  final bool _seedTutorialOnCreate;

  factory AppDatabase.open() {
    return AppDatabase(
      LazyDatabase(() async {
        final directory = await getApplicationSupportDirectory();
        if (Platform.isIOS) {
          await _localStorageApi.excludeApplicationSupportFromBackup();
        }
        final databaseFile = File(path.join(directory.path, 'maltto.sqlite'));
        return NativeDatabase.createInBackground(databaseFile);
      }),
      seedTutorialOnCreate: true,
    );
  }

  factory AppDatabase.openAt(
    File databaseFile, {
    bool seedTutorialOnCreate = true,
  }) {
    return AppDatabase(
      NativeDatabase.createInBackground(databaseFile),
      seedTutorialOnCreate: seedTutorialOnCreate,
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      if (!_seedTutorialOnCreate) return;
      final timestamp = DateTime.now().toUtc();
      await into(scriptRows).insert(
        ScriptRowsCompanion.insert(
          title: tutorialScriptTitle,
          body: tutorialScriptBody,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    },
    onUpgrade: (migrator, from, to) =>
        migrateSchema(migrator, from: from, to: to),
  );
}
