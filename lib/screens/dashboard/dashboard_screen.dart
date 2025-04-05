import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Color> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.brown,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DashboardProvider>(context, listen: false).refreshDashboard();
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).fetchExpensesByWeek();
      Provider.of<IncomeProvider>(context, listen: false).fetchIncomesByMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodicitySelector(),
            const SizedBox(height: 24),
            _buildExpensesByCategoryChart(),
            const SizedBox(height: 32),
            _buildExpensesVsBudgetChart(),
            const SizedBox(height: 32),
            _buildSummaryCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodicitySelector() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Période',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'weekly',
                      label: Text('Hebdo'),
                      icon: Icon(Icons.calendar_view_week),
                    ),
                    ButtonSegment<String>(
                      value: 'monthly',
                      label: Text('Mensuel'),
                      icon: Icon(Icons.calendar_view_month),
                    ),
                    ButtonSegment<String>(
                      value: 'quarterly',
                      label: Text('Trim.'),
                      icon: Icon(Icons.calendar_view_month),
                    ),
                    ButtonSegment<String>(
                      value: 'yearly',
                      label: Text('Annuel'),
                      icon: Icon(Icons.calendar_today),
                    ),
                  ],
                  selected: {dashboardProvider.currentPeriodicity},
                  onSelectionChanged: (Set<String> newSelection) {
                    dashboardProvider.setPeriodicity(newSelection.first);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesByCategoryChart() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dashboardProvider.error.isNotEmpty) {
          return Center(
            child: Text(
              dashboardProvider.error,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final expensesByCategory = dashboardProvider.expensesByCategory;

        if (expensesByCategory.isEmpty) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Aucune dépense trouvée pour cette période',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }

        double totalExpenses = expensesByCategory.values.fold(
          0,
          (sum, amount) => sum + amount,
        );

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dépenses par catégorie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${totalExpenses.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _getPieChartSections(
                        expensesByCategory,
                        totalExpenses,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(expensesByCategory),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _getPieChartSections(
    Map<String, double> data,
    double total,
  ) {
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    data.forEach((category, amount) {
      final double percentage = (amount / total) * 100;
      sections.add(
        PieChartSectionData(
          color: _chartColors[colorIndex % _chartColors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return sections;
  }

  Widget _buildLegend(Map<String, double> data) {
    List<Widget> legendItems = [];
    int colorIndex = 0;

    data.forEach((category, amount) {
      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: _chartColors[colorIndex % _chartColors.length],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                '${amount.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
      colorIndex++;
    });

    return Column(children: legendItems);
  }

  Widget _buildExpensesVsBudgetChart() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dashboardProvider.error.isNotEmpty) {
          return Center(
            child: Text(
              dashboardProvider.error,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final expensesVsBudget = dashboardProvider.expensesVsBudget;

        if (expensesVsBudget.isEmpty) {
          return const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Aucune donnée disponible pour la comparaison budget/dépenses',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dépenses vs Budget',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(expensesVsBudget) * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String category = expensesVsBudget.keys.elementAt(
                              group.x.toInt(),
                            );
                            double value =
                                rodIndex == 0
                                    ? expensesVsBudget[category]!['expense']!
                                    : expensesVsBudget[category]!['budget']!;
                            return BarTooltipItem(
                              '${rodIndex == 0 ? 'Dépense' : 'Budget'}: ${value.toStringAsFixed(2)} €',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 &&
                                  value < expensesVsBudget.length) {
                                String category = expensesVsBudget.keys
                                    .elementAt(value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    category.length > 10
                                        ? '${category.substring(0, 10)}...'
                                        : category,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _getBarGroups(expensesVsBudget),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text('Dépenses'),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        const Text('Budget'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getMaxValue(Map<String, Map<String, double>> data) {
    double max = 0;
    data.forEach((category, values) {
      if (values['expense']! > max) max = values['expense']!;
      if (values['budget']! > max) max = values['budget']!;
    });
    return max;
  }

  List<BarChartGroupData> _getBarGroups(Map<String, Map<String, double>> data) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    data.forEach((category, values) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values['expense']!,
              color: Colors.blue,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: values['budget']!,
              color: Colors.green,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return barGroups;
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildIncomeCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildExpenseCard()),
          ],
        ),
        const SizedBox(height: 16),
        _buildBalanceCard(),
      ],
    );
  }

  Widget _buildIncomeCard() {
    return Consumer<IncomeProvider>(
      builder: (context, incomeProvider, child) {
        final totalIncome = incomeProvider.getTotalIncome();

        return Card(
          color: Colors.green.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Revenus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalIncome.toStringAsFixed(2)} XOF',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ce mois',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseCard() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        double totalExpenses = 0;
        for (var expense in expenseProvider.expenses) {
          totalExpenses += expense.amount;
        }

        return Card(
          color: Colors.red.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Dépenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalExpenses.toStringAsFixed(2)} XOF',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cette semaine',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard() {
    return Consumer2<IncomeProvider, ExpenseProvider>(
      builder: (context, incomeProvider, expenseProvider, child) {
        final totalIncome = incomeProvider.getTotalIncome();

        double totalExpenses = 0;
        for (var expense in expenseProvider.expenses) {
          totalExpenses += expense.amount;
        }

        final balance = totalIncome - totalExpenses;
        final isPositive = balance >= 0;

        return Card(
          color: isPositive ? Colors.blue.shade50 : Colors.orange.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.account_balance : Icons.warning,
                      color: isPositive ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${balance.toStringAsFixed(2)} XOF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.blue : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPositive ? 'Excédent' : 'Déficit',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
