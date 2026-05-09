import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/income_source.dart';
import '../models/ledger_entry.dart';
import '../models/bill_template.dart';
import '../models/income_template.dart';
import '../models/transfer_template.dart';
import '../models/goal.dart';
import 'notification_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ledger.db');

    try {
      if (await File(path).exists()) {
        final preOpen = await openReadOnlyDatabase(path);
        final storedVersion = await preOpen.getVersion();
        await preOpen.close();
        if (storedVersion < 17 && storedVersion > 0) {
          final docs = await getApplicationDocumentsDirectory();
          final stamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
          final backupPath = join(
            docs.path,
            'kovira_backup_pre_v${storedVersion}_$stamp.db',
          );
          await File(path).copy(backupPath);
        }
      }
    } catch (_) {}

    return openDatabase(
      path,
      version: 17,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL, useCount INTEGER NOT NULL DEFAULT 0, color INTEGER
        )''');
        await db.execute('''CREATE TABLE income_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL DEFAULT '💰',
          color INTEGER NOT NULL DEFAULT 4283215696, balance INTEGER NOT NULL DEFAULT 0,
          monthlyStart INTEGER NOT NULL DEFAULT 0, archived INTEGER NOT NULL DEFAULT 0
        )''');
        await db.execute('''CREATE TABLE income_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL,
          sourceId INTEGER NOT NULL, amount INTEGER NOT NULL DEFAULT 0, isFixed INTEGER NOT NULL DEFAULT 1,
          reminderDay INTEGER, cadence TEXT NOT NULL DEFAULT 'monthly'
        )''');
        await db.execute('''CREATE TABLE ledger_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, categoryId INTEGER NOT NULL,
          sourceId INTEGER NOT NULL DEFAULT 1, toSourceId INTEGER, amount INTEGER NOT NULL,
          paidAmount INTEGER NOT NULL DEFAULT 0, name TEXT NOT NULL, date TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'paid',
          linkedDueId INTEGER, billTemplateId INTEGER, linkedTransferId INTEGER
        )''');
        await db.execute('''CREATE TABLE category_suggestions (
          id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER NOT NULL, text TEXT NOT NULL,
          useCount INTEGER NOT NULL, lastUsedAt TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE bill_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL,
          categoryId INTEGER NOT NULL, sourceId INTEGER NOT NULL, amount INTEGER NOT NULL DEFAULT 0,
          isFixed INTEGER NOT NULL DEFAULT 1
        )''');
        await db.execute('''CREATE TABLE transfer_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fromSourceId INTEGER NOT NULL,
          toSourceId INTEGER NOT NULL,
          amount INTEGER NOT NULL DEFAULT 0,
          isFixed INTEGER NOT NULL DEFAULT 1,
          reminderDay INTEGER,
          feeCents INTEGER NOT NULL DEFAULT 0,
          feePercentBps INTEGER NOT NULL DEFAULT 0,
          name TEXT NOT NULL DEFAULT ''
        )''');
        await db.execute('''CREATE TABLE category_budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          categoryId INTEGER NOT NULL UNIQUE,
          monthlyLimit INTEGER NOT NULL DEFAULT 0
        )''');
        await db.execute('''CREATE TABLE goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT NOT NULL DEFAULT '🎯',
          color INTEGER NOT NULL DEFAULT 4283215696,
          targetAmount INTEGER NOT NULL DEFAULT 0,
          savedAmount INTEGER NOT NULL DEFAULT 0,
          targetDate TEXT,
          createdAt TEXT NOT NULL,
          archived INTEGER NOT NULL DEFAULT 0,
          inactive INTEGER NOT NULL DEFAULT 0
        )''');

        await db.execute('''CREATE TABLE category_budget_months (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          categoryId INTEGER NOT NULL,
          yearMonth TEXT NOT NULL,
          monthlyLimit INTEGER NOT NULL,
          UNIQUE(categoryId, yearMonth)
        )''');
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS app_meta (key TEXT PRIMARY KEY, value TEXT)''',
        );
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          try {
            await db.execute(
              "ALTER TABLE income_sources ADD COLUMN icon TEXT NOT NULL DEFAULT '💰'",
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE income_sources ADD COLUMN color INTEGER NOT NULL DEFAULT 4283215696',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE income_sources ADD COLUMN balance INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE income_sources ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          final sources = await db.query('income_sources');
          for (final s in sources) {
            await db.update(
              'income_sources',
              {'balance': (s['monthlyAmount'] as int?) ?? 0},
              where: 'id = ?',
              whereArgs: [s['id']],
            );
          }
          try {
            await db.execute(
              'ALTER TABLE ledger_entries ADD COLUMN sourceId INTEGER NOT NULL DEFAULT 1',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE ledger_entries ADD COLUMN toSourceId INTEGER',
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE ledger_entries ADD COLUMN status TEXT NOT NULL DEFAULT 'paid'",
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE ledger_entries ADD COLUMN paidAmount INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          final firstSource = await db.query('income_sources', limit: 1);
          if (firstSource.isNotEmpty) {
            await db.update('ledger_entries', {
              'sourceId': firstSource.first['id'] as int,
            });
          }
        }
        if (oldVersion < 5) {
          try {
            await db.execute(
              'ALTER TABLE income_sources ADD COLUMN monthlyStart INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await db.execute('''CREATE TABLE income_templates (
              id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL,
              sourceId INTEGER NOT NULL, amount INTEGER NOT NULL DEFAULT 0, isFixed INTEGER NOT NULL DEFAULT 1,
              reminderDay INTEGER
            )''');
          } catch (_) {}
        }
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE categories ADD COLUMN color INTEGER');
          } catch (_) {}
        }
        if (oldVersion < 8) {
          try {
            await db.update(
              'categories',
              {'name': 'General'},
              where: 'name = ?',
              whereArgs: ['Uncategorized'],
            );
          } catch (_) {}

          try {
            final res = await db.query(
              'categories',
              where: 'name = ?',
              whereArgs: ['General'],
              limit: 1,
            );
            if (res.isEmpty) {
              await db.insert('categories', {
                'name': 'General',
                'icon': '📦',
                'useCount': 0,
              });
            }
          } catch (_) {}

          try {
            final res = await db.query(
              'categories',
              where: 'name = ?',
              whereArgs: ['Bills'],
              limit: 1,
            );
            if (res.isEmpty) {
              await db.insert('categories', {
                'name': 'Bills',
                'icon': '🧾',
                'useCount': 0,
              });
            }
          } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute(
              'ALTER TABLE income_templates ADD COLUMN reminderDay INTEGER',
            );
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
              'ALTER TABLE categories ADD COLUMN useCount INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await db.execute('''CREATE TABLE bill_templates (
              id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL,
              categoryId INTEGER NOT NULL, sourceId INTEGER NOT NULL, amount INTEGER NOT NULL DEFAULT 0,
              isFixed INTEGER NOT NULL DEFAULT 1
            )''');
          } catch (_) {}
        }
        if (oldVersion < 9) {
          try {
            await db.execute(
              'UPDATE income_sources SET balance = balance * 100',
            );
          } catch (_) {}
          try {
            await db.execute(
              'UPDATE income_sources SET monthlyStart = monthlyStart * 100',
            );
          } catch (_) {}
          try {
            await db.execute(
              'UPDATE income_templates SET amount = amount * 100',
            );
          } catch (_) {}
          try {
            await db.execute('UPDATE ledger_entries SET amount = amount * 100');
          } catch (_) {}
          try {
            await db.execute(
              'UPDATE ledger_entries SET paidAmount = paidAmount * 100',
            );
          } catch (_) {}
          try {
            await db.execute('UPDATE bill_templates SET amount = amount * 100');
          } catch (_) {}

          try {
            await db.execute('''CREATE TABLE IF NOT EXISTS app_meta (
              key TEXT PRIMARY KEY, value TEXT)''');
            await db.insert('app_meta', {
              'key': 'decimal_migrated_at',
              'value': DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } catch (_) {}
        }
        if (oldVersion < 10) {
          try {
            await db.execute('''CREATE TABLE IF NOT EXISTS transfer_templates (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fromSourceId INTEGER NOT NULL,
              toSourceId INTEGER NOT NULL,
              amount INTEGER NOT NULL DEFAULT 0,
              isFixed INTEGER NOT NULL DEFAULT 1,
              reminderDay INTEGER
            )''');
          } catch (_) {}
        }
        if (oldVersion < 11) {
          try {
            await db.execute('''CREATE TABLE IF NOT EXISTS category_budgets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              categoryId INTEGER NOT NULL UNIQUE,
              monthlyLimit INTEGER NOT NULL DEFAULT 0
            )''');
          } catch (_) {}
        }
        if (oldVersion < 12) {
          try {
            await db.execute('''CREATE TABLE IF NOT EXISTS goals (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              icon TEXT NOT NULL DEFAULT '🎯',
              color INTEGER NOT NULL DEFAULT 4283215696,
              targetAmount INTEGER NOT NULL DEFAULT 0,
              savedAmount INTEGER NOT NULL DEFAULT 0,
              targetDate TEXT,
              createdAt TEXT NOT NULL
            )''');
          } catch (_) {}
        }
        if (oldVersion < 13) {
          try {
            await db.execute(
              'ALTER TABLE goals ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              '''CREATE TABLE IF NOT EXISTS category_budget_months (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              categoryId INTEGER NOT NULL,
              yearMonth TEXT NOT NULL,
              monthlyLimit INTEGER NOT NULL,
              UNIQUE(categoryId, yearMonth)
            )''',
            );
          } catch (_) {}
        }
        if (oldVersion < 14) {
          try {
            await db.execute(
              'ALTER TABLE goals ADD COLUMN inactive INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
        }
        if (oldVersion < 15) {
          try {
            await db.execute(
              "ALTER TABLE income_templates ADD COLUMN cadence TEXT NOT NULL DEFAULT 'monthly'",
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE transfer_templates ADD COLUMN feeCents INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE transfer_templates ADD COLUMN feePercentBps INTEGER NOT NULL DEFAULT 0',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE ledger_entries ADD COLUMN linkedDueId INTEGER',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE ledger_entries ADD COLUMN billTemplateId INTEGER',
            );
          } catch (_) {}
        }
        if (oldVersion < 16) {
          try {
            await db.execute(
              "ALTER TABLE transfer_templates ADD COLUMN name TEXT NOT NULL DEFAULT ''",
            );
          } catch (_) {}
        }
        if (oldVersion < 17) {
          try {
            await db.execute(
              'ALTER TABLE ledger_entries ADD COLUMN linkedTransferId INTEGER',
            );
          } catch (_) {}
          try {
            await db.update(
              'categories',
              {'name': 'Transfer fees'},
              where: 'name = ?',
              whereArgs: ['Fees'],
            );
          } catch (_) {}
        }
      },
    );
  }

  Future<Category> getOrCreateTransferFeesCategory() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: ['Transfer fees'],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return Category.fromMap(rows.first);
    }
    final id = await db.insert('categories', {
      'name': 'Transfer fees',
      'icon': '💸',
      'useCount': 0,
      'color': null,
    });
    return Category(id: id, name: 'Transfer fees', icon: '💸', useCount: 0);
  }

  Future<int> getBudgetForCategory(int categoryId) async {
    final db = await database;
    final rows = await db.query(
      'category_budgets',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['monthlyLimit'] as int?) ?? 0;
  }

  Future<void> setBudgetForCategory(int categoryId, int cents) async {
    final db = await database;
    if (cents <= 0) {
      await db.delete(
        'category_budgets',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
      );
      return;
    }
    await db.insert('category_budgets', {
      'categoryId': categoryId,
      'monthlyLimit': cents,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<int, int>> getAllBudgets() async {
    final db = await database;
    final rows = await db.query('category_budgets');
    return {
      for (final r in rows)
        (r['categoryId'] as int): (r['monthlyLimit'] as int),
    };
  }

  Future<int> getEffectiveBudget(int categoryId, DateTime month) async {
    final ym = _yearMonth(month);
    final db = await database;
    final overrides = await db.query(
      'category_budget_months',
      where: 'categoryId = ? AND yearMonth = ?',
      whereArgs: [categoryId, ym],
      limit: 1,
    );
    if (overrides.isNotEmpty) {
      return (overrides.first['monthlyLimit'] as int?) ?? 0;
    }
    return getBudgetForCategory(categoryId);
  }

  Future<void> setMonthOverride(
    int categoryId,
    DateTime month,
    int cents,
  ) async {
    final ym = _yearMonth(month);
    final db = await database;
    if (cents <= 0) {
      await db.delete(
        'category_budget_months',
        where: 'categoryId = ? AND yearMonth = ?',
        whereArgs: [categoryId, ym],
      );
      return;
    }
    await db.insert('category_budget_months', {
      'categoryId': categoryId,
      'yearMonth': ym,
      'monthlyLimit': cents,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static String _yearMonth(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  // ── Goals ─────────────────────────────────────────────────────────────────
  /// Active goals only (archived rows hidden) by default. Pass
  /// [includeArchived] to get the full list.
  Future<List<Goal>> getGoals({bool includeArchived = false}) async {
    final db = await database;
    final rows = await db.query(
      'goals',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'createdAt DESC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  Future<void> setGoalArchived(int id, bool archived) async {
    final db = await database;

    await db.update(
      'goals',
      {'archived': archived ? 1 : 0, if (archived) 'inactive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setGoalInactive(int id, bool inactive) async {
    final db = await database;
    await db.update(
      'goals',
      {'inactive': inactive ? 1 : 0, if (inactive) 'archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> addGoal(Goal g) async {
    final db = await database;
    return db.insert('goals', g.toMap()..remove('id'));
  }

  Future<void> updateGoal(Goal g) async {
    final db = await database;
    await db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> contributeToGoal(int id, int deltaCents, {int? sourceId}) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'goals',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final cur = (rows.first['savedAmount'] as int?) ?? 0;
      final target = (rows.first['targetAmount'] as int?) ?? 0;
      final wasArchived = ((rows.first['archived'] as int?) ?? 0) != 0;
      final next = (cur + deltaCents).clamp(0, 1 << 62);
      final shouldArchive = !wasArchived && target > 0 && next >= target;
      await txn.update(
        'goals',
        {
          'savedAmount': next,
          if (shouldArchive) 'archived': 1,
          if (shouldArchive) 'inactive': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (sourceId != null) {
        final src = await txn.query(
          'income_sources',
          where: 'id = ?',
          whereArgs: [sourceId],
          limit: 1,
        );
        if (src.isNotEmpty) {
          final cur = (src.first['balance'] as int?) ?? 0;
          await txn.update(
            'income_sources',
            {'balance': cur - deltaCents},
            where: 'id = ?',
            whereArgs: [sourceId],
          );
        }
      }
    });
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('categories', {
      'name': 'General',
      'icon': '📦',
      'useCount': 0,
    });
    await db.insert('categories', {
      'name': 'Bills',
      'icon': '🧾',
      'useCount': 0,
    });
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    return (await db.query(
      'categories',
      orderBy: 'id ASC',
    )).map((e) => Category.fromMap(e)).toList();
  }

  Future<List<Category>> getCategoriesByUsage() async {
    final db = await database;
    return (await db.query(
      'categories',
      orderBy: 'useCount DESC',
    )).map((e) => Category.fromMap(e)).toList();
  }

  Future<void> incrementCategoryUse(int categoryId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE categories SET useCount = useCount + 1 WHERE id = ?',
      [categoryId],
    );
  }

  Future<int> updateCategoryNameIcon(int id, String name, String icon) async {
    final db = await database;
    return db.update(
      'categories',
      {'name': name, 'icon': icon},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCategory(Category c) async {
    final db = await database;
    return db.insert('categories', c.toMap());
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    final cat = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (cat.isEmpty) return;
    if (cat.first['name'] == 'General' || cat.first['name'] == 'Bills') {
      throw Exception('CANNOT_DELETE_DEFAULT_CATEGORY');
    }
    final used = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ledger_entries WHERE categoryId = ?',
        [categoryId],
      ),
    );
    if ((used ?? 0) > 0) throw Exception('CATEGORY_IN_USE');
    await db.delete(
      'category_suggestions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<void> deleteCategoryAndReassign({
    required int fromCategoryId,
    required int toCategoryId,
  }) async {
    final db = await database;
    final cat = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [fromCategoryId],
      limit: 1,
    );
    if (cat.isEmpty) return;
    if (cat.first['name'] == 'General' || cat.first['name'] == 'Bills') {
      throw Exception('CANNOT_DELETE_DEFAULT_CATEGORY');
    }
    await db.update(
      'ledger_entries',
      {'categoryId': toCategoryId},
      where: 'categoryId = ?',
      whereArgs: [fromCategoryId],
    );
    await db.delete(
      'category_suggestions',
      where: 'categoryId = ?',
      whereArgs: [fromCategoryId],
    );
    await db.delete('categories', where: 'id = ?', whereArgs: [fromCategoryId]);
  }

  Future<List<IncomeSource>> getActiveSources() async {
    final db = await database;
    return (await db.query(
      'income_sources',
      where: 'archived = 0',
      orderBy: 'id ASC',
    )).map((e) => IncomeSource.fromMap(e)).toList();
  }

  Future<List<IncomeSource>> getAllSources() async {
    final db = await database;
    return (await db.query(
      'income_sources',
      orderBy: 'id ASC',
    )).map((e) => IncomeSource.fromMap(e)).toList();
  }

  Future<int> addIncomeSource(
    String name,
    String icon,
    int color,
    int balance,
  ) async {
    final db = await database;
    return db.insert('income_sources', {
      'name': name.trim(),
      'icon': icon,
      'color': color,
      'balance': balance,
      'archived': 0,
    });
  }

  Future<void> updateIncomeSource(
    int id,
    String name,
    String icon,
    int color,
  ) async {
    final db = await database;
    await db.update(
      'income_sources',
      {'name': name.trim(), 'icon': icon, 'color': color},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSourceBalance(int sourceId, int newBalance) async {
    final db = await database;
    await db.update(
      'income_sources',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [sourceId],
    );
  }

  Future<void> unarchiveSource(int id) async {
    final db = await database;
    await db.update(
      'income_sources',
      {'archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteOrArchiveSource(int id) async {
    final db = await database;
    final used = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ledger_entries WHERE sourceId = ? OR toSourceId = ?',
        [id, id],
      ),
    );
    final activeCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM income_sources WHERE archived = 0',
      ),
    );
    if ((activeCount ?? 0) <= 1) throw Exception('CANNOT_DELETE_LAST_SOURCE');
    if ((used ?? 0) > 0) {
      await db.update(
        'income_sources',
        {'archived': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      final orphanTemplates = await db.query(
        'income_templates',
        columns: ['id'],
        where: 'sourceId = ?',
        whereArgs: [id],
      );
      for (final t in orphanTemplates) {
        final tid = t['id'] as int?;
        if (tid != null) {
          try {
            await NotificationService.instance.cancelIncomeReminder(tid);
          } catch (_) {}
        }
      }

      try {
        final orphanTransfers = await db.query(
          'transfer_templates',
          columns: ['id'],
          where: 'fromSourceId = ? OR toSourceId = ?',
          whereArgs: [id, id],
        );
        for (final t in orphanTransfers) {
          final tid = t['id'] as int?;
          if (tid != null) {
            try {
              await NotificationService.instance.cancelTransferReminder(tid);
            } catch (_) {}
          }
        }
        await db.delete(
          'transfer_templates',
          where: 'fromSourceId = ? OR toSourceId = ?',
          whereArgs: [id, id],
        );
      } catch (_) {}
      await db.delete(
        'income_templates',
        where: 'sourceId = ?',
        whereArgs: [id],
      );
      await db.delete('bill_templates', where: 'sourceId = ?', whereArgs: [id]);
      await db.delete('income_sources', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> totalBalance() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT SUM(balance) as total FROM income_sources WHERE archived = 0',
    );
    return (res.first['total'] as int?) ?? 0;
  }

  Future<List<LedgerEntry>> getEntriesForMonth(DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 1).toIso8601String();
    return (await db.query(
      'ledger_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    )).map((e) => LedgerEntry.fromMap(e)).toList();
  }

  Future<List<LedgerEntry>> getEntriesForCategory(
    int categoryId,
    DateTime month,
  ) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 1).toIso8601String();
    return (await db.query(
      'ledger_entries',
      where: "categoryId = ? AND type = 'expense' AND date >= ? AND date < ?",
      whereArgs: [categoryId, start, end],
      orderBy: 'date DESC',
    )).map((e) => LedgerEntry.fromMap(e)).toList();
  }

  Future<List<LedgerEntry>> getAllEntries() async {
    final db = await database;
    return (await db.query(
      'ledger_entries',
      orderBy: 'date ASC',
    )).map((e) => LedgerEntry.fromMap(e)).toList();
  }

  Future<List<LedgerEntry>> getRecentEntries({int limit = 5}) async {
    final db = await database;
    return (await db.query(
      'ledger_entries',
      orderBy: 'id DESC',
      limit: limit,
    )).map((e) => LedgerEntry.fromMap(e)).toList();
  }

  Future<int> addExpense(LedgerEntry e) async {
    final db = await database;
    final id = await db.insert('ledger_entries', e.toMap());
    if (e.status == 'paid') await _adjustBalance(db, e.sourceId, -e.amount);
    if (e.name.trim().isNotEmpty) {
      await recordSuggestionUse(e.categoryId, e.name);
    }
    await incrementCategoryUse(e.categoryId);
    return id;
  }

  Future<int> addIncome(LedgerEntry e) async {
    final db = await database;
    final id = await db.insert('ledger_entries', e.toMap());
    await _adjustBalance(db, e.sourceId, e.amount);
    return id;
  }

  Future<int> addTransfer({
    required int fromSourceId,
    required int toSourceId,
    required int amount,
    required String name,
    required DateTime date,
  }) async {
    final db = await database;
    final entry = LedgerEntry(
      type: 'transfer',
      categoryId: 0,
      sourceId: fromSourceId,
      toSourceId: toSourceId,
      amount: amount,
      name: name,
      date: date,
    );
    final id = await db.insert('ledger_entries', entry.toMap());
    await _adjustBalance(db, fromSourceId, -amount);
    await _adjustBalance(db, toSourceId, amount);
    return id;
  }

  Future<void> payDue(int entryId, int paymentAmount, int sourceId) async {
    final db = await database;
    final rows = await db.query(
      'ledger_entries',
      where: 'id = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final entry = LedgerEntry.fromMap(rows.first);
    if (entry.status != 'due') return;
    final newPaid = entry.paidAmount + paymentAmount;
    await db.update(
      'ledger_entries',
      {
        'paidAmount': newPaid,
        'sourceId': sourceId,
        'status': newPaid >= entry.amount ? 'paid' : 'due',
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
    await _adjustBalance(db, sourceId, -paymentAmount);
  }

  Future<void> updateIncomeEntry(
    LedgerEntry original,
    LedgerEntry updated,
  ) async {
    final db = await database;
    final diff = updated.amount - original.amount;
    final map = updated.toMap()..remove('id');
    await db.update(
      'ledger_entries',
      map,
      where: 'id = ?',
      whereArgs: [original.id],
    );
    if (diff != 0) await _adjustBalance(db, updated.sourceId, diff);
  }

  Future<void> updateTransferEntry(
    LedgerEntry original,
    LedgerEntry updated,
  ) async {
    final db = await database;
    await _adjustBalance(db, original.sourceId, original.amount);
    if (original.toSourceId != null) {
      await _adjustBalance(db, original.toSourceId!, -original.amount);
    }
    await _adjustBalance(db, updated.sourceId, -updated.amount);
    if (updated.toSourceId != null) {
      await _adjustBalance(db, updated.toSourceId!, updated.amount);
    }
    final map = updated.toMap()..remove('id');
    await db.update(
      'ledger_entries',
      map,
      where: 'id = ?',
      whereArgs: [original.id],
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    final rows = await db.query(
      'ledger_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final e = LedgerEntry.fromMap(rows.first);
    if (e.type == 'expense' && e.status == 'paid') {
      await _adjustBalance(db, e.sourceId, e.amount);
    } else if (e.type == 'expense' && e.status == 'due' && e.paidAmount > 0) {
      await _adjustBalance(db, e.sourceId, e.paidAmount);
    } else if (e.type == 'income') {
      await _adjustBalance(db, e.sourceId, -e.amount);
    } else if (e.type == 'transfer') {
      await _adjustBalance(db, e.sourceId, e.amount);
      if (e.toSourceId != null) {
        await _adjustBalance(db, e.toSourceId!, -e.amount);
      }
      final linked = await db.query(
        'ledger_entries',
        where: 'linkedTransferId = ?',
        whereArgs: [id],
      );
      for (final row in linked) {
        await deleteEntry(row['id'] as int);
      }
    }
    await db.delete('ledger_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    final db = await database;

    List<Map<String, dynamic>> coerce(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final sources = coerce(data['sources']);
    final categories = coerce(data['categories']);
    final entries = coerce(data['entries']);
    final bills = coerce(data['bills']);
    final incomeTemplates = coerce(data['incomeTemplates']);
    final transferTemplates = coerce(data['transferTemplates']);
    final suggestions = coerce(data['categorySuggestions']);
    final budgets = coerce(data['categoryBudgets']);
    final budgetMonths = coerce(data['categoryBudgetMonths']);
    final goals = coerce(data['goals']);

    await db.transaction((txn) async {
      await txn.delete('ledger_entries');
      await txn.delete('income_templates');
      await txn.delete('transfer_templates');
      await txn.delete('income_sources');
      await txn.delete('category_budget_months');
      await txn.delete('category_budgets');
      await txn.delete('category_suggestions');
      await txn.delete('bill_templates');
      await txn.delete('goals');
      await txn.delete('categories');

      Future<void> insertAll(
        String table,
        List<Map<String, dynamic>> rows,
      ) async {
        for (var i = 0; i < rows.length; i++) {
          try {
            await txn.insert(table, rows[i]);
          } catch (e) {
            throw FormatException(
              '$table row $i failed to insert: $e\nrow=${rows[i]}',
            );
          }
        }
      }

      await insertAll('categories', categories);
      await insertAll('income_sources', sources);
      await insertAll('ledger_entries', entries);
      await insertAll('bill_templates', bills);
      await insertAll('income_templates', incomeTemplates);
      await insertAll('transfer_templates', transferTemplates);
      await insertAll('category_suggestions', suggestions);
      await insertAll('category_budgets', budgets);
      await insertAll('category_budget_months', budgetMonths);
      await insertAll('goals', goals);
    });
  }

  Future<List<Map<String, dynamic>>> getCategorySuggestionsRaw() async {
    final db = await database;
    return (await db.query(
      'category_suggestions',
    )).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCategoryBudgetsRaw() async {
    final db = await database;
    return (await db.query(
      'category_budgets',
    )).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCategoryBudgetMonthsRaw() async {
    final db = await database;
    return (await db.query(
      'category_budget_months',
    )).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _adjustBalance(Database db, int sourceId, int delta) async {
    final source = await db.query(
      'income_sources',
      where: 'id = ?',
      whereArgs: [sourceId],
      limit: 1,
    );
    if (source.isEmpty) return;
    await db.update(
      'income_sources',
      {'balance': (source.first['balance'] as int) + delta},
      where: 'id = ?',
      whereArgs: [sourceId],
    );
  }

  Future<int> spentThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final res = await db.rawQuery(
      "SELECT SUM(amount) as total FROM ledger_entries WHERE type = 'expense' AND status = 'paid' AND date >= ? AND date < ?",
      [
        DateTime(now.year, now.month, 1).toIso8601String(),
        DateTime(now.year, now.month + 1, 1).toIso8601String(),
      ],
    );
    return (res.first['total'] as int?) ?? 0;
  }

  Future<int> incomeThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final res = await db.rawQuery(
      "SELECT SUM(amount) as total FROM ledger_entries WHERE type = 'income' AND date >= ? AND date < ?",
      [
        DateTime(now.year, now.month, 1).toIso8601String(),
        DateTime(now.year, now.month + 1, 1).toIso8601String(),
      ],
    );
    return (res.first['total'] as int?) ?? 0;
  }

  Future<List<LedgerEntry>> getDueEntries() async {
    final db = await database;
    return (await db.query(
      'ledger_entries',
      where: "status = 'due'",
      orderBy: 'date ASC',
    )).map((e) => LedgerEntry.fromMap(e)).toList();
  }

  Future<int> totalDueAmount() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT SUM(amount - paidAmount) as total FROM ledger_entries WHERE status = 'due'",
    );
    return (res.first['total'] as int?) ?? 0;
  }

  Future<List<String>> getSuggestions(int categoryId) async {
    final db = await database;
    return (await db.query(
      'category_suggestions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'useCount DESC, lastUsedAt DESC',
    )).map((e) => e['text'] as String).toList();
  }

  Future<void> recordSuggestionUse(int categoryId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final existing = await db.query(
      'category_suggestions',
      where: 'categoryId = ? AND text = ?',
      whereArgs: [categoryId, t],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('category_suggestions', {
        'categoryId': categoryId,
        'text': t,
        'useCount': 1,
        'lastUsedAt': now,
      });
    } else {
      await db.update(
        'category_suggestions',
        {
          'useCount': (existing.first['useCount'] as int) + 1,
          'lastUsedAt': now,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<List<BillTemplate>> getBillTemplates() async {
    final db = await database;
    return (await db.query(
      'bill_templates',
      orderBy: 'id ASC',
    )).map((e) => BillTemplate.fromMap(e)).toList();
  }

  Future<int> addBillTemplate(BillTemplate b) async {
    final db = await database;
    return db.insert('bill_templates', b.toMap());
  }

  Future<void> updateBillTemplate(BillTemplate b) async {
    final db = await database;
    await db.update(
      'bill_templates',
      b.toMap(),
      where: 'id = ?',
      whereArgs: [b.id],
    );
  }

  Future<void> deleteBillTemplate(int id) async {
    final db = await database;
    await db.delete('bill_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> snapshotMonthlyStart() async {
    final db = await database;
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final prefs = await db.rawQuery(
      "SELECT value FROM app_meta WHERE key = 'last_snapshot'",
    );
    if (prefs.isNotEmpty && prefs.first['value'] == key) return;
    // Save current balance as monthly start for all sources
    final sources = await db.query('income_sources', where: 'archived = 0');
    for (final s in sources) {
      await db.update(
        'income_sources',
        {'monthlyStart': s['balance']},
        where: 'id = ?',
        whereArgs: [s['id']],
      );
    }
    try {
      await db.execute(
        "CREATE TABLE IF NOT EXISTS app_meta (key TEXT PRIMARY KEY, value TEXT)",
      );
      await db.insert('app_meta', {
        'key': 'last_snapshot',
        'value': key,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  // ---- Income Templates ----

  Future<List<IncomeTemplate>> getIncomeTemplates() async {
    final db = await database;
    return (await db.query(
      'income_templates',
      orderBy: 'id ASC',
    )).map((e) => IncomeTemplate.fromMap(e)).toList();
  }

  Future<int> addIncomeTemplate(IncomeTemplate t) async {
    final db = await database;
    return db.insert('income_templates', t.toMap());
  }

  Future<void> updateIncomeTemplate(IncomeTemplate t) async {
    final db = await database;
    await db.update(
      'income_templates',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<void> deleteIncomeTemplate(int id) async {
    final db = await database;
    try {
      await NotificationService.instance.cancelIncomeReminder(id);
    } catch (_) {
      /* best effort */
    }
    await db.delete('income_templates', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Transfer Templates ----

  Future<List<TransferTemplate>> getTransferTemplates() async {
    final db = await database;
    return (await db.query(
      'transfer_templates',
      orderBy: 'id ASC',
    )).map((e) => TransferTemplate.fromMap(e)).toList();
  }

  Future<int> addTransferTemplate(TransferTemplate t) async {
    final db = await database;
    return db.insert('transfer_templates', t.toMap());
  }

  Future<void> updateTransferTemplate(TransferTemplate t) async {
    final db = await database;
    await db.update(
      'transfer_templates',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<void> deleteTransferTemplate(int id) async {
    final db = await database;
    // Transfer templates can carry monthly reminders too. Use a distinct
    // notification id space (offset by 100_000) so we don't collide with

    try {
      await NotificationService.instance.cancelTransferReminder(id);
    } catch (_) {}
    await db.delete('transfer_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetAllData() async {
    final db = await database;

    try {
      await NotificationService.instance.cancelAll();
    } catch (_) {}
    await db.delete('ledger_entries');
    await db.delete('income_templates');
    try {
      await db.delete('transfer_templates');
    } catch (_) {}
    await db.delete('income_sources');
    try {
      await db.delete('category_budget_months');
    } catch (_) {}
    try {
      await db.delete('category_budgets');
    } catch (_) {}
    await db.delete('category_suggestions');
    await db.delete('bill_templates');
    try {
      await db.delete('goals');
    } catch (_) {}
    await db.delete('categories');
    try {
      await db.delete('app_meta');
    } catch (_) {}
    await _seedDefaults(db);

    await _db?.close();
    _db = null;
  }
}
