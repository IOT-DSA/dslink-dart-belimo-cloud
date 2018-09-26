import 'dart:async';

import 'package:dslink/dslink.dart';

import '../client.dart';
import '../../models.dart';

abstract class Account {
  Future<BClient> get client;
}

abstract class OwnerNd {
  Future<Owner> get owner;
  void setOwner(Owner owner);
  String get path;
}

abstract class DeviceNd {
  Future<Device> get device;
  void setDevice(Device device);
  bool get hasSubscription;
  void addSubscription(String datapoint);
  void removeSubscription(String datapoint);
}

class ChildNode extends SimpleNode {
  Future<BClient> getClient() {
    var p = parent;
    while (p != null && p is! Account) {
      p = p.parent;
    }

    return (p as Account)?.client;
  }

  ChildNode(String path) : super(path);
}
