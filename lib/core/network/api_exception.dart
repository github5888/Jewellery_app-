class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic rawBody;

  const ApiException({
    required this.message,
    this.statusCode,
    this.rawBody,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
