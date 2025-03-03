class ApiSettings {
  String endpoint;
  String apiKey;

  ApiSettings({
    required this.endpoint,
    required this.apiKey,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'apiKey': apiKey,
  };

  factory ApiSettings.fromJson(Map<String, dynamic> json) => ApiSettings(
    endpoint: json['endpoint'] ?? '',
    apiKey: json['apiKey'] ?? '',
  );
} 