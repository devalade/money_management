class Budget {
  final int? id;
  final String periodicity;
  final double amount;

  Budget({
    this.id,
    required this.periodicity,
    required this.amount,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      periodicity: map['periodicity'],
      amount: map['amount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'periodicity': periodicity,
      'amount': amount,
    };
  }
}
