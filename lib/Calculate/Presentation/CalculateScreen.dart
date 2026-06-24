import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dolzhnicapp/Core/models.dart';
import 'package:dolzhnicapp/Calculate/DataBase/DatabaseFunctions.dart' as db;
import 'package:sqflite/sqflite.dart';
import 'package:dolzhnicapp/Calculate/Presentation/debtorsListScreen.dart';

class DebtCalculator extends StatefulWidget {
  const DebtCalculator({super.key});

  @override
  State<DebtCalculator> createState() => _DebtCalculatorState();
}

class _DebtCalculatorState extends State<DebtCalculator> {
  final debtController = TextEditingController();
  final percentController = TextEditingController();
  final dateController = TextEditingController();
  final predDateController = TextEditingController();
  final nameController = TextEditingController();      // новое поле
  final reasonController = TextEditingController();    // новое поле

  DateTime? selectedDate;
  DateTime? selectedPredictedDate;
  String result = '';


  /// Создаёт объект [Debtor] из текущих значений полей ввода.
/// Возвращает готовый объект или `null`, если данные некорректны.
Debtor? _buildDebtorFromFields() {
  // Проверка обязательного имени
  final name = nameController.text.trim();
  if (name.isEmpty) {
    setState(() => result = 'Введите имя должника');
    return null;
  }

  // Проверка причины (description) – может быть пустой, это допустимо
  final description = reasonController.text.trim();
  final reason = description.isEmpty ? null : description;

  // Проверка суммы долга
  final debtText = debtController.text.replaceAll(',', '.');
  final debt = double.tryParse(debtText);
  if (debt == null || debt < 0) {
    setState(() => result = 'Введите корректную сумму долга (положительное число)');
    return null;
  }

  // Проверка процента
  final percentText = percentController.text.replaceAll(',', '.');
  final percent = double.tryParse(percentText);
  if (percent == null || percent < 0) {
    setState(() => result = 'Введите корректный процент (положительное число)');
    return null;
  }

  // Проверка даты начала
  if (selectedDate == null) {
    setState(() => result = 'Выберите дату взятия долга');
    return null;
  }
  final startDate = selectedDate!;

  // Проверка предполагаемой даты
  if (selectedPredictedDate == null) {
    setState(() => result = 'Выберите предполагаемую дату возврата');
    return null;
  }
  final predDate = selectedPredictedDate!;

  // Дополнительная логическая проверка (по желанию, можно оставить)
  if (predDate.isBefore(startDate)) {
    setState(() => result = 'Предполагаемая дата возврата не может быть раньше даты взятия');
    return null;
  }

  // Все данные корректны – создаём объект должника
  return Debtor(
    // id отсутствует (будет присвоен базой при вставке)
    name: name,
    description: reason,
    percent: percent,
    startDate: startDate,
    predDate: predDate,
    dept: debt,
    closed: false, // новый долг по умолчанию не закрыт
  );
}
  /// Вспомогательный метод: добавляет к сообщению имя и причину, если они заполнены
  String _buildResult(String message) {
    final name = nameController.text.trim();
    final reason = reasonController.text.trim();
    String prefix = '';
    if (name.isNotEmpty) prefix += 'Должник: $name\n';
    if (reason.isNotEmpty) prefix += 'Причина: $reason\n';
    return '$prefix$message';
  }

  void _openDebtorsList() async {
  final database = await db.createDatabase();
  final debtors = await db.getAllDebtors(database);
  if (!mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DebtorsListScreen(debtors: debtors),
      ),
    );
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            '${picked.day.toString().padLeft(2, '0')}.'
            '${picked.month.toString().padLeft(2, '0')}.'
            '${picked.year}';
      });
    }
  }

  Future<void> _pickPredDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedPredictedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedPredictedDate = picked;
        predDateController.text =
            '${picked.day.toString().padLeft(2, '0')}.'
            '${picked.month.toString().padLeft(2, '0')}.'
            '${picked.year}';
      });
    }
  }

  void _calculate() {
    final debtText = debtController.text.replaceAll(',', '.');
    final percentText = percentController.text.replaceAll(',', '.');

    if (debtText.isEmpty || percentText.isEmpty || selectedDate == null) {
      setState(() => result = _buildResult('Заполните все обязательные поля'));
      return;
    }

    final debt = double.tryParse(debtText);
    final percent = double.tryParse(percentText);
    if (debt == null || percent == null || debt < 0 || percent < 0) {
      setState(() => result = _buildResult('Введите корректные числа'));
      return;
    }

    final today = DateTime.now();
    final start = selectedDate!;
    final predEnd = selectedPredictedDate;

    if (start.isAfter(today)) {
      setState(() => result = _buildResult('Дата взятия долга не может быть в будущем'));
      return;
    }

    if (predEnd == null) {
      setState(() => result = _buildResult('Выберите предполагаемую дату отдачи долга'));
      return;
    }

    if (predEnd.isAfter(today)) {
      setState(() => result = _buildResult('Ещё не время отдавать долг, процентов нет'));
      return;
    }

    if (predEnd.isBefore(start)) {
      setState(() => result = _buildResult('Вы не можете отдать долг до того, как его взяли!'));
      return;
    }

    final days = today.difference(predEnd).inDays;
    if (days == 0) {
      setState(() {
        result = _buildResult(
          'Пеней нет.\nСумма долга: ${debt.toStringAsFixed(2)}',
        );
      });
      return;
    }

    final rate = percent / 100.0;
    final total = debt * pow(1 + rate, days);
    final penalty = total - debt;

    setState(() {
      result = _buildResult(
        'Просрочено дней: $days\n'
        'Итоговая сумма долга: ${total.toStringAsFixed(2)}\n'
        'Начисленные пени: ${penalty.toStringAsFixed(2)}',
      );
    });
  }

  @override
  void dispose() {
    debtController.dispose();
    percentController.dispose();
    dateController.dispose();
    predDateController.dispose();
    nameController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор пенни')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Новые поля: имя должника и причина долга
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Имя должника'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Причина долга'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: debtController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Сумма долга'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: percentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Процент пенни от долга (%)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Дата взятия долга',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: predDateController,
              readOnly: true,
              onTap: _pickPredDate,
              decoration: const InputDecoration(
                labelText: 'Предположительная дата отдачи долга',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: .center,
              children: [
                ElevatedButton(
                  onPressed: _calculate,
                  child: const Text('Рассчитать'),
                ),
                ElevatedButton(
                  onPressed: ()async {
                    Debtor? debtor = _buildDebtorFromFields();
                    if (debtor != null)
                    {
                      Database database = await db.createDatabase();
                      await db.addDebtor(db: database, debtor: debtor);
                      setState(() {
                        showDialog(context: context, builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Успех"),
                            content: Text("Объект успешно добавлен в базу данных!"),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("OK"))
                            ],
                          );
                        });
                      });
                    }
                  },
                  child: const Text("Сохранить"),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _openDebtorsList(),
              child: const Text("Открыть список всех")
            ),
            const SizedBox(height: 20),
            Text(
              result,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}