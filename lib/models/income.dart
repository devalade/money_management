class Income {
  final int? id;
  final String date;
  final double amount;
  final String title;
  final String? observation;

  Income({
    this.id,
    required this.date,
    required this.amount,
    required this.title,
    this.observation,
  });

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      date: map['date'],
      amount: map['amount'],
      title: map['title'],
      observation: map['observation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'title': title,
      'observation': observation,
    };
  }
}
