class Expense {
  final int? id;
  final String date;
  final int categoryId;
  final double amount;
  final String title;
  final String? observation;
  final String? categoryName; // Used when joining with category table

  Expense({
    this.id,
    required this.date,
    required this.categoryId,
    required this.amount,
    required this.title,
    this.observation,
    this.categoryName,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: map['date'],
      categoryId: map['category_id'],
      amount: map['amount'],
      title: map['title'],
      observation: map['observation'],
      categoryName: map['category_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'category_id': categoryId,
      'amount': amount,
      'title': title,
      'observation': observation,
    };
  }
}
