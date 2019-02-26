import 'dart:collection' show HashMap;

import 'package:dslink/utils.dart' show logger;

import 'dataprofiles.dart';

class Owner {
  static final HashMap<String, Owner> _cache = new HashMap<String, Owner>();
  static void clearDevices() {
    for (var own in _cache.values) {
      own.devices.length = 0;
    }
  }

  final String ref;
  String id;
  final String name;
  final String type;
  final List<Device> devices = <Device>[];

  Owner._(this.ref, this.name, this.type) {
    id = ref.split('/').last;
  }

  factory Owner.fromJson(Map<String, String> map) => _cache[map['ref']] ??=
      new Owner._(map['ref'], map['displayName'], map['type']);
}

class Device {
  String id;
  String name;
  String displayName;
  String serial;
  String type;
  String project;
  String city;
  String country;
  bool remoteEnabled = false;
  Owner owner;
  DeviceHealth health;
  DataProfile profile;

  Device.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    displayName = map['displayName'];
    serial = map['serialNumber'];
    type = map['deviceType'];
    project = map['projectName'];
    city = map['addressCity'];
    country = map['addressCountry'];
    remoteEnabled = map['remoteControlEnabled'];

    profile = new DataProfile.fromJson(map['dataprofile']);
    health = new DeviceHealth.fromMap(map['health']);
    owner = new Owner.fromJson(map['owner']);
    owner.devices.add(this);
  }
}

class DeviceHealth {
  DateTime lastSeen;
  String state;
  String description;

  DeviceHealth.fromMap(Map<String, String> map) {
    try {
      if (map['lastSeen'] != null) lastSeen = DateTime.parse(map['lastSeen']);
    } catch (e) {
      logger.warning('DeviceHealth: unable to parse lastSeen date: '
          '${map['lastSeen']}', e);
    }
    state = map['state'];
    description = map['description'];
  }
}
