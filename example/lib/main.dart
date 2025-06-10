import 'package:dio/dio.dart';
import 'package:example/page_two.dart';
import 'package:flutter/material.dart';
import 'package:flutter_log_helper/flutter_log_helper.dart';
import 'package:logger/web.dart';

final memoryOutput = MemoryOutput(bufferSize: 50);
var logger = Logger(
  printer: SimplePrinter(),
  output: MultiOutput([memoryOutput, ConsoleOutput()]),
);

final logInterceptor = LogDioInterceptor(
  logCallback: (request, response) {
    logger.d(
      'Request: ${request.method} ${request.url}\n'
      'Headers: ${request.headers}\n'
      'Body: ${request.body}\n'
      'Sent at: ${request.sentAt}',
    );
    logger.d(
      'Status: ${response.hasError ? 'Error' : 'Success'}\n'
      'Response: ${response.statusCode} ${response.headers}\n'
      'Body: ${response.body}\n'
      'Received at: ${response.receivedAt}',
    );
  },
);

final navigationObserver = LogNavigatorObserver(
  callback: (action) {
    logger.d(
      'Navigation action: ${action.type} from ${action.from} to ${action.to} with args ${action.args}',
    );
  },
);

final dio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'))
  ..interceptors.add(logInterceptor);

void main() {
  logger.d('App started');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorObservers: [navigationObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _successRequestInProgress = false;
  bool _errorRequestInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text('Example App'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: Container()),
            FilledButton(
              onPressed: () {
                logger.d('Navigate to other page button pressed');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PageTwo(),
                    settings: RouteSettings(
                      name: 'PageTwo',
                      arguments: 'Some argument for PageTwo',
                    ),
                  ),
                );
              },
              child: Text('Navigate to other Page'),
            ),
            Expanded(child: Container()),
            FilledButton(
              onPressed:
                  _successRequestInProgress
                      ? null
                      : () async {
                        setState(() => _successRequestInProgress = true);
                        try {
                          await dio.post(
                            '/anything',
                            data: {'key': 'value', 'number': 42},
                          );
                        } catch (e) {
                          logger.e('Error during success request: $e');
                        } finally {
                          setState(() => _successRequestInProgress = false);
                        }
                      },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Make a successful HTTP request'),
                  _successRequestInProgress
                      ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
            FilledButton(
              onPressed:
                  _errorRequestInProgress
                      ? null
                      : () async {
                        setState(() => _errorRequestInProgress = true);
                        try {
                          await dio.post('/status/500', data: {'key': 'value'});
                        } catch (e) {
                          logger.e('Error during error request: $e');
                        } finally {
                          setState(() => _errorRequestInProgress = false);
                        }
                      },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Make an error HTTP request'),
                  _errorRequestInProgress
                      ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
            Expanded(child: Container()),
            LogOverlay(
              logs: memoryOutput.buffer.map(
                (l) => l.lines.fold(
                  '',
                  (previousValue, element) =>
                      previousValue.isEmpty
                          ? element
                          : '$previousValue\n$element',
                ),
              ),
              httpLogCache: logInterceptor.httpLogCache,
              navigationLogCache: navigationObserver.navigationLogCache,
              child: Text('Press me 5 times to attach overlay button.'),
            ),
          ],
        ),
      ),
    );
  }
}
