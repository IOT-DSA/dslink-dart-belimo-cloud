import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart' show NodeNamer;

import 'common.dart';
import 'devices.dart';
import '../client.dart';
import '../../models.dart' show Owner, Device;

//* @Action Add_Account
//* @Parent root
//* @Is addAccountNode
//*
//* Add a Belimo Cloud account to the Link.
//*
//* Attempts to add a Belimo cloud account to the DSLink. It will first
//* verify that the display name is not an existing node. It will also
//* attempt to verify the credentials with the remote server. Returns an
//* error message on failure.
//*
//* @Param displayName string Display Name is the name of the node that will
//* be created to host the account.
//* @Param username string Username used to log into the Belimo cloud account.
//* @Param password string Password used to log into the Belimo cloud account.
//*
//* @Return value
//* @Column success bool A boolean which represents if the action succeeded or
//* not. Returns false on failure and true on success.
//* @Column message string If the action succeeds, this will be "Success!", on
//* failure, it will return the error message.
class AddAccount extends SimpleNode {
  static const String isType = 'addAccountNode';
  static const String pathName = 'Add_Account';

  static const String _name = 'displayName';
  static const String _user = 'username';
  static const String _pass = 'password';
  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition() => {
    r'$is' : isType,
    r'$name' : 'Add Account',
    r'$invokable' : 'write',
    r'$params' : [
      {'name': _name, 'type': 'string', 'placeholder': 'Display Name'},
      {'name': _user, 'type': 'string', 'placeholder': 'username'},
      {'name': _pass, 'type': 'string', 'editor': 'password'}
      ],
    r'$columns' : [
      { 'name' : _success, 'type' : 'bool', 'default' : false },
      { 'name' : _message, 'type' : 'string', 'default': '' }
    ]
  };

  LinkProvider _link;

  AddAccount(String path, this._link) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, String> params) async {
    final ret = { _success: false, _message: '' };

    var name = params[_name];
    if (name == null || name.isEmpty) {
      return ret..[_message] = 'Display name cannot be empty';
    }

    var n = NodeNamer.createName(name);
    var nd = provider.getNode('/$n');

    var user = params[_user];
    var pass = params[_pass];
    var cl = new BClient(user, pass);

    ret[_success] = await cl.authenticate();
    if (ret[_success]) {
      if (nd == null) {
        provider.addNode('/$n', AccountNode.definition(user, pass));
      } else {
        (nd as AccountNode)..loadUser()
            ..loadDevices();
      }

      ret[_message] = 'Success!';
      _link.save();
    } else {
      ret[_message] = 'Unable to authenticate with provided credentials';
    }

    return ret;
  }
}

//* @Node
//* @MetaType Account
//* @Parent root
//* @Is accountNode
//*
//* Account node manages the specific Belimo Cloud account.
//*
//* Account Node handles updating the child owners (sites) and devices at each
//* site. When the DSLink starts it will load all owners and devices reported
//* by the remote server. It will then attempt to update these lists every 5
//* minutes.
class AccountNode extends SimpleNode implements Account {
  static const String isType = 'accountNode';

  static const String _user = r'$$username';
  static const String _pass = r'$$password';
  static const String _first = r'first';
  static const String _last = r'last';
  static const String _locale = r'locale';
  static const String _id = 'id';
  static const String _email = 'email';
  static const String _activated = 'activated';
  static const Duration _refDur = const Duration(minutes: 5);

  static Map<String, dynamic> definition(String user, String pass) => {
    r'$is': isType,
    _user: user,
    _pass: pass,
    r'$name': user,
    _id: {
      r'$name': 'Id',
      r'$type': 'string',
      r'?value': ''
    },
    _first: {
      r'$name': 'First Name',
      r'$type': 'string',
      r'?value': ''
    },
    _last: {
      r'$name': 'Last Name',
      r'$type': 'string',
      r'?value': ''
    },
    _email: {
      r'$name': 'email',
      r'$type': 'string',
      r'?value': ''
    },
    _locale: {
      r'$name': 'Locale',
      r'$type': 'string',
      r'?value': ''
    },
    _activated: {
      r'$name': 'activated',
      r'$type': 'bool',
      r'?value': false
    },
    EditAccount.pathName: EditAccount.definition(user),
    RemoveAccount.pathName: RemoveAccount.definition(),
    RefreshDevices.pathName: RefreshDevices.definition()
  };

  BClient _client;
  Completer<BClient> _clComp;

  Future<BClient> get client async {
    if (_client != null) {
      return _client;
    }
    return _clComp.future;
  }

  AccountNode(String path) : super(path) {
    _clComp = new Completer<BClient>();
  }

