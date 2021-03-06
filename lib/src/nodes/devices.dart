import 'dart:async';

import 'package:dslink/nodes.dart' show NodeNamer;
import 'package:dslink/dslink.dart' show SimpleNode;

import 'common.dart';
import 'data.dart';
import '../../models.dart' show Owner, Device, DeviceData;

//* @Node
//* @MetaType Owner
//* @Parent Account
//* @Is ownerNode
//*
//* Owner Node is the site and owner of Devices and acts as a collection
//* of the associated devices. The node has a path name of the OwnerID
//* and a display name of the Owner name provided by the remote server.
class OwnerNode extends ChildNode implements OwnerNd {
  static const String isType = 'ownerNode';
  static Map<String, dynamic> definition(Owner own) {
    var ret = {
      r'$is': isType,
      r'$name': own.name,
      //* @Node id
      //* @MetaType OwnerId
      //* @Parent Owner
      //*
      //* Id is the owner ID supplied by the remove server.
      //*
      //* @Value string
      'id' : {
        r'$type' : 'string',
        r'?value' : own.id,
      },
      //* @Node type
      //* @Parent Owner
      //*
      //* Type is the owner type supplied by the remote server.
      //* @Value string
      'type' : {
        r'$name' : 'Type',
        r'$type' : 'string',
        r'?value' : own.type,
      }
    };

    return ret;
  }

  Future<Owner> get owner async {
    if (_owner != null) return _owner;
    return _ownComp.future;
  }

  Owner _owner;
  Completer<Owner> _ownComp;
  void setOwner(Owner own) {
    _owner = own;
    _ownComp.complete(own);
  }

  OwnerNode(String path) : super(path) {
    _ownComp = new Completer<Owner>();
  }

  void update(Owner own) {
    _owner = own;
    displayName = own.name;

    SimpleNode node = children['type'];
    node.updateValue(own.type);
    node = children['id'];
    node.updateValue(own.id);
  }

  Future remove() async {
    var futs = <Future>[];
    for (var cn in children.keys.toList()) {
      futs.add(new Future(() => removeChild(cn)));
    }

    await Future.wait(futs);
    super.remove();
  }
}

//* @Node
//* @MetaType Device
//* @Parent Owner
//* @Is deviceNode
//*
//* Device Node is the device which collects the various data points.
//*
//* There are several devices per site/owner. Each device has its own list of
//* Datapoints which may different from points collected by another device,
//* depending on its profile. It has the path name of the device ID, and the
//* Display name of the device's display name provided by the server.
class DeviceNode extends ChildNode implements DeviceNd {
  static const String isType = 'deviceNode';

  static const String _data = 'data';
  static const String _health = 'health';
  static const String _last = 'lastSeen';
  static const String _state = 'state';
  static const String _desc = 'description';

  static const String _devId = 'id';
  static const String _name  = 'name';
  static const String _projName = 'project';
  static const String _serial = 'serial';
  static const String _devType = 'devType';
  static const String _city = 'addressCity';
  static const String _country = 'addressCountry';
  static const String _remote = 'remote';

  static Map<String, dynamic> definition(Device d) => {
    r'$is': isType,
    r'$name': d.displayName,
    DataDatePoint.pathName: DataDatePoint.definition(),
    DataTimeseries.pathName: DataTimeseries.definition(),
    //* @Node id
    //* @MetaType DeviceId
    //* @Parent Device
    //*
    //* Id is the id of the device as provided by the remote server.
    //* @Value string
    _devId: {
      r'$type': 'string',
      r'?value': d.id,
    },
    //* @Node name
    //* @MetaType DeviceName
    //* @Parent Device
    //*
    //* Name of the device provided by the server. May differ from display name.
    //* @Value string
    _name: {
      r'$name': 'Name',
      r'$type': 'string',
      r'?value': d.name,
    },
    //* @Node project
    //* @Parent Device
    //*
    //* Project name of the device provided by the remote server. This may
    //* be null if the user did not add this value.
    //* @Value string
    _projName : {
      r'$name': 'Project Name',
      r'$type': 'string',
      r'?value': d.project
    },
    //* @Node serial
    //* @Parent Device
    //*
    //* Serial number of the device provided by the remote server.
    //* @Value string
    _serial: {
      r'$name': 'Serial Number',
      r'$type': 'string',
      r'?value': d.serial
    },
    //* @Node devType
    //* @Parent Device
    //*
    //* Device Type specified by the remote server.
    //* @Value string
    _devType: {
      r'$name': 'Device Type',
      r'$type': 'string',
      r'?value': d.type,
    },
    //* @Node dataProfile
    //* @Parent Device
    //*
    //* Data profile used by the device. Specifies the type of data points the
    //* device collects.
    //* @Value string
    'dataProfile': {
      r'$name': 'Data Profile',
      r'$type': 'string',
      r'?value': d.profile.name,
      //* @Node ref
      //* @MetaType DataProfileId
      //* @Parent dataProfile
      //*
      //* Data profile reference specified by the remote server.
      //* @Value string
      'ref': {
        r'$type': 'string',
        r'?value': d.profile.ref,
      },
    },
    _city: {
      r'$name': 'Address City',
      r'$type': 'string',
      r'?value': d.city
    },
    _country: {
      r'$name': 'Address Country',
      r'$type': 'string',
      r'?value': d.country
    },
    _remote: {
      r'$name': 'Remote Control Enabled',
      r'$type': 'bool',
      r'?value': d.remoteEnabled
    },
    //* @Node health
    //* @Parent Device
    //*
    //* Collection of device health related values.
    _health: {
      //* @Node lastSeen
      //* @Parent health
      //*
      //* Date the device was last seen, in ISO8601 Format
      //* @Value string
      _last: {
        r'$name': 'Last Seen',
        r'$type': 'string',
        r'?value': d.health.lastSeen?.toIso8601String(),
      },
      //* @Node state
      //* @Parent health
      //*
      //* The last known device state as provided by remote server.
      //* @Value string
      _state: {
        r'$type': 'string',
        r'?value': d.health.state,
      },
      //* @Node description
      //* @Parent health
      //*
      //* Description of the device's last known state/health.
      //* @Value string
      _desc: {
        r'$type': 'string',
        r'?value': d.health.description,
      },
    },
    //* @Node data
    //* @Parent Device
    //*
    //* Collection of DataValues for this device.
    //*
    //* The collection of DataValues may differ, from other devices depending
    //* on the device profiles. These nodes are automatically generated.
    _data: {},
  };

