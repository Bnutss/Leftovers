import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WorkDayScreen extends StatefulWidget {
  const WorkDayScreen({super.key});

  @override
  _WorkDayScreenState createState() => _WorkDayScreenState();
}

class _WorkDayScreenState extends State<WorkDayScreen> {
  final Box _workDayBox = Hive.box('workDayBox');
  String? _selectedDate;

  void _showAddEntryDialog(BuildContext context) {
    _showEntryDialog(context, null);
  }

  void _showEditEntryDialog(BuildContext context, int index) {
    _showEntryDialog(context, index);
  }

  void _showEntryDialog(BuildContext context, int? index) {
    final isEditing = index != null;
    final entry = isEditing ? _workDayBox.getAt(index!) : null;

    final TextEditingController ostatokController = TextEditingController(
        text: isEditing ? entry['ostatok'].toString() : '');
    final TextEditingController tushdiController = TextEditingController(
        text: isEditing ? entry['tushdi'].toString() : '');
    final TextEditingController ketdiController = TextEditingController(
        text: isEditing ? entry['ketdi'].toString() : '');
    final TextEditingController secondOstatokController = TextEditingController(
        text: isEditing ? entry['secondOstatok'].toString() : '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Редактировать запись' : 'Добавить запись'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(ostatokController, 'Остаток', Icons.account_balance_wallet),
                _buildTextField(tushdiController, 'Тушди', Icons.arrow_downward),
                _buildTextField(ketdiController, 'Кетди', Icons.arrow_upward),
                _buildTextField(secondOstatokController, 'Остаток', Icons.account_balance),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Сохранить' : 'Добавить'),
              onPressed: () {
                setState(() {
                  final newEntry = {
                    'date': isEditing
                        ? entry['date']
                        : '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
                    'ostatok': double.tryParse(ostatokController.text) ?? 0,
                    'tushdi': double.tryParse(tushdiController.text) ?? 0,
                    'ketdi': double.tryParse(ketdiController.text) ?? 0,
                    'secondOstatok': double.tryParse(secondOstatokController.text) ?? 0,
                  };
                  if (isEditing) {
                    _workDayBox.putAt(index!, newEntry);
                  } else {
                    _workDayBox.add(newEntry);
                    // Перемещаем новую запись в начало списка
                    final newIndex = _workDayBox.length - 1;
                    final newEntry = _workDayBox.getAt(newIndex);
                    _workDayBox.deleteAt(newIndex);
                    _workDayBox.add(newEntry);
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Подтверждение удаления',
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: const Text('Вы уверены, что хотите удалить эту запись?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Удалить'),
              onPressed: () {
                _deleteEntry(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteEntry(int index) {
    setState(() {
      _workDayBox.deleteAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Запись успешно удалена'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate =
        '${pickedDate.day.toString().padLeft(2, '0')}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Рабочий день',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {
              _selectDate(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showAddEntryDialog(context);
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurpleAccent,
                Colors.grey,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurpleAccent,
              Colors.grey,
            ],
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: _workDayBox.listenable(),
          builder: (context, Box box, _) {
            if (box.isEmpty) {
              return const Center(
                child: Text(
                  'Записей пока нет.',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              );
            } else {
              List filteredEntries = _selectedDate == null
                  ? box.values.toList()
                  : box.values.where((entry) => entry['date'] == _selectedDate).toList();

              if (filteredEntries.isEmpty) {
                return const Center(
                  child: Text(
                    'Записей за выбранную дату нет.',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredEntries.length,
                itemBuilder: (context, index) {
                  final entry = filteredEntries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    color: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10.0),
                      leading: const Icon(Icons.date_range, color: Colors.white),
                      title: Text(
                        'Дата: ${entry['date']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Остаток: ${entry['ostatok']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Тушди: ${entry['tushdi']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Кетди: ${entry['ketdi']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Остаток: ${entry['secondOstatok']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              _showEditEntryDialog(context, index);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              _confirmDelete(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}