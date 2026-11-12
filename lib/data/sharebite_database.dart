import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class ShareBiteDatabase {
  ShareBiteDatabase._();

  static final ShareBiteDatabase instance = ShareBiteDatabase._();

  Database? _database;
  Future<void>? _opening;

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('O banco de dados SQLite ainda não foi inicializado.');
    }
    return database;
  }

  Future<void> open() async {
    if (_database != null) return;
    final pending = _opening;
    if (pending != null) return pending;

    final attempt = _open();
    _opening = attempt;
    try {
      await attempt;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<void> _open() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final path = kIsWeb
        ? 'sharebite.db'
        : p.join(await getDatabasesPath(), 'sharebite.db');
    _database = await openDatabase(
      path,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE listings (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            mode TEXT NOT NULL,
            place TEXT NOT NULL,
            distance TEXT NOT NULL,
            price TEXT NOT NULL,
            owner TEXT NOT NULL,
            description TEXT NOT NULL,
            image TEXT NOT NULL,
            accepted_categories TEXT NOT NULL,
            is_mine INTEGER NOT NULL,
            completed INTEGER NOT NULL,
            image_bytes BLOB,
            completed_at TEXT
          )
        ''');
        await database.execute('''
          CREATE TABLE saved_listings (
            listing_id TEXT PRIMARY KEY,
            FOREIGN KEY (listing_id) REFERENCES listings (id)
              ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            note TEXT NOT NULL,
            listing TEXT NOT NULL,
            image TEXT NOT NULL,
            time TEXT NOT NULL,
            icon_code_point INTEGER NOT NULL,
            position INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id TEXT NOT NULL,
            text TEXT NOT NULL,
            mine INTEGER NOT NULL,
            time TEXT NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES conversations (id)
              ON DELETE CASCADE
          )
        ''');
        await _createAccountProfileTable(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAccountProfileTable(database);
        }
      },
    );
  }

  Future<void> _createAccountProfileTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE account_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');
  }

  Future<Map<String, Object?>?> loadAccountProfile() async {
    await open();
    final rows = await _db.query(
      'account_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveAccountProfile({
    required String name,
    required String email,
  }) async {
    await open();
    await _db.insert(
      'account_profile',
      {'id': 1, 'name': name, 'email': email},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> seedIfEmpty({
    required List<Map<String, Object?>> listings,
    required List<Map<String, Object?>> conversations,
  }) async {
    await open();
    await _db.transaction((transaction) async {
      final listingCount = Sqflite.firstIntValue(
            await transaction.rawQuery('SELECT COUNT(*) FROM listings'),
          ) ??
          0;
      if (listingCount == 0) {
        for (final listing in listings) {
          await transaction.insert('listings', listing);
        }
      }

      final conversationCount = Sqflite.firstIntValue(
            await transaction.rawQuery('SELECT COUNT(*) FROM conversations'),
          ) ??
          0;
      if (conversationCount == 0) {
        for (var index = 0; index < conversations.length; index++) {
          final conversation = Map<String, Object?>.from(conversations[index]);
          final messages =
              (conversation.remove('messages')! as List<Map<String, Object?>>)
                  .toList();
          await _insertConversation(
            transaction,
            conversation,
            messages: messages,
            position: index,
          );
        }
      }
    });
  }

  Future<List<Map<String, Object?>>> loadListings() async {
    await open();
    return _db.query('listings', orderBy: 'rowid DESC');
  }

  Future<void> saveListing(Map<String, Object?> listing) async {
    await open();
    await _db.transaction((transaction) async {
      final id = listing['id']! as String;
      final updated = await transaction.update(
        'listings',
        listing,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        await transaction.insert('listings', listing);
      }
    });
  }

  Future<void> completeListing(String id, DateTime completedAt) async {
    await open();
    final updated = await _db.update(
      'listings',
      {'completed': 1, 'completed_at': completedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated != 1) {
      throw StateError('Anúncio não encontrado no banco de dados: $id');
    }
  }

  Future<Set<String>> loadSavedListingIds() async {
    await open();
    final rows = await _db.query('saved_listings');
    return rows.map((row) => row['listing_id']! as String).toSet();
  }

  Future<void> setListingSaved(String id, bool saved) async {
    await open();
    if (saved) {
      await _db.insert(
        'saved_listings',
        {'listing_id': id},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _db.delete(
        'saved_listings',
        where: 'listing_id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<Map<String, Object?>>> loadConversations() async {
    await open();
    final conversations = await _db.query(
      'conversations',
      orderBy: 'position ASC',
    );
    final result = <Map<String, Object?>>[];
    for (final conversation in conversations) {
      final messages = await _db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversation['id']],
        orderBy: 'id ASC',
      );
      result.add({...conversation, 'messages': messages});
    }
    return result;
  }

  Future<void> saveConversation(
    Map<String, Object?> conversation,
    List<Map<String, Object?>> messages,
  ) async {
    await open();
    await _db.transaction((transaction) async {
      await transaction.rawUpdate(
        'UPDATE conversations SET position = position + 1',
      );
      await _insertConversation(
        transaction,
        conversation,
        messages: messages,
        position: 0,
      );
    });
  }

  Future<void> saveMessage(
    String conversationId,
    Map<String, Object?> message,
  ) async {
    await open();
    await _db.transaction((transaction) async {
      final updated = await transaction.update(
        'conversations',
        {'time': message['time']},
        where: 'id = ?',
        whereArgs: [conversationId],
      );
      if (updated != 1) {
        throw StateError(
          'Conversa não encontrada no banco de dados: $conversationId',
        );
      }
      await transaction.insert('messages', {
        ...message,
        'conversation_id': conversationId,
      });
    });
  }

  Future<void> _insertConversation(
    Transaction transaction,
    Map<String, Object?> conversation, {
    List<Map<String, Object?>> messages = const [],
    required int position,
  }) async {
    await transaction.insert('conversations', {
      ...conversation,
      'position': position,
    });
    for (final message in messages) {
      await transaction.insert('messages', {
        ...message,
        'conversation_id': conversation['id'],
      });
    }
  }
}
