// lib/core/constants/route_constants.dart
// Author: Jeffry Tambunan | IFS23032
// PAM Praktikum 8 - Flutter Authentication

class RouteConstants {
  RouteConstants._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String todos = '/todos';
  static const String todosAdd = '/todos/add';
  static String todosDetail(String id) => '/todos/$id';
  static String todosEdit(String id) => '/todos/$id/edit';
}
