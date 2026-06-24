/// Класс, представляющий запись о должнике в таблице debters.
class Debtor {
  final int? id;               // автоинкрементный первичный ключ, может быть null до вставки
  final String name;
  final String? description;
  final double percent;
  final DateTime startDate;    // дата начала
  final DateTime predDate;     // предполагаемая дата
  final double dept;           // сумма долга
  final bool closed;           // завершён ли долг

  const Debtor({
    this.id,
    required this.name,
    this.description,
    required this.percent,
    required this.startDate,
    required this.predDate,
    required this.dept,
    this.closed = false,
  });

  /// Создать объект [Debter] из словаря (например, после запроса к SQLite).
  /// Ожидается, что даты хранятся в текстовом формате ISO 8601.
  factory Debtor.fromMap(Map<String, dynamic> map) {
    return Debtor(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      percent: (map['percent'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      predDate: DateTime.parse(map['predDate'] as String),
      dept: (map['dept'] as num).toDouble(),
      closed: (map['closed'] as int) == 1,
    );
  }

  /// Преобразовать объект в словарь для вставки/обновления в SQLite.
  /// [id] не включается, если равен null (автоинкремент).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'percent': percent,
      'startDate': startDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'predDate': predDate.toIso8601String().substring(0, 10),
      'dept': dept,
      'closed': closed ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Создать копию с изменёнными полями (удобно для обновлений).
  Debtor copyWith({
    int? id,
    String? name,
    String? description,
    double? percent,
    DateTime? startDate,
    DateTime? predDate,
    double? dept,
    bool? closed,
  }) {
    return Debtor(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      percent: percent ?? this.percent,
      startDate: startDate ?? this.startDate,
      predDate: predDate ?? this.predDate,
      dept: dept ?? this.dept,
      closed: closed ?? this.closed,
    );
  }

  @override
  String toString() {
    return 'Debter(id: $id, name: $name, dept: $dept, closed: $closed)';
  }
}