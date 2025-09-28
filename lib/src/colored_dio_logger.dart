import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';

const _timeStampKey = '_pdl_timeStamp_';

/// Enum representing the different ANSI colors used for logging output.
/// These colors are typically used to differentiate between log types like
/// requests, responses, headers, errors, and more.
enum ColoredDioLoggerColors {
  /// Represents the color red. Typically used to highlight errors or warnings.
  red,

  /// Represents the color black. Can be used for neutral or default log output.
  black,

  /// Represents the color green. Often used to highlight success messages or positive responses.
  green,

  /// Represents the color yellow. Typically used for warnings or cautionary logs.
  yellow,

  /// Represents the color blue. Can be used to indicate informational logs.
  blue,

  /// Represents the color magenta. Used for visual distinction in logs.
  magenta,

  /// Represents the color cyan. Used to highlight certain informational logs.
  cyan,

  /// Represents the color white. Often used for neutral log output or defaults.
  white,

  /// Resets the color back to default terminal color. Useful for clearing any previous color changes.
  reset,
}

/// A utility class that provides ANSI escape codes for adding colors to text
/// output in the terminal or debug console.
///
/// These color codes can be prefixed to a string before printing, and reset
/// afterward, to render the string in the desired color (if the environment
/// supports ANSI escape sequences).
class DebugConsoleColors {
  /// Resets the text color back to the default terminal color.
  static const reset = '\x1B[0m';

  /// Sets the text color to red.
  /// Commonly used to indicate errors or critical messages.
  static const red = '\x1B[31m';

  /// Sets the text color to green.
  /// Typically used to indicate success or positive outcomes.
  static const green = '\x1B[32m';

  /// Sets the text color to yellow.
  /// Useful for warnings or cautionary messages.
  static const yellow = '\x1B[33m';

  /// Sets the text color to blue.
  /// Often used for informational or neutral logs.
  static const blue = '\x1B[34m';

  /// Sets the text color to magenta (purple).
  /// Can be used to highlight specific categories of logs.
  static const magenta = '\x1B[35m';

  /// Sets the text color to cyan (aqua).
  /// Useful for drawing attention to debug or trace messages.
  static const cyan = '\x1B[36m';

  /// Sets the text color to white.
  /// Often used for neutral logs or to reset styling without a full reset.
  static const white = '\x1B[37m';

  ///set the next colot to black
  ///often used in white mode logs
  static const black = '\x1B[30m';
}

/// A Colored logger for Dio
/// it will print request/response info with a colored format
/// and also can filter the request/response by [RequestOptions]
class ColoredDioLogger extends Interceptor {
  /// Print request [Options]
  final bool request;

  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request data [Options.data]
  final bool requestBody;

  /// Print [Response.data]
  final bool responseBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print error message
  final bool error;

  /// InitialTab count to logPrint json response
  static const int kInitialTab = 1;

  /// 1 tab length
  static const String tabStep = '    ';

  /// Print compact json response
  final bool compact;

  /// Width size per logPrint
  final int maxWidth;

  /// Size in which the Uint8List will be split
  static const int chunkSize = 20;

  /// Log printer; defaults logPrint log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file.
  final void Function(Object object) logPrint;

  /// Filter request/response by [RequestOptions]
  final bool Function(RequestOptions options, FilterArgs args)? filter;

  /// Enable logPrint
  final bool enabled;

  /// The color used for printing request information.
  /// Can be customized to highlight request logs in specific colors.
  ColoredDioLoggerColors? requestColor;

  /// The color used for printing header information.
  /// Customize the color for visibility of header logs.
  ColoredDioLoggerColors? headerColor;

  /// The color used for printing the request or response body.
  /// Useful to differentiate the body content visually.
  ColoredDioLoggerColors? bodyColor;

  /// The color used for printing error messages.
  /// Helps in highlighting errors in a specific color.
  ColoredDioLoggerColors? errorColor;

  /// The color used for printing the response information.
  /// Can be customized for visual clarity of response logs.
  ColoredDioLoggerColors? responseColor;

