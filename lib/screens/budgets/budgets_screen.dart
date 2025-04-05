import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/budget.dart';
import 'new_budget_screen.dart';
import 'edit_budget_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<BudgetProvider>(context, listen: false).fetchBudgets()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (budgetProvider.error.isNotEmpty) {
            return Center(
              child: Text(
                budgetProvider.error,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          if (budgetProvider.budgets.isEmpty) {
            return const Center(
              child: Text('Aucun budget trouvé. Ajoutez-en un !'),
            );
          }
          
          return ListView.builder(
            itemCount: budgetProvider.budgets.length,
            itemBuilder: (context, index) {
              final budget = budgetProvider.budgets[index];
              return Dismissible(
                key: Key(budget.id.toString()),
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
                        content: const Text('Voulez-vous supprimer ce budget ?'),
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
                  final success = await budgetProvider.deleteBudget(budget.id!);
                  if (!success) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(budgetProvider.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget supprimé avec succès'),
                      ),
                    );
                  }
                },
                child: ListTile(
                  title: Text('${budget.periodicity} - ${budget.amount} XOF'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditBudgetScreen(budget: budget),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewBudgetScreen(),
            ),
          );
        },
        tooltip: 'Ajouter un budget',
        child: const Icon(Icons.add),
      ),
    );
  }
}
