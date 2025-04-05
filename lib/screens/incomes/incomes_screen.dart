import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/income_provider.dart';
import 'new_income_screen.dart';

class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key});

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<IncomeProvider>(context, listen: false).fetchIncomesByMonth()
    );
  }

  Future<void> _showDateRangeDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isFilterActive = true;
      });
      
      if (!mounted) return;
      Provider.of<IncomeProvider>(context, listen: false)
          .fetchIncomesByDateRange(_startDate, _endDate);
    }
  }

  void _resetFilter() {
    setState(() {
      _isFilterActive = false;
    });
    Provider.of<IncomeProvider>(context, listen: false).fetchIncomesByMonth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showDateRangeDialog,
          ),
          if (_isFilterActive)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _resetFilter,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isFilterActive)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 8),
                    Text(
                      'Du ${DateFormat('dd/MM/yyyy').format(_startDate)} au ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Consumer<IncomeProvider>(
              builder: (context, incomeProvider, child) {
                if (incomeProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (incomeProvider.error.isNotEmpty) {
                  return Center(
                    child: Text(
                      incomeProvider.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                if (incomeProvider.incomes.isEmpty) {
                  return const Center(
                    child: Text('Aucun revenu trouvé pour cette période.'),
                  );
                }
                
                final totalIncome = incomeProvider.getTotalIncome();
                
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total des revenus:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${totalIncome.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: incomeProvider.incomes.length,
                        itemBuilder: (context, index) {
                          final income = incomeProvider.incomes[index];
                          return Dismissible(
                            key: Key(income.id.toString()),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirmation'),
                                    content: const Text('Voulez-vous supprimer ce revenu ?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) async {
                              final success = await incomeProvider.deleteIncome(income.id!);
                              if (!success) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(incomeProvider.error),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Revenu supprimé avec succès'),
                                  ),
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(income.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(income.date))),
                                    if (income.observation != null && income.observation!.isNotEmpty)
                                      Text('Note: ${income.observation}'),
                                  ],
                                ),
                                trailing: Text(
                                  '${income.amount.toStringAsFixed(2)} XOF',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewIncomeScreen(),
            ),
          );
        },
        tooltip: 'Ajouter un revenu',
        child: const Icon(Icons.add),
      ),
    );
  }
}
