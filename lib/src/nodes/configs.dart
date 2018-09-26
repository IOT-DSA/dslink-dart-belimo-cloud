import 'package:dslink/dslink.dart';

class ConfigNode extends SimpleNode {
  static Map<String,dynamic> def(String name, {String value: ''}) => {
    r'$name': name,
    r'$type': 'string',
    r'?value': value,
    r'$writable': 'config'
  };

  ConfigNode(String path) : super(path);
}