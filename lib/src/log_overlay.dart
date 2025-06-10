import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_log_helper/src/log_dio_interceptor.dart';
import 'package:flutter_log_helper/src/log_navigation_observer.dart';
import 'package:share_plus/share_plus.dart';

/// A widget that overlays an other widget to show an overlay button, which opens a  when tapped 5 times.
///
/// Use like this:
/// ```dart
/// LogOverlay(
///   logs: logs, // Iterable<String> with logs
///   httpLogCache: logInterceptor.httpLogCache,
///   navigationLogCache: navigationObserver.navigationLogCache,
///   onSharePressed: () {
///    // Provide your own share action
///   },
///   child: Text('Version: 2.0.3-abc'), // The widget which can be tapped
/// );
/// ```
class LogOverlay extends StatefulWidget {
  final Iterable<String>? _logs;
  final List<(LogRequest request, LogResponse response)>? _httpLogCache;
  final List<LogNavigationAction>? _navigationLogCache;
  final void Function()? _onSharePressed;

  const LogOverlay({
    super.key,
    Iterable<String>? logs,
    List<(LogRequest request, LogResponse response)>? httpLogCache,
    List<LogNavigationAction>? navigationLogCache,
    void Function()? onSharePressed,
    required Widget child,
  }) : _logs = logs,
       _httpLogCache = httpLogCache,
       _navigationLogCache = navigationLogCache,
       _onSharePressed = onSharePressed,
       _child = child;

  final Widget _child;

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  static const _timesToPressToAttachButton = 5;
  var _timesPressed = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _timesPressed++;
        });

        if (_timesPressed >= _timesToPressToAttachButton &&
            !LogOverlayButton.isAttached()) {
          LogOverlayButton.attach(
            context: context,
            logs: widget._logs,
            httpLogCache: widget._httpLogCache,
            navigationLogCache: widget._navigationLogCache,
            onSharePressed: widget._onSharePressed,
          );
        }
      },
      child: widget._child,
    );
  }
}

/// A button that overlays the screen and opens a log entry page when tapped.
///
/// Use like this:
/// ```dart
/// LogOverlayButton.attach(
///   context: context,
///   logs: logs, // Iterable<String> with logs
///   httpLogCache: logInterceptor.httpLogCache,
///   navigationLogCache: navigationObserver.navigationLogCache,
///   onSharePressed: () {
///   // Handle share action
///   },
/// );
/// ```
class LogOverlayButton extends StatefulWidget {
  static OverlayEntry? _entry;

  final Iterable<String>? _logs;
  final List<(LogRequest request, LogResponse response)>? _httpLogCache;
  final List<LogNavigationAction>? _navigationLogCache;
  final void Function()? _onSharePressed;

  const LogOverlayButton({
    super.key,
    Iterable<String>? logs,
    List<(LogRequest request, LogResponse response)>? httpLogCache,
    List<LogNavigationAction>? navigationLogCache,
    void Function()? onSharePressed,
  }) : _logs = logs,
       _httpLogCache = httpLogCache,
       _navigationLogCache = navigationLogCache,
       _onSharePressed = onSharePressed;

  static void attach({
    required BuildContext context,
    Iterable<String>? logs,
    List<(LogRequest request, LogResponse response)>? httpLogCache,
    List<LogNavigationAction>? navigationLogCache,
    required void Function()? onSharePressed,
  }) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder:
          (ctx) => LogOverlayButton(
            logs: logs,
            httpLogCache: httpLogCache,
            navigationLogCache: navigationLogCache,
            onSharePressed: onSharePressed,
          ),
    );
    final overlay = Overlay.of(context);
    overlay.insert(_entry!);
  }

  static bool isAttached() {
    return _entry != null;
  }

  static void detach() {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
    }
  }

  @override
  State<LogOverlayButton> createState() => _LogOverlayButtonState();
}

