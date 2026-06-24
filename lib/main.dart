import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Долг с пенями',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DebtCalculator(),
    );
  }
}

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

  /// Вспомогательный метод: добавляет к сообщению имя и причину, если они заполнены
  String _buildResult(String message) {
    final name = nameController.text.trim();
    final reason = reasonController.text.trim();
    String prefix = '';
    if (name.isNotEmpty) prefix += 'Должник: $name\n';
    if (reason.isNotEmpty) prefix += 'Причина: $reason\n';
    return '$prefix$message';
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
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Рассчитать'),
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