  /// The color used for printing response headers.
  /// Customize this to easily spot response header logs.
  ColoredDioLoggerColors? responseHeaderColor;

  /// The color used for printing response status.
  /// Useful for highlighting response status like 200, 404, etc.
  ColoredDioLoggerColors? responseStatusColor;

  /// The default color used for printing when no specific color is assigned.
  /// Acts as a fallback color for general logs.
  ColoredDioLoggerColors? defaultColor;

  /// Default constructor
  ColoredDioLogger({
    this.request = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.maxWidth = 90,
    this.compact = true,
    this.logPrint = print,
    this.filter,
    this.enabled = true,
    this.defaultColor,
    this.requestColor,
    this.headerColor,
    this.bodyColor,
    this.errorColor,
    this.responseColor,
    this.responseHeaderColor,
    this.responseStatusColor,
  }) {
    defaultColor ??= ColoredDioLoggerColors.reset;
    requestColor ??= defaultColor;
    headerColor ??= defaultColor;
    bodyColor ??= defaultColor;
    errorColor ??= defaultColor;
    responseColor ??= defaultColor;
    responseHeaderColor ??= defaultColor;
    responseStatusColor ??= defaultColor;
  }

  /// Returns the appropriate ANSI escape code for a given [ColoredDioLoggerColors] value.
  ///
  /// This method maps a color enum value to its corresponding terminal color code.
  /// If the current environment does not support ANSI escape sequences
  /// (i.e., `stdout.supportsAnsiEscapes` is `false`), it falls back to using the
  /// predefined constants in [DebugConsoleColors].
  String getTextColors(ColoredDioLoggerColors color) {
    if (color == ColoredDioLoggerColors.black) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[30m'
          : DebugConsoleColors.reset;
    } else if (color == ColoredDioLoggerColors.red) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[31m'
          : DebugConsoleColors.red;
    } else if (color == ColoredDioLoggerColors.green) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[32m'
          : DebugConsoleColors.green;
    } else if (color == ColoredDioLoggerColors.yellow) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[33m'
          : DebugConsoleColors.yellow;
    } else if (color == ColoredDioLoggerColors.blue) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[34m'
          : DebugConsoleColors.blue;
    } else if (color == ColoredDioLoggerColors.magenta) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[35m'
          : DebugConsoleColors.magenta;
    } else if (color == ColoredDioLoggerColors.cyan) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[36m'
          : DebugConsoleColors.cyan;
    } else if (color == ColoredDioLoggerColors.white) {
      return stdout.supportsAnsiEscapes
          ? '\u001b[37m'
          : DebugConsoleColors.white;
    } else {
      return stdout.supportsAnsiEscapes
          ? '\u001b[0m'
          : DebugConsoleColors.reset;
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final extra = Map.of(options.extra);
    options.extra[_timeStampKey] = DateTime.timestamp().millisecondsSinceEpoch;

    if (!enabled ||
        (filter != null &&
            !filter!(options, FilterArgs(false, options.data)))) {
      handler.next(options);
      return;
    }

    if (request) {
      _printRequestHeader(getTextColors(requestColor!), options);
    }
    if (requestHeader) {
      _printMapAsTable(getTextColors(headerColor!), options.queryParameters,
          header: 'Query Parameters');
      final requestHeaders = <String, dynamic>{};
      requestHeaders.addAll(options.headers);
      if (options.contentType != null) {
        requestHeaders['contentType'] = options.contentType?.toString();
      }
      requestHeaders['responseType'] = options.responseType.toString();
      requestHeaders['followRedirects'] = options.followRedirects;
      if (options.connectTimeout != null) {
        requestHeaders['connectTimeout'] = options.connectTimeout?.toString();
      }
      if (options.receiveTimeout != null) {
        requestHeaders['receiveTimeout'] = options.receiveTimeout?.toString();
      }
      _printMapAsTable(getTextColors(headerColor!), requestHeaders,
          header: 'Headers');
      _printMapAsTable(getTextColors(headerColor!), extra, header: 'Extras');
    }
    if (requestBody && options.method != 'GET') {
      final dynamic data = options.data;
      if (data != null) {
        if (data is Map) {
          _printMapAsTable(getTextColors(bodyColor!), options.data as Map?,
              header: 'Body');
        }
        if (data is FormData) {
          final formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          _printMapAsTable(getTextColors(bodyColor!), formDataMap,
              header: 'Form data | ${data.boundary}');
        } else {
          _printBlock(getTextColors(bodyColor!), data.toString());
        }
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled ||
        (filter != null &&
            !filter!(
                err.requestOptions, FilterArgs(true, err.response?.data)))) {
      handler.next(err);
      return;
    }

    final triggerTime = err.requestOptions.extra[_timeStampKey];
    logPrint(getTextColors(errorColor!));

    if (error) {
      if (err.type == DioExceptionType.badResponse) {
        final uri = err.response?.requestOptions.uri;
        int diff = 0;
        if (triggerTime is int) {
          diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
        }
        _printBoxed(getTextColors(errorColor!),
            header:
                'DioError ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage} ║ Time: $diff ms',
            text: uri.toString());
        if (err.response != null && err.response?.data != null) {
          logPrint('${getTextColors(errorColor!)}╔ ${err.type.toString()}');
          _printResponse(getTextColors(errorColor!), err.response!);
        }
        _printLine(getTextColors(errorColor!), '╚');
        logPrint('');
      } else {
        _printBoxed(getTextColors(errorColor!),
            header: 'DioError ║ ${err.type}', text: err.message);
      }
    }
    handler.next(err);
    logPrint(getTextColors(ColoredDioLoggerColors.reset));
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled ||
        (filter != null &&
            !filter!(
                response.requestOptions, FilterArgs(true, response.data)))) {
      handler.next(response);
      return;
    }

    final triggerTime = response.requestOptions.extra[_timeStampKey];

    int diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }
    _printResponseHeader(getTextColors(responseColor!), response, diff);
    if (responseHeader) {
      logPrint(getTextColors(responseHeaderColor!));
      final responseHeaders = <String, String>{};
      response.headers
          .forEach((k, list) => responseHeaders[k] = list.toString());
      _printMapAsTable(getTextColors(responseColor!), responseHeaders,
          header: 'Headers');
      logPrint(getTextColors(ColoredDioLoggerColors.reset));
    }

    if (responseBody) {
      logPrint(getTextColors(responseColor!));
      logPrint('${getTextColors(responseColor!)}╔ Body');
      logPrint('${getTextColors(responseColor!)}║');
      _printResponse(
        getTextColors(responseColor!),
        response,
      );
      logPrint('${getTextColors(responseColor!)}║');
      _printLine('${getTextColors(responseColor!)}╚');
      logPrint(getTextColors(ColoredDioLoggerColors.reset));
    }
    handler.next(response);
  }

