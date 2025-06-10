import 'package:dio/dio.dart';
import 'package:flutter_log_helper/src/log_dio_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'log_dio_interceptor_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RequestInterceptorHandler>(),
  MockSpec<ResponseInterceptorHandler>(),
  MockSpec<ErrorInterceptorHandler>(),
])
void main() {
  group('LogRequest', () {
    group('==', () {
      test('should return true when all properties are equal', () {
        final request1 = LogRequest(
          url: 'https://example.com',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          sentAt: DateTime.now(),
        );
        final request2 = LogRequest(
          url: 'https://example.com',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          sentAt: request1.sentAt,
        );

        expect(request1, equals(request2));
      });

      test('should return false when url is different', () {
        final request1 = LogRequest(
          url: 'https://example.com',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          sentAt: DateTime.now(),
        );
        final request2 = LogRequest(
          url: 'https://another.com',
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          sentAt: request1.sentAt,
        );

        expect(request1, isNot(equals(request2)));
      });
    });
  });

  group('LogResponse', () {
    group('==', () {
      test('should return true when all properties are equal', () {
        final response1 = LogResponse(
          hasError: false,
          statusCode: 200,
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          receivedAt: DateTime.now(),
        );
        final response2 = LogResponse(
          hasError: false,
          statusCode: 200,
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          receivedAt: response1.receivedAt,
        );

        expect(response1, equals(response2));
      });

      test('should return false when statusCode is different', () {
        final response1 = LogResponse(
          statusCode: 200,
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          receivedAt: DateTime.now(),
        );
        final response2 = LogResponse(
          statusCode: 404,
          headers: {'Content-Type': 'application/json'},
          body: {'key': 'value'},
          receivedAt: response1.receivedAt,
        );

        expect(response1, isNot(equals(response2)));
      });
    });
  });

  group('LogDioInterceptor', () {
    late MockRequestInterceptorHandler requestHandler;
    late MockResponseInterceptorHandler responseHandler;
    late MockErrorInterceptorHandler errorHandler;

    final requestOptions = RequestOptions(
      baseUrl: 'https://testapi.com',
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      data: {'key': 'value'},
    );

    final responseOptions = Response(
      requestOptions: requestOptions,
      statusCode: 200,
      data: {'responseKey': 'responseValue'},
      headers: Headers.fromMap({
        'Content-Type': ['application/json'],
      }),
    );

    final errorOptions = DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 500,
        data: {'errorKey': 'errorValue'},
        headers: Headers.fromMap({
          'Content-Type': ['application/json'],
        }),
      ),
      type: DioExceptionType.badResponse,
    );

    setUp(() {
      requestHandler = MockRequestInterceptorHandler();
      responseHandler = MockResponseInterceptorHandler();
      errorHandler = MockErrorInterceptorHandler();
    });

    group('onRequest', () {
      test('should deliver the request to the next interceptor', () {
        final interceptor = LogDioInterceptor(
          logCallback: (request, response) {},
        );

        interceptor.onRequest(requestOptions, requestHandler);

        verify(requestHandler.next(requestOptions)).called(1);
        verifyNever(requestHandler.resolve(any, any));
        verifyNever(requestHandler.reject(any, any));
      });
    });

    group('onResponse', () {
      test('should deliver the response to the next interceptor', () {
        final interceptor = LogDioInterceptor(
          logCallback: (request, response) {},
        );

        interceptor.onResponse(responseOptions, responseHandler);

        verify(responseHandler.next(responseOptions)).called(1);
        verifyNever(responseHandler.resolve(any));
        verifyNever(responseHandler.reject(any, any));
      });
    });

    group('onError', () {
      test('should deliver the error to the next interceptor', () {
        final interceptor = LogDioInterceptor(
          logCallback: (request, response) {},
        );

        interceptor.onError(errorOptions, errorHandler);

        verify(errorHandler.next(errorOptions)).called(1);
        verifyNever(errorHandler.resolve(any));
        verifyNever(errorHandler.reject(any));
      });
    });

    group('logCache', () {
      test(
        'should add request and response to the logCache, when is successful request and response',
        () {
          final interceptor = LogDioInterceptor();

          interceptor.onRequest(requestOptions, requestHandler);
          interceptor.onResponse(responseOptions, responseHandler);

          final (LogRequest request, LogResponse response) logEntry =
              interceptor.httpLogCache.first;
          LogRequest logRequest = logEntry.$1;
          LogResponse logResponse = logEntry.$2;

          expect(logRequest.url, 'https://testapi.com');
          expect(logRequest.method, 'POST');
          expect(logRequest.headers, {'Content-Type': 'application/json'});
          expect(logRequest.body, {'key': 'value'});
          expect(logRequest.sentAt, isNotNull);
          expect(logRequest.sentAt!.isBefore(DateTime.now().toUtc()), isTrue);

          expect(logResponse.statusCode, 200);
          expect(logResponse.headers, {'Content-Type': 'application/json'});
          expect(logResponse.body, {'responseKey': 'responseValue'});
          expect(logResponse.hasError, isFalse);
          expect(logResponse.receivedAt, isNotNull);
          expect(logResponse.receivedAt.isAfter(logRequest.sentAt!), isTrue);
          expect(
            logResponse.receivedAt.isBefore(DateTime.now().toUtc()),
            isTrue,
          );
        },
      );

      test(
        'should pass request and error to the callback, when is error response',
        () {
          final interceptor = LogDioInterceptor();

          interceptor.onRequest(requestOptions, requestHandler);
          interceptor.onError(errorOptions, errorHandler);

          final (LogRequest request, LogResponse response) logEntry =
              interceptor.httpLogCache.first;
          LogRequest logRequest = logEntry.$1;
          LogResponse logResponse = logEntry.$2;

          expect(logRequest, isNotNull);
          expect(logRequest.url, 'https://testapi.com');
          expect(logRequest.method, 'POST');
          expect(logRequest.headers, {'Content-Type': 'application/json'});
          expect(logRequest.body, {'key': 'value'});
          expect(logRequest.sentAt, isNotNull);
          expect(logRequest.sentAt!.isBefore(DateTime.now().toUtc()), isTrue);

          expect(logResponse, isNotNull);
          expect(logResponse.statusCode, 500);
          expect(logResponse.headers, {'Content-Type': 'application/json'});
          expect(logResponse.body, {'errorKey': 'errorValue'});
          expect(logResponse.hasError, isTrue);
          expect(logResponse.receivedAt, isNotNull);
          expect(logResponse.receivedAt.isAfter(logRequest.sentAt!), isTrue);
          expect(
            logResponse.receivedAt.isBefore(DateTime.now().toUtc()),
            isTrue,
          );
        },
      );

      test('should not exceed max cache size, when adding new log entries', () {
        final interceptor = LogDioInterceptor(maxCacheSize: 2);

        interceptor.onRequest(requestOptions, requestHandler);
        interceptor.onResponse(responseOptions, responseHandler);

        interceptor.onRequest(requestOptions, requestHandler);
        interceptor.onResponse(responseOptions, responseHandler);

        interceptor.onRequest(requestOptions, requestHandler);
        interceptor.onResponse(responseOptions, responseHandler);

        expect(interceptor.httpLogCache.length, 2);
      });
    });

    group('callback', () {
      test(
        'should pass request and response to the callback, when is successful request and response',
        () {
          LogRequest? logRequest;
          LogResponse? logResponse;

          final interceptor = LogDioInterceptor(
            logCallback: (request, response) {
              logRequest = request;
              logResponse = response;
            },
          );

          interceptor.onRequest(requestOptions, requestHandler);
          interceptor.onResponse(responseOptions, responseHandler);

          expect(logRequest, isNotNull);
          expect(logRequest!.url, 'https://testapi.com');
          expect(logRequest!.method, 'POST');
          expect(logRequest!.headers, {'Content-Type': 'application/json'});
          expect(logRequest!.body, {'key': 'value'});
          expect(logRequest!.sentAt, isNotNull);
          expect(logRequest!.sentAt!.isBefore(DateTime.now().toUtc()), isTrue);

          expect(logResponse, isNotNull);
          expect(logResponse!.statusCode, 200);
          expect(logResponse!.headers, {'Content-Type': 'application/json'});
          expect(logResponse!.body, {'responseKey': 'responseValue'});
          expect(logResponse!.hasError, isFalse);
          expect(logResponse!.receivedAt, isNotNull);
          expect(logResponse!.receivedAt.isAfter(logRequest!.sentAt!), isTrue);
          expect(
            logResponse!.receivedAt.isBefore(DateTime.now().toUtc()),
            isTrue,
          );
        },
      );

      test(
        'should pass request and error to the callback, when is error response',
        () {
          LogRequest? logRequest;
          LogResponse? logResponse;

          final interceptor = LogDioInterceptor(
            logCallback: (request, response) {
              logRequest = request;
              logResponse = response;
            },
          );

          interceptor.onRequest(requestOptions, requestHandler);
          interceptor.onError(errorOptions, errorHandler);

          expect(logRequest, isNotNull);
          expect(logRequest!.url, 'https://testapi.com');
          expect(logRequest!.method, 'POST');
          expect(logRequest!.headers, {'Content-Type': 'application/json'});
          expect(logRequest!.body, {'key': 'value'});
          expect(logRequest!.sentAt, isNotNull);
          expect(logRequest!.sentAt!.isBefore(DateTime.now().toUtc()), isTrue);

          expect(logResponse, isNotNull);
          expect(logResponse!.statusCode, 500);
          expect(logResponse!.headers, {'Content-Type': 'application/json'});
          expect(logResponse!.body, {'errorKey': 'errorValue'});
          expect(logResponse!.hasError, isTrue);
          expect(logResponse!.receivedAt, isNotNull);
          expect(logResponse!.receivedAt.isAfter(logRequest!.sentAt!), isTrue);
          expect(
            logResponse!.receivedAt.isBefore(DateTime.now().toUtc()),
            isTrue,
          );
        },
      );
    });
  });
}
