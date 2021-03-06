import 'dart:async';

import 'package:dslink/utils.dart' show logger;

import 'common.dart';
import '../models/data.dart';

//* @Node
//* @MetaType DataValue
//* @Parent data
//* @Is deviceValueNode
//*
//* DataValue is a data point in the associated Device.
//*
//* The DataValues will be automatically generated by the DSLink based on the
//* data points received from the remote server for a device. The path name is
//* the data value's datapoint ID, and the display name is the data value name
//* or description (it will attempt to use a name which does not contain a '/'
//* character from those two fields). The value type may be a bool, number,
//* or string depending on the type provided by the remote server. The value
//* will be the value specified by the remote server.
//*
//* @Value dynamic
class DataValueNode extends ChildNode {
  static const String isType = 'deviceValueNode';
  static Map<String, dynamic> definition(DataValue dv) {
    var ret = {
      r'$is': isType,
//      r'$name': dv.name,
      //* @Node updated
      //* @Parent DataValue
      //*
      //* ISO8601 String of when the value was last updated on server.
      //* @Value string
      'updated': {
        r'$name': 'Updated At',
        r'$type': 'string',
        r'?value': dv.updated?.toIso8601String()
      },
      //* @Node dataId
      //* @Parent DataValue
      //*
      //* Datapoint ID of the value.
      //* @Value string
      'dataId': {
        r'$name': 'Datapoint ID',
        r'$type': 'string',
        r'?value': dv.id ?? dv.name
      }
    };

    try {
      switch (dv.type) {
        case 'Double':
        case 'Integer':
          ret[r'$type'] = 'number';
          ret[r'?value'] = dv.value as num;
          break;
        case 'Boolean':
          ret[r'$type'] = 'bool';
          ret[r'?value'] = dv.value as bool;
          break;
        default:
          ret[r'$type'] = 'string';
          ret[r'?value'] = '${dv.value}';
          break;
      }
    } catch (e) {
      ret[r'$type'] = 'string';
      ret[r'?value'] = '${dv.value}';
    }
    return ret;
  }

  DataValueNode(String path): super(path);

  DeviceNd getDeviceNode() {
    var p = parent;
    while (p != null && p is! DeviceNd) {
      p = p.parent;
    }

    return p;
  }

  @override
  void onSubscribe() {
    var dn = getDeviceNode();
    if (dn != null) {
      dn.addSubscription(name);
    }
  }

  @override
  void onUnsubscribe() {
    var dn = getDeviceNode();
    if (dn != null) {
      dn.removeSubscription(name);
    }
  }

  @override
  void onRemoving() {
    onUnsubscribe();
  }
}

//* @Action Get_Date_Point
//* @Parent Device
//* @Is dataDatePointAction
//*
//* Get Date Point retrieves from the data values from a specified Date/Time.
//*
//* Get Date Point will attempt to retrieve the data values which were logged
//* at or close to the specified time. This will return a table with the names
//* of each DataPoint, the value (dynamic) and the value type specified by
//* the server and DateTime the value was logged in ISO8601 Format.
//*
//* @Param date string Date/Time to retrieve the value for. Uses a DateRange
//* editor, however only the first Date/Time of the range is used to retrieve
//* the values.
//*
//* @Return table
//* @Column name string DataPoint name of the value.
//* @Column value dynamic The value of the DataValue at that time.
//* @Column valueType string The value type specified by the server. May be
//* String, bool, Integer, Double, etc.
//* @Column updatedAt string ISO8601 formatted string indicating when the value
//* was actually updated on the remote server.
class DataDatePoint extends ChildNode {
  static const String isType = 'dataDatePointAction';
  static const String pathName = 'Get_Date_Point';

  static const String _date = 'date';
  static const String _name = 'name';
  static const String _value = 'value';
  static const String _valType = 'valueType';
  static const String _updated = 'updatedAt';

  static Map<String, dynamic> definition() => {
    r'$is': isType,
    r'$name': 'Get Data on Date',
    r'$invokable': 'write',
    r'$params': [
      {'name': _date, 'type': 'string', 'editor': 'daterange'}
    ],
    r'$result': 'table',
    r'$columns': [
      {'name': _name, 'type': 'string', 'default': '' },
      {'name': _value, 'type': 'dynamic', 'default': null },
      {'name': _valType, 'type': 'string', 'default': 'String'},
      {'name': _updated, 'type': 'string', 'default': '0000-00-00T00:00:00.000Z'}
    ]
  };

