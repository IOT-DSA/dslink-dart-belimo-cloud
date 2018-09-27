import 'package:dslink/dslink.dart';

import '../client.dart';

class QueueLevel extends SimpleNode {
  static const String isType = 'queueLevelNode';
  static const String pathName = 'Queue_Level';

  static Map<String, dynamic> def() => {
    r'$is': isType,
    r'$name': 'Queue Level',
    r'$type': 'number',
    r'?value': 0
  };

  QueueLevel(String path) : super(path);

  @override
  void onCreated() {
    BClient.stream.listen((int count) => updateValue(count));
  }
}