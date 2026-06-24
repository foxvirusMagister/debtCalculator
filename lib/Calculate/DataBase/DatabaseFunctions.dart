import 'package:dolzhnicapp/Core/models.dart';
import 'package:sqflite/sqflite.dart';

/// Возвращает объект Database
Future<Database> createDatabase() async {

  // Открываем (или создаём) базу данных.
  return openDatabase(
    'debtBase',
    version: 1,
    onCreate: (db, version) async {
      // Создаём таблицу debters
      await db.execute('''
        CREATE TABLE debtors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          percent REAL,
          startDate TEXT,
          predDate TEXT,
          dept REAL,
          closed INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
}

Future<int> addDebtor({
  required Database db,
  required Debtor debtor
}) async {
  int insertedId = 0;

  await db.transaction((txn) async {
    insertedId = await txn.insert(
      'debtors',
      debtor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  });

  return insertedId;
}

Future<List<Debtor>> getAllDebtors(Database db) async {
  final List<Map<String, dynamic>> maps = await db.query('debtors');
  return List.generate(maps.length, (i) => Debtor.fromMap(maps[i]));
}

/// Обновляет запись о должнике в таблице debters на основе переданного объекта [Debter].
/// Параметры:
/// - [db]: открытое соединение с базой данных.
/// - [debtor]: объект должника, который должен содержать [id] для идентификации записи.
/// Возвращает [Future<int>] – количество изменённых строк (обычно 1, если запись найдена, иначе 0).
Future<int> updateDebtor(Database db, Debtor debtor) async {
  // Убеждаемся, что у объекта есть id, иначе обновление невозможно
  if (debtor.id == null) {
    throw ArgumentError('Для обновления должника необходимо указать id.');
  }

  int updatedCount = 0;

  // Выполняем обновление в транзакции для атомарности
  await db.transaction((txn) async {
    updatedCount = await txn.update(
      'debtors',
      debtor.toMap(),           // преобразуем объект в словарь значений
      where: 'id = ?',         // условие – обновляем запись с конкретным id
      whereArgs: [debtor.id],
    );
  });

  return updatedCount;
}