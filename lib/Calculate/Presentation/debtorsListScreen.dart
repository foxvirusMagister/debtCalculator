import 'package:flutter/material.dart';
import 'package:dolzhnicapp/Core/models.dart'; // класс Debtor

class DebtorsListScreen extends StatelessWidget {
  final List<Debtor> debtors;

  const DebtorsListScreen({super.key, required this.debtors});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Список должников')),
      body: debtors.isEmpty
          ? const Center(child: Text('Список пуст'))
          : ListView.builder(
              itemCount: debtors.length,
              itemBuilder: (context, index) {
                final debtor = debtors[index];
                return ListTile(
                  title: Text(debtor.name),
                  subtitle: Text(
                    'Вернуть до: ${debtor.predDate}\nДолг: ${debtor.dept.toStringAsFixed(2)}',
                  ),
                  onTap: () {
                    // Пустой обработчик нажатия
                  },
                );
              },
            ),
    );
  }
}