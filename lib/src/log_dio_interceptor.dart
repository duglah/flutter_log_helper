import 'package:collection/collection.dart';
import 'package:dio/dio.dart';

/// Represents a logged HTTP request.
class LogRequest {
  /// The URL of the request.
  final String url;

  /// The HTTP method used for the request (GET, POST, etc.).
  final String method;

  /// The headers sent with the request.
  final Map<String, dynamic> headers;

  /// The body of the request, if any.
  final dynamic body;

  /// The time when the request was sent, can be null if request was not found in cache.
  final DateTime? sentAt;

  /// Creates a new instance of [LogRequest].
  LogRequest({
    required this.url,
    required this.method,
    required this.headers,
    required this.body,
    required this.sentAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LogRequest &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.method, method) || other.method == method) &&
            const DeepCollectionEquality().equals(other.headers, headers) &&
            const DeepCollectionEquality().equals(other.body, body) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    method,
    const DeepCollectionEquality().hash(headers),
    body,
    sentAt,
  );

  @override
  String toString() {
    return 'LogRequest(url: $url, method: $method, headers: $headers, body: $body, sentAt: $sentAt)';
  }
}

/// Represents a logged HTTP response.
class LogResponse {
  /// Indicates whether the response resulted in an error.
  final bool hasError;

  /// The HTTP status code of the response.
  final int statusCode;

  /// The headers received with the response.
  final Map<String, String> headers;

  /// The body of the response, if any.
  final dynamic body;

  /// The time when the response was received.
  final DateTime receivedAt;

  /// Creates a new instance of [LogResponse].
  LogResponse({
    this.hasError = false,
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.receivedAt,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LogResponse &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            const DeepCollectionEquality().equals(other.headers, headers) &&
            const DeepCollectionEquality().equals(other.body, body) &&
            (identical(other.receivedAt, receivedAt) ||
                other.receivedAt == receivedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    hasError,
    statusCode,
    const DeepCollectionEquality().hash(headers),
    body,
    receivedAt,
  );

  @override
  String toString() {
    return 'LogResponse(hasError: $hasError, statusCode: $statusCode, headers: $headers, body: $body, receivedAt: $receivedAt)';
  }
}

/// An interceptor for Dio that logs HTTP requests and responses.
class LogDioInterceptor extends Interceptor {
  final _requestTimeCache = <RequestOptions, DateTime>{};

  final void Function(LogRequest request, LogResponse response)? _logCallback;

  final int _maxCacheSize;

  /// A cache for logged requests and responses.
  final List<(LogRequest request, LogResponse response)> httpLogCache = [];

  /// Creates a new instance of [LogDioInterceptor].
  ///
  /// The [logCallback] is a function that will be called with the logged request and response data.
  LogDioInterceptor({
    void Function(LogRequest request, LogResponse response)? logCallback,
    int maxCacheSize = 100,
  }) : assert(maxCacheSize > 0, 'maxCacheSize must be greater than 0'),
       _logCallback = logCallback,
       _maxCacheSize = maxCacheSize;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimeCache[options] = DateTime.now().toUtc();

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final Map<String, String> responseHeaders = response.headers.map.map(
      (key, value) => MapEntry(key, value.join(', ')),
    );
    final sentAt = _requestTimeCache[response.requestOptions];
    final receivedAt = DateTime.now().toUtc();
    _requestTimeCache.remove(response.requestOptions);

    final logRequest = LogRequest(
      url: response.requestOptions.uri.toString(),
      method: response.requestOptions.method,
      headers: response.requestOptions.headers,
      body: response.requestOptions.data,
      sentAt: sentAt,
    );
    final logResponse = LogResponse(
      statusCode: response.statusCode ?? 0,
      headers: responseHeaders,
      body: response.data,
      receivedAt: receivedAt,
    );

    _log(logRequest, logResponse);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Map<String, String>? responseHeaders = err.response?.headers.map.map(
      (key, value) => MapEntry(key, value.join(', ')),
    );
    final sentAt = _requestTimeCache[err.requestOptions];
    final receivedAt = DateTime.now();
    _requestTimeCache.remove(err.requestOptions);

    final logRequest = LogRequest(
      url: err.requestOptions.uri.toString(),
      method: err.requestOptions.method,
      headers: err.requestOptions.headers,
      body: err.requestOptions.data,
      sentAt: sentAt,
    );
    final logResponse = LogResponse(
      hasError: true,
      statusCode: err.response?.statusCode ?? 0,
      headers: responseHeaders ?? {},
      body: err.response?.data,
      receivedAt: receivedAt,
    );

    _log(logRequest, logResponse);

    handler.next(err);
  }

  void _log(LogRequest logRequest, LogResponse logResponse) {
    if (httpLogCache.length >= _maxCacheSize) {
      httpLogCache.removeAt(0);
    }
    httpLogCache.add((logRequest, logResponse));

    if (_logCallback != null) {
      _logCallback(logRequest, logResponse);
    }
  }
}