  void _printBoxed(String textColor, {String? header, String? text}) {
    logPrint('$textColor╔╣ $header');
    logPrint('$textColor║  $text');
    _printLine(textColor, '╚');
  }

  void _printResponse(String textColor, Response response) {
    if (response.data != null) {
      if (response.data is Map) {
        _printColoredMap(textColor, response.data as Map);
      } else if (response.data is Uint8List) {
        logPrint('$textColor║${_indent()}[');
        _printUint8List(textColor, response.data as Uint8List);
        logPrint('$textColor║${_indent()}]');
      } else if (response.data is List) {
        logPrint('$textColor║${_indent()}[');
        _printList(textColor, response.data as List);
        logPrint('$textColor║${_indent()}]');
      } else {
        _printBlock(textColor, response.data.toString());
      }
    }
  }

  void _printResponseHeader(
      String textColor, Response response, int responseTime) {
    final uri = response.requestOptions.uri;
    final method = response.requestOptions.method;
    _printBoxed(textColor,
        header:
            'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}  ║ Time: $responseTime ms',
        text: uri.toString());
  }

  void _printRequestHeader(String tesxtColor, RequestOptions options) {
    final uri = options.uri;
    final method = options.method;
    _printBoxed(
      tesxtColor,
      header: 'Request ║ $method ',
      text: uri.toString(),
    );
  }

  void _printLine(String textColor, [String pre = '', String suf = '╝']) =>
      logPrint('$textColor$pre${'═' * maxWidth}$suf');

  void _printKV(String textColor, String? key, Object? v) {
    final pre = '╟ $key: ';
    final msg = v.toString();

    if (pre.length + msg.length > maxWidth) {
      logPrint(textColor + pre);
      _printBlock(textColor, msg);
    } else {
      logPrint('$textColor$pre$msg');
    }
  }

  void _printBlock(String textColor, String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      logPrint(textColor +
          (i >= 0 ? '║ ' : '') +
          msg.substring(i * maxWidth,
              math.min<int>(i * maxWidth + maxWidth, msg.length)));
    }
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  void _printColoredMap(
    String textColor,
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logPrint('$textColor║$initialIndent{');

    for (var index = 0; index < data.length; index++) {
      final isLast = index == data.length - 1;
      final key = '"${data.keys.elementAt(index)}"';
      dynamic value = data[data.keys.elementAt(index)];
      if (value is String) {
        value = '"${value.toString().replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint(
              '$textColor║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}');
        } else {
          logPrint('$textColor║${_indent(tabs)} $key: {');
          _printColoredMap(textColor, value, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint('$textColor║${_indent(tabs)} $key: ${value.toString()}');
        } else {
          logPrint('$textColor║${_indent(tabs)} $key: [');
          _printList(textColor, value, tabs: tabs);
          logPrint('$textColor║${_indent(tabs)} ]${isLast ? '' : ','}');
        }
      } else {
        final msg = value.toString().replaceAll('\n', '');
        final indent = _indent(tabs);
        final linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final lines = (msg.length / linWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            final multilineKey = i == 0 ? "$key:" : "";
            logPrint(
                '$textColor║${_indent(tabs)} $multilineKey ${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}');
          }
        } else {
          logPrint(
              '$textColor║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}');
        }
      }
    }

    logPrint('$textColor║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printList(String textColor, List list, {int tabs = kInitialTab}) {
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final isLast = i == list.length - 1;
      if (element is Map) {
        if (compact && _canFlattenMap(element)) {
          logPrint(
              '$textColor║${_indent(tabs)}  $element${!isLast ? ',' : ''}');
        } else {
          _printColoredMap(
            textColor,
            element,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
          );
        }
      } else {
        logPrint(
            '$textColor║${_indent(tabs + 2)} $element${isLast ? '' : ','}');
      }
    }
  }

  void _printUint8List(String textColor, Uint8List list,
      {int tabs = kInitialTab}) {
    var chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
            i, i + chunkSize > list.length ? list.length : i + chunkSize),
      );
    }
    for (var element in chunks) {
      logPrint('$textColor║${_indent(tabs)} ${element.join(", ")}');
    }
  }

  bool _canFlattenMap(Map map) {
    return map.values
            .where((dynamic val) => val is Map || val is List)
            .isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printMapAsTable(String textColor, Map? map, {String? header}) {
    if (map == null || map.isEmpty) return;
    logPrint('$textColor╔ $header ');
    for (final entry in map.entries) {
      _printKV(textColor, entry.key.toString(), entry.value);
    }
    _printLine('$textColor╚');
  }
}

/// Filter arguments
class FilterArgs {
  /// If the filter is for a request or response
  final bool isResponse;

  /// if the [isResponse] is false, the data is the [RequestOptions.data]
  /// if the [isResponse] is true, the data is the [Response.data]
  final dynamic data;

  /// Returns true if the data is a string
  bool get hasStringData => data is String;

  /// Returns true if the data is a map
  bool get hasMapData => data is Map;

  /// Returns true if the data is a list
  bool get hasListData => data is List;

  /// Returns true if the data is a Uint8List
  bool get hasUint8ListData => data is Uint8List;

  /// Returns true if the data is a json data
  bool get hasJsonData => hasMapData || hasListData;

  /// Default constructor
  const FilterArgs(this.isResponse, this.data);
}
