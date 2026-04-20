class Task {
  String? id;
  String? foodDate;
  String? foodMeal;
  String? foodName;
  double? foodPrice;
  int? foodPerson; 
  String? foodImageUrl;

  Task({
    this.id,
    this.foodDate,
    this.foodMeal,
    this.foodName,
    this.foodPrice,
    this.foodPerson,
    this.foodImageUrl,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        foodDate: json['foodDate'],
        foodMeal: json['foodMeal'],
        foodName: json['foodName'],
        foodPrice: json['foodPrice'],
        foodPerson: json['foodPerson'],
        foodImageUrl: json['foodImageUrl'],
      );

  Map<String, dynamic> toJson() => {
        'foodDate': foodDate,
        'foodMeal': foodMeal,
        'foodName': foodName,
        'foodPrice': foodPrice,
        'foodPerson': foodPerson,
        'foodImageUrl': foodImageUrl,
      };
}
