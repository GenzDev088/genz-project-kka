import 'dart:io';

void main() {
  final file = File('lib/tools_gateway.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'Navigator.pop(context);\n          Navigator.push',
    'Navigator.push',
  );
  content = content.replaceAll(
    'Navigator.pop(context);\r\n          Navigator.push',
    'Navigator.push',
  );
  content = content.replaceAll(
    RegExp(r'Navigator\.pop\(context\);\s*Navigator\.push'),
    'Navigator.push',
  );
  file.writeAsStringSync(content);
  print('Done');
}