  @override
  void onCreated() {
    var u = getConfig(_user);
    var p = getConfig(_pass);

    var nd = provider.getNode('$path/${RefreshDevices.pathName}');
    if (nd == null) {
      provider.addNode('$path/${RefreshDevices.pathName}',
          RefreshDevices.definition());
    }

    if (displayName == null || displayName.isEmpty) {
      displayName = u;
    }

    var cl = new BClient(u, p);
    cl.authenticate().then((bool auth) {
      if (auth) {

        _client = cl;
        _clComp.complete(cl);
        loadUser();
        loadDevices();
      } else {
        cl.close();
      }
    });
  }

  Future<Null> loadUser() async {
    var user = await _client.getUser();

    var idN = provider.getNode('$path/$_id');
    if (idN != null) {
      idN.updateValue(user.id);
    } else {
      provider.addNode('$path/$_id', {
        r'$name': 'Id',
        r'$type': 'string',
        r'?value': user.id
      });
    }

    var fName = provider.getNode('$path/$_first');
    if (fName != null) {
      fName.updateValue(user.firstName);
    } else {
      provider.addNode('$path/$_first', {
        r'$name': 'First Name',
        r'$type': 'string',
        r'?value': user.firstName
      });
    }

    var lName = provider.getNode('$path/$_last');
    if (lName != null) {
      lName.updateValue(user.lastName);
    } else {
      provider.addNode('$path/$_last', {
        r'$name': 'Last Name',
        r'$type': 'string',
        r'?value': user.lastName
      });
    }

    var email = provider.getNode('$path/$_email');
    if (email != null) {
      email.updateValue(user.email);
    } else {
      provider.addNode('$path/$_email', {
        r'$name': 'Email',
        r'$type': 'string',
        r'?value': user.email
      });
    }

    var locale = provider.getNode('$path/$_locale');
    if (locale != null) {
      locale.updateValue(user.locale);
    } else {
      provider.addNode('$path/$_locale', {
        r'$name': 'Locale',
        r'$type': 'string',
        r'?value': user.locale
      });
    }

    var active = provider.getNode('$path/$_activated');
    if (active != null) {
      active.updateValue(user.activated);
    } else {
      provider.addNode('$path/$_activated', {
        r'$name': 'activated',
        r'$type': 'bool',
        r'?value': user.activated
      });
    }
  }

  Future<Null> loadDevices() async {
    var owners = await _client.getDevicesByOwner();
    // Check for owners already in nodes.
    for (OwnerNode c in children.values.where((Node nd) => nd is OwnerNode).toList()) {
      Owner own;
      for (var i = 0; i < owners.length; i++) {
        if (c.displayName != owners[i].name) continue;
        own = owners[i];
        break;
      }

      if (own == null) {
        // Not in the new list, get rid of it.
        c.remove();
        continue;
      }

      owners.remove(own); // Remove from list before updating
      c.update(own);

      List<DeviceNode> deviceNodes = c.children.values
          .where((Node nd) => nd is DeviceNode)
          .toList();
      List<Device> ownerDevices = own.devices.toList();
      _updateDevices(deviceNodes, ownerDevices, c.path);

    } // end check for owners already in nodes.

    for (var own in owners) { // Add remaining owners.
      if (own?.name == null) continue;
      var oname = NodeNamer.createName(own.name);
      var opath = '$path/$oname';
      OwnerNode oNd = provider.getNode(opath);
      if (oNd != null) {
        oNd.update(own);
      } else {
        oNd = provider.addNode(opath, OwnerNode.definition(own));
        oNd.setOwner(own);
      }

      for (var dev in own.devices) {
        if (dev?.displayName == null) continue;
        var dname = NodeNamer.createName(dev.displayName);
        var devNd = provider.addNode('${oNd.path}/$dname',
            DeviceNode.definition(dev)) as DeviceNode;
        devNd.setDevice(dev);
      }
    }
  }

  void _updateDevices(List<DeviceNode> nodes, List<Device> devices, String ownPath) {
    for (DeviceNode device in nodes) {
      Device dev;
      for (var i = 0; i < devices.length; i++) {
        if (device.displayName != devices[i].displayName) continue;
        dev = devices[i];
        break;
      }

      if (dev == null) { // Can't find match in the current devices so remove
        device.remove();
        continue;
      }

      devices.remove(dev);
      new Future(() => device.updateDevice(dev));
    }

    for (var dev in devices) {
      if (dev?.displayName == null) continue;
      var dname = NodeNamer.createName(dev.displayName);
      var devNd = provider.addNode('$ownPath/$dname',
          DeviceNode.definition(dev)) as DeviceNode;
      devNd.setDevice(dev);
    }
  }

  Future<Null> _refreshDevices() async {
    if (_client == null) {
      throw new StateError('Client is not authenticated');
    }

    loadUser();
    _client.getDevicesByOwner().then(_populateOwnerDevices);

  }

  @override
  void onRemoving() {
    _client?.close();

    // User this instead of default removeNode because it's more efficient.
    for (var c in children.values.toList()) {
//      _rmNode(c as LocalNode);
      (c as OwnerNode).remove();
    }
  }

