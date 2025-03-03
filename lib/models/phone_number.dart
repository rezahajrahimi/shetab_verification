class PhoneNumber {
  String number;
  String description;

  PhoneNumber({
    required this.number,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'description': description,
  };

  factory PhoneNumber.fromJson(Map<String, dynamic> json) => PhoneNumber(
    number: json['number'],
    description: json['description'] ?? '',
  );
} 