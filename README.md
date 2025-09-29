# colored_dio_logger

`colored_dio_logger` is a **Dio interceptor** that provides beautifully formatted and **color-coded logs** for your HTTP requests, responses, and errors.  
It helps developers **debug network calls faster** by making log output clean, structured, and easy to scan at a glance.


## Demo 
![image](https://github.com/user-attachments/assets/1fc4590b-9085-4076-9e45-ec4432494224)

![image](https://github.com/user-attachments/assets/ea2020f7-6aa3-484f-adb9-bbf8c966012d)


![image](https://github.com/user-attachments/assets/ff49e7e3-ce28-4d68-bb09-ff37d730b94d)



## Installation
Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  colored_dio_logger: ^0.1.0
```

Then run : 
```dart
  flutter pub get
```

## Usage
Simply add ```ColoredDioLogger``` to your Dio interceptors:

```dart
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
        defaultColor: PrettyDioLoggerColors.cyan,
        errorColor: PrettyDioLoggerColors.red,
        requestColor: PrettyDioLoggerColors.green,
        responseColor: PrettyDioLoggerColors.magenta,
        headerColor: PrettyDioLoggerColors.yellow,
        responseHeaderColor: PrettyDioLoggerColors.red,
        responseStatusColor: PrettyDioLoggerColors.blue,        maxWidth: 90,
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
```

## Features

🌈 Colored logs for requests, responses, and errors
📡 Logs headers and bodies with customization
⚡ Configurable options (compact mode, max width, filtering)
🛠 Works seamlessly with Dio


## License
This project is licensed under the MIT License. See the LICENSE file for details.


