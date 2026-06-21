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
  DateTime? selectedDate;
  String result = '';

  /// Открывает диалог выбора даты и записывает её в поле
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

  /// Основная логика расчёта сложного процента
  void _calculate() {
    // Подготовка чисел (разрешены и точка, и запятая)
    final debtText = debtController.text.replaceAll(',', '.');
    final percentText = percentController.text.replaceAll(',', '.');

    if (debtText.isEmpty || percentText.isEmpty || selectedDate == null) {
      setState(() => result = 'Заполните все поля');
      return;
    }

    final debt = double.tryParse(debtText);
    final percent = double.tryParse(percentText);
    if (debt == null || percent == null || debt < 0 || percent < 0) {
      setState(() => result = 'Введите корректные числа');
      return;
    }

    final today = DateTime.now();
    final start = selectedDate!;
    if (start.isAfter(today)) {
      setState(() => result = 'Дата взятия долга не может быть в будущем');
      return;
    }

    final days = today.difference(start).inDays;
    if (days == 0) {
      setState(() {
        result = 'Сегодня долг взят, пеней нет.\n'
            'Сумма долга: ${debt.toStringAsFixed(2)}';
      });
      return;
    }

    // Сложный процент: каждый день сумма увеличивается на процент от текущей суммы
    final rate = percent / 100.0;
    final total = debt * pow(1 + rate, days);
    final penalty = total - debt;

    setState(() {
      result = 'Прошло дней: $days\n'
          'Итоговая сумма долга: ${total.toStringAsFixed(2)}\n'
          'Начисленные пени: ${penalty.toStringAsFixed(2)}';
    });
  }

  @override
  void dispose() {
    debtController.dispose();
    percentController.dispose();
    dateController.dispose();
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