import 'package:colored_dio_logger/colored_dio_logger.dart';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio()
    ..interceptors.add(
      ColoredDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        headerColor: ColoredDioLoggerColors.yellow,
        responseColor: ColoredDioLoggerColors.magenta,
        errorColor: ColoredDioLoggerColors.red,
        requestColor: ColoredDioLoggerColors.blue,
        bodyColor: ColoredDioLoggerColors.green,
        maxWidth: 90,
        filter: (options, args) {
          //  return !options.uri.path.contains('posts');
          return !args.isResponse || !args.hasUint8ListData;
        },
      ),
    );
  try {
    await dio.get('https://jsonplaceholder.typicode.com/posts/1');
  } catch (e) {
    print(e);
  }
}