  DataDatePoint(String path) : super(path);

  @override
  Future<List<List>> onInvoke(Map<String, String> params) async {
    var ret = new List<List>();
    var dev = await (parent as DeviceNd).device;
    var cl = await getClient();

    var dt = params[_date].split('/')[0];
    DateTime date;
    try {
      date = DateTime.parse(dt);
    } catch (e) {
      logger.warning('Unable to parse date: $dt', e);
      rethrow;
    }

    var res = await cl.getDeviceData(dev, date.millisecondsSinceEpoch);
    if (res == null || res.values.isEmpty) return ret;
    for (var val in res.values) {
      ret.add([val.name, val.value, val.type, val.updated?.toIso8601String()]);
    }
    return ret;
  }
}


//* @Action Timeseries_Data
//* @Parent Device
//* @Is dataTimeseries
//*
//* Get historical data of a device as a time series.
//*
//* Timeseries Data retrieves the mean values of the DataValues over a specified
//* Date/Time range with the total number of results to be provided specified.
//* (Eg: 7 day period with 14 results would be 2 results per day). Results are
//* returned as a table, grouped by datapoint name.
//*
//* @Param dateRange string Date/Time range to load the values.
//* @Param dataIds string A comma separated list of DataPoint Ids to retrieve
//* values for over the specified time range.
//* @Param numValues num Integer number of values over the specified time
//* range to return.
//*
//* @Return table
//* @Column name string Data point name of the value.
//* @Column value dynamic Mean value of the datapoint over the specified range.
//* @Column timestamp string ISO8601 formatted string of the timestamp for the
//* data
class DataTimeseries extends ChildNode {
  static const String isType = 'dataTimeseries';
  static const String pathName = 'Timeseries_Data';

  static const String _dataIds = 'dataIds';
  static const String _dateRange = 'dateRange';
  static const String _numValues = 'numValues';
  static const String _name = 'name';
  static const String _value = 'value';
  static const String _timestamp = 'timestamp';

  static Map<String, dynamic> definition() => {
    r'$is': isType,
    r'$name': 'Timeseries Data',
    r'$invokable': 'write',
    r'$params': [
      {'name': _dateRange, 'type': 'string', 'editor': 'daterange'},
      {
        'name': _dataIds,
        'type': 'string',
        'description': 'comma separated list of data point Ids'
      },
      {
        'name': _numValues,
        'type': 'number',
        'editor': 'int',
        'description': 'Number of values within timespan'
      }
    ],
    r'$result': 'table',
    r'$columns': [
      {'name': _name, 'type': 'string', 'default': ''},
      {'name': _value, 'type': 'dynamic', 'default': null},
      {'name': _timestamp, 'type': 'string', 'default':'0000-00-00T00:00:00.000Z'}
    ]
  };

  DataTimeseries(String path) : super(path);
  
  @override
  Future<List<List>> onInvoke(Map<String, dynamic> params) async {
    final ret = new List<List>();
    var dev = await (parent as DeviceNd).device;
    var cl = await getClient();

    var idsStr = params[_dataIds] as String;
    var id = idsStr.split(',')..forEach((st) => st.trim());
    idsStr = id.join(',');

    var times = (params[_dateRange] as String).split('/');
    DateTime from;
    DateTime to;
    int res;
    try {
      from = DateTime.parse(times[0]);
      to = DateTime.parse(times[1]);
      res = (params[_numValues] as num).toInt();
    } catch (e) {
      logger.warning('Unable to parse dates', e);
      return ret;
    }
    var resp = await cl.getTimeseriesData(
        dev,
        idsStr,
        from.toUtc().toIso8601String(),
        to.toUtc().toIso8601String(),
        res);

    if (resp == null) return ret;
    for (var ds in resp) {
      ret.add([ds.name, ds.value, ds.updated?.toIso8601String()]);
    }

    return ret;
  }
}