  Future<Device> get device async {
    if (_device != null) return _device;
    return _devComp.future;
  }
  Completer<Device> _devComp;
  Device _device;
  Set<String> _datapoints;
  bool _isRefreshing = false;

  bool get hasSubscription => _datapoints.isNotEmpty;
  Stream<DeviceData> dataStream;
  StreamSubscription<DeviceData> _subscription;

  DeviceNode(String path): super(path) {
    serializable = false;
    _datapoints = new Set<String>();
    _devComp = new Completer<Device>();
  }

  @override
  void onRemoving() {
    if (_datapoints.isNotEmpty) {
      for (var dp in _datapoints.toList()) {
        removeSubscription(dp);
      }
    }
  }

  void addSubscription(String name) {
    _datapoints.add(name);
    if (dataStream != null) return;

    getClient().then((client) async {
      if (_device == null) {
        await device;
      }
      dataStream = client.subscribeDevice(_device);
      _subscription = dataStream.listen(_loadData);
    });
  }

  void removeSubscription(String name) {
    _datapoints.remove(name);
    if (_datapoints.isEmpty && _subscription != null) {
      var fut = _subscription.cancel();
      // Cancel can sometimes return null (though shouldn't). So watch out
      if (fut != null) {
        fut.then((_) => _subscription = null).catchError((e) {});
      } else {
        _subscription = null;
      }
      dataStream = null;
      getClient().then((client) => client.unsubscribeDevice(_device));
    }
  }

  void setDevice(Device dev) {
    _device = dev;
    _devComp.complete(dev);
    updateDevice(dev, force: true);
  }

  void updateDevice(Device dev, {bool force: false}) {
    _device = dev;
    if (!hasSubscription && !force) return;
    getClient().then((cl) async {
      // In the case of a large queue, it's possible the refresh timer may
      // fire before the previous refresh is finished, resulting in the same
      // device being added to the queue multiple times. isRefreshing prevents
      // this from happening.
      if ((hasSubscription || force) && !_isRefreshing) {
        _isRefreshing = true;
        return cl.getDeviceData(dev);
      }
      return null;
    }).then((DeviceData data) {
      _loadData(data, force: force);
    });

    provider.updateValue('$path/$_devId', dev.id);
    provider.updateValue('$path/$_name', dev.name);
    provider.updateValue('$path/$_projName', dev.project);
    provider.updateValue('$path/$_serial', dev.serial);
    provider.updateValue('$path/$_devType', dev.type);
    provider.updateValue('$path/$_city', dev.city);
    provider.updateValue('$path/$_country', dev.country);
    provider.updateValue('$path/$_remote', dev.remoteEnabled);

    provider.updateValue('$path/$_health/$_last',
        dev.health.lastSeen?.toIso8601String());
    provider.updateValue('$path/$_health/$_state', dev.health.state);
    provider.updateValue('$path/$_health/$_desc', dev.health.description);
  }

  void _loadData(DeviceData data, {bool force: false}) {
    _isRefreshing = false;
    if (data == null || data.values == null || data.values.isEmpty) return;

    if (hasSubscription && !force) {
      for (var dp in _datapoints) {
        var dv = provider.getNode('$path/$_data/$dp');
        if (dv == null) continue;

        var val = data.values.firstWhere((v) => v.name == dp, orElse: () => null);
        if (val == null) continue;

        dv.updateValue(val.value);
      }
      return;
    }

    for(var v in data.values) {
      var ndName = NodeNamer.createName(v.name);
      var dv = provider.getNode('$path/$_data/$ndName');
      if (dv == null) {
        provider.addNode('$path/$_data/$ndName', DataValueNode.definition(v));
      } else {
        dv.updateValue(v.value);
      }
    }
  }
}
