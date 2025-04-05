import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/budget.dart';

class EditBudgetScreen extends StatefulWidget {
  final Budget budget;
  
  const EditBudgetScreen({super.key, required this.budget});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late String _selectedPeriodicity;

  final List<String> _periodicities = ['weekly', 'monthly', 'quarterly', 'yearly'];
  final Map<String, String> _periodicityLabels = {
    'weekly': 'Hebdomadaire',
    'monthly': 'Mensuel',
    'quarterly': 'Trimestriel',
    'yearly': 'Annuel',
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.budget.amount.toString());
    _selectedPeriodicity = widget.budget.periodicity;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateBudget() async {
    if (_formKey.currentState!.validate()) {
      final updatedBudget = Budget(
        id: widget.budget.id,
        periodicity: _selectedPeriodicity,
        amount: double.parse(_amountController.text.trim()),
      );

      final success = await Provider.of<BudgetProvider>(context, listen: false)
          .updateBudget(updatedBudget);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget mis à jour avec succès')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<BudgetProvider>(context, listen: false).error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le Budget'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Périodicité',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPeriodicity,
                items: _periodicities.map((String periodicity) {
                  return DropdownMenuItem<String>(
                    value: periodicity,
                    child: Text(_periodicityLabels[periodicity] ?? periodicity),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPeriodicity = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une périodicité';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'XOF',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateBudget,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Mettre à jour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