class _LogOverlayButtonState extends State<LogOverlayButton>
    with SingleTickerProviderStateMixin {
  static const _buttonWidth = 24.0;
  static const _buttonPadding = 8.0;
  static const _edgeMargin = 8.0;

  late final AnimationController _animationController;
  Animation<Offset>? _animation;
  Offset _offset = Offset.zero;
  bool _isDragging = false;
  bool _pageOpened = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _offset = Offset(
            size.width - (_buttonWidth + _buttonPadding * 2 + 8) - _edgeMargin,
            (size.height / 2) - _edgeMargin,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanStart:
            (details) => setState(() {
              _isDragging = true;
            }),
        onPanUpdate: _updatePosition,
        onPanEnd: (_) => _snapToEdge(),
        child: IconButton.filledTonal(
          onPressed:
              _isDragging
                  ? null
                  : () {
                    if (_LogEntryPageState.isOpened &&
                        Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => _LogEntryPage(
                                logs: widget._logs,
                                httpLogCache: widget._httpLogCache,
                                navigationLogCache: widget._navigationLogCache,
                                onSharePressed: widget._onSharePressed,
                              ),
                          settings: const RouteSettings(name: '/logEntry'),
                        ),
                      );
                    }

                    setState(() {
                      _pageOpened = !_pageOpened;
                    });
                  },
          icon: Icon(Icons.terminal),
          iconSize: _buttonWidth,
          padding: EdgeInsets.all(_buttonPadding),
        ),
      ),
    );
  }

  void _updatePosition(DragUpdateDetails details) {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    setState(() {
      _offset = Offset(
        (_offset.dx + details.delta.dx).clamp(
          0,
          size.width - (_buttonWidth + _buttonPadding * 2),
        ),
        (_offset.dy + details.delta.dy).clamp(
          0,
          size.height - (_buttonWidth + _buttonPadding * 2),
        ),
      );
    });
  }

  void _snapToEdge() {
    final size = MediaQuery.of(context).size;

    final distanceToLeft = _offset.dx;
    final distanceToRight =
        size.width - (_offset.dx + (_buttonWidth + _buttonPadding * 2));

    final positionX =
        distanceToLeft < distanceToRight
            ? _edgeMargin
            : size.width -
                (_buttonWidth + _buttonPadding * 2 + 8) -
                _edgeMargin;

    _animation = Tween<Offset>(
      begin: _offset,
      end: Offset(positionX, _offset.dy),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutExpo),
    )..addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _offset = _animation!.value;
      });
    });

    _animationController.reset();
    _animationController.forward();

    setState(() => _isDragging = false);
  }
}

class _LogEntryPage extends StatefulWidget {
  final Iterable<String>? _logs;
  final List<(LogRequest request, LogResponse response)>? _httpLogCache;
  final List<LogNavigationAction>? _navigationLogCache;
  final void Function()? _onSharePressed;

  const _LogEntryPage({
    Iterable<String>? logs,
    List<(LogRequest request, LogResponse response)>? httpLogCache,
    List<LogNavigationAction>? navigationLogCache,
    void Function()? onSharePressed,
  }) : _logs = logs,
       _httpLogCache = httpLogCache,
       _navigationLogCache = navigationLogCache,
       _onSharePressed = onSharePressed;

  @override
  State<_LogEntryPage> createState() => _LogEntryPageState();
}

class _LogEntryPageState extends State<_LogEntryPage> {
  static bool isOpened = false;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    isOpened = true;
    _scrollController = ScrollController();

    // Scroll to bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    isOpened = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabCount =
        [
          widget._logs,
          widget._httpLogCache,
          widget._navigationLogCache,
        ].where((e) => e != null).length;

    if (tabCount == 0) {
      return Center(
        child: Text(
          'No logs available',
          style: TextTheme.of(context).bodyMedium,
        ),
      );
    }