  Future<bool> updateAccount(String user, String pass) async {
    var curU = getConfig(_user);
    var curP = getConfig(_pass);

    BClient cl;
    if (pass == null || pass.isEmpty) pass = curP;

    if (curU != user || curP != pass || _client == null) {
      cl = new BClient(user, pass);
    } else {
      return true;
    }

    var auth = await cl.authenticate();
    if (auth) {
      // Only close old if the username is different
      if (curU != user) _client?.close();

      _client = cl;
      configs[_user] = user;
      configs[_pass] = pass;
    }

    return auth;
  }

  // Populate Owners (locations) and devices at each.
  void _populateOwnerDevices(List<Owner> owners) {
    for (var own in owners) {
      var oname = NodeNamer.createName(own.name);
      var oNd = provider.getNode('$path/$oname') as OwnerNode;
      if (oNd == null) {
        oNd = provider.addNode('$path/$oname', OwnerNode.definition(own))
        as OwnerNode;
        oNd.setOwner(own);
      } else {
        (oNd as OwnerNode).update(own);
      }

      List<DeviceNode> deviceNodes = oNd.children.values
          .where((Node nd) => nd is DeviceNode)
          .toList();
      List<Device> devices = own.devices.toList();

      _updateDevices(deviceNodes, devices, oNd.path);
    }

  }
}

//* @Action Edit_Account
//* @Parent Account
//* @Is editAccount
//*
//* Allows you to edit the Belimo Account credentials.
//*
//* Edit Account allows you to edit the account credentials, including username
//* and password. If you omit the password value, it will attempt to use the
//* previously provided password.
//*
//* @Param username string Username used to log into the Belimo cloud account.
//* @Param password string Password used to log into the Belimo cloud account.
//*
//* @Return value
//* @Column success bool A boolean which represents if the action succeeded or
//* not. Returns false on failure and true on success.
//* @Column message string If the action succeeds, this will be "Success!", on
//* failure, it will return the error message.
class EditAccount extends SimpleNode {
  static const String isType = 'editAccount';
  static const String pathName = 'Edit_Account';

  static const String _user = 'username';
  static const String _pass = 'password';
  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition(String user) => {
    r'$is' : isType,
    r'$name' : 'Edit Account',
    r'$invokable' : 'write',
    r'$params' : [
      {'name': _user, 'type': 'string', 'default': user},
      {'name': _pass, 'type': 'string', 'editor': 'password'}
    ],
    r'$columns' : [
      { 'name' : _success, 'type' : 'bool', 'default' : false },
      { 'name' : _message, 'type' : 'string', 'default': '' }
    ]
  };

  LinkProvider _link;

  EditAccount(String path, this._link) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    final ret = { _success: false, _message: '' };

    var u = params[_user];
    var p = params[_pass];
    ret[_success] = await (parent as AccountNode).updateAccount(u, p);

    if (ret[_success]) {
      ret[_message] = 'Success!';
      _link.save();
    } else {
      ret[_message] = 'Unable to authenticate with provided credentials';
    }

    return ret;
  }
}

//* @Action Remove_Account
//* @Parent Account
//* @Is removeAccount
//*
//* Remove an account from the DSLink, closing the associated client.
//*
//* Remove Account will remove the account and child nodes from the DSLink. It
//* will also close the associated client for this account.
//*
//* @Return value
//* @Column success bool A boolean which represents if the action succeeded or
//* not. Returns false on failure and true on success.
//* @Column message string If the action succeeds, this will be "Success!", on
//* failure, it will return the error message.
class RemoveAccount extends SimpleNode {
  static const String isType = 'removeAccount';
  static const String pathName = 'Remove_Account';

  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition() => {
    r'$is' : isType,
    r'$name' : 'Remove Account',
    r'$invokable' : 'write',
    r'$params' : [],
    r'$columns' : [
      { 'name' : _success, 'type' : 'bool', 'default' : false },
      { 'name' : _message, 'type' : 'string', 'default': '' }
    ]
  };

  LinkProvider _link;

  RemoveAccount(String path, this._link) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    final ret = { _success: true, _message: 'Success!' };

    provider.removeNode(parent.path, recurse: false);
    _link.save();

    return ret;
  }
}

class RefreshDevices extends SimpleNode {
  static const String isType = 'refreshDevices';
  static const String pathName = 'Refresh_Devices';

  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition() => {
    r'$is': isType,
    r'$name': 'Refresh Devices',
    r'$invokable': 'write',
    r'$params': [],
    r'$columns': [
      {'name': _success, 'type': 'bool', 'default': false},
      {'name': _message, 'type': 'string', 'default': ''}
    ]
  };

  RefreshDevices(String path) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    final ret = {_success: true, _message: 'Success!'};

    try {
      await (parent as AccountNode)._refreshDevices();
    } on StateError catch (e) {
      return ret..[_success] = false
          ..[_message] = e.message;
    } catch (e) {
      return ret..[_success] = false
          ..[_message] = 'Error: $e';
    }

    return ret;
  }
}