import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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
    final TextEditingController resultOstatokController = TextEditingController(
        text: isEditing ? entry['ostatok'].toString() : '');

    void _updateResultOstatok() {
      final ostatok = double.tryParse(ostatokController.text) ?? 0;
      final tushdi = double.tryParse(tushdiController.text) ?? 0;
      final ketdi = double.tryParse(ketdiController.text) ?? 0;
      resultOstatokController.text = (ostatok + tushdi - ketdi).toString();
    }

    tushdiController.addListener(_updateResultOstatok);
    ketdiController.addListener(_updateResultOstatok);
    ostatokController.addListener(_updateResultOstatok);

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
                _buildTextField(resultOstatokController, 'Остаток (итог)', Icons.account_balance, readOnly: true),
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
                final newEntry = {
                  'date': entry != null && isEditing ? entry['date'] : DateTime.now().toIso8601String(),
                  'ostatok': double.tryParse(ostatokController.text) ?? 0,
                  'tushdi': double.tryParse(tushdiController.text) ?? 0,
                  'ketdi': double.tryParse(ketdiController.text) ?? 0,
                };
                if (isEditing) {
                  _workDayBox.putAt(index!, newEntry);
                } else {
                  _workDayBox.add(newEntry);
                }
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildColoredBlock(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
                  : box.values.where((entry) => DateFormat('dd.MM.yyyy').format(DateTime.parse(entry['date'])) == _selectedDate).toList();

              filteredEntries.sort((a, b) => b['date'].compareTo(a['date']));

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
                  final originalIndex = _workDayBox.values.toList().indexOf(entry);
                  return Dismissible(
                    key: Key(entry['date']),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      color: Colors.blue,
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _showEditEntryDialog(context, originalIndex);
                        return false;
                      } else if (direction == DismissDirection.endToStart) {
                        return await showDialog(
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
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Удалить'),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        _deleteEntry(originalIndex);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                      color: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(entry['date']))}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildColoredBlock('Остаток', entry['ostatok'], Colors.blue, Icons.account_balance_wallet),
                            _buildColoredBlock('Тушди', entry['tushdi'], Colors.grey, Icons.arrow_downward),
                            _buildColoredBlock('Кетди', entry['ketdi'], Colors.red, Icons.arrow_upward),
                            _buildColoredBlock('Остаток (итог)', (entry['ostatok'] + entry['tushdi'] - entry['ketdi']), Colors.green, Icons.account_balance),
                          ],
                        ),
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
        _selectedDate = DateFormat('dd.MM.yyyy').format(pickedDate);
      });
    }
  }
}