    return DefaultTabController(
      initialIndex: 0,
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          actions: [
            IconButton(
              onPressed:
                  widget._onSharePressed ??
                  () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Logs:\n\n${widget._logs?.join('\n') ?? 'No logs available'}\n\nHTTP Requests:\n\n${widget._httpLogCache?.map((e) => '${e.$1}\n${e.$2}').join('\n') ?? 'No HTTP requests available'}\n\nNavigation Logs:\n\n${widget._navigationLogCache?.map((e) => e.toString()).join('\n') ?? 'No navigation logs available'}',
                      ),
                    );
                  },
              icon: Icon(Icons.share),
            ),
          ],
          title: Text('Logs'),
          bottom: TabBar(
            tabs: [
              if (widget._logs != null) Tab(text: 'Logs'),
              if (widget._httpLogCache != null) Tab(text: 'Http Requests'),
              if (widget._navigationLogCache != null) Tab(text: 'Navigation'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (widget._logs != null)
              ListView(
                padding: EdgeInsets.all(8),
                controller: _scrollController,
                children: [
                  for (final log in widget._logs!)
                    _LogEntryWidget(logEntry: log),
                ],
              ),
            if (widget._httpLogCache != null)
              ListView(
                padding: EdgeInsets.all(8),
                children: [
                  for (final entry in widget._httpLogCache!)
                    _HttpRequestWidget(request: entry.$1, response: entry.$2),
                ],
              ),
            if (widget._navigationLogCache != null)
              ListView(
                padding: EdgeInsets.all(8),
                children: [
                  for (final logEntry in widget._navigationLogCache!)
                    _NavigationLogWidget(logEntry: logEntry),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationLogWidget extends StatelessWidget {
  final LogNavigationAction _logEntry;

  const _NavigationLogWidget({required LogNavigationAction logEntry})
    : _logEntry = logEntry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: _logEntry.toString()));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: const Text('Copied to clipboard!')));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_logEntry.timestamp.hour.toString().padLeft(2, '0')}:${_logEntry.timestamp.minute.toString().padLeft(2, '0')}:${_logEntry.timestamp.second.toString().padLeft(2, '0')} - ${_logEntry.type.name} from ${_logEntry.from} to ${_logEntry.to}',
              style: TextTheme.of(context).bodyMedium,
            ),

            Text(
              'Arguments: ${_logEntry.args}',
              style: TextTheme.of(context).bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntryWidget extends StatelessWidget {
  final String _logEntry;

  const _LogEntryWidget({required String logEntry}) : _logEntry = logEntry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: _logEntry));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: const Text('Copied to clipboard!')));
        },
        child: Text(_logEntry, style: TextTheme.of(context).bodySmall),
      ),
    );
  }
}

class _HttpRequestWidget extends StatefulWidget {
  final LogRequest _request;
  final LogResponse _response;

  const _HttpRequestWidget({
    required LogRequest request,
    required LogResponse response,
  }) : _request = request,
       _response = response;

  @override
  State<_HttpRequestWidget> createState() => _HttpRequestWidgetState();
}

class _HttpRequestWidgetState extends State<_HttpRequestWidget> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _opened = !_opened;
          });
        },
        onLongPress: () {
          Clipboard.setData(
            ClipboardData(text: '${widget._request}\n\n${widget._response}'),
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: const Text('Copied to clipboard!')));
        },
        child: Row(
          children: [
            Icon(_opened ? Icons.arrow_drop_down : Icons.arrow_right),

            _opened
                ? Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget._request.method} ${widget._request.url}',
                        style: TextTheme.of(context).bodyMedium,
                      ),

                      Text(
                        'Sent at: ${widget._request.sentAt?.toIso8601String()}',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Text(
                        'Request Headers:',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      for (final header in widget._request.headers.entries)
                        Text(
                          '${header.key}: ${header.value}',
                          style: TextTheme.of(context).bodySmall,
                        ),
                      Text(
                        'Request Body:',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Text(
                        widget._request.body.toString(),
                        style: TextTheme.of(context).bodySmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Response Status: ${widget._response.statusCode}',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Text(
                        'Received at: ${widget._response.receivedAt.toIso8601String()}',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Text(
                        'Duration: ${widget._response.receivedAt.difference(widget._request.sentAt ?? widget._response.receivedAt).inMilliseconds}ms',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Text(
                        'Response Headers:',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      for (final header in widget._response.headers.entries)
                        Text(
                          '${header.key}: ${header.value}',
                          style: TextTheme.of(context).bodySmall,
                        ),
                      Text(
                        'Response Body:',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Text(
                        widget._response.body.toString(),
                        style: TextTheme.of(context).bodySmall,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        maxLines: 10,
                      ),
                    ],
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget._request.method} ${widget._request.url}',
                      style: TextTheme.of(context).bodyMedium,
                    ),
                    Text(
                      'Status: ${widget._response.statusCode} - ${widget._request.sentAt?.hour.toString().padLeft(2, '0')}:${widget._request.sentAt?.minute.toString().padLeft(2, '0')}:${widget._request.sentAt?.second.toString().padLeft(2, '0')} - ${widget._response.receivedAt.difference(widget._request.sentAt ?? widget._response.receivedAt).inMilliseconds}ms',
                      style: TextTheme.of(context).bodySmall,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
