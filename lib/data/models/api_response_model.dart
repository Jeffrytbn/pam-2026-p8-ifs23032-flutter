// lib/data/models/api_response_model.dart
// Author: Jeffry Tambunan | IFS23032
// PAM Praktikum 8 - Flutter Authentication

/// Model generik untuk semua response dari API.
/// [T] adalah tipe data pada field [data].
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final T? data;
}
