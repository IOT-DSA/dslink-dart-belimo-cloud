import 'package:dslink/utils.dart' show logger;

import 'dataprofiles.dart';

class DeviceData {
  DateTime timestamp;
  List<DataValue> values;

  DeviceData.fromJson(DataProfile profile, Map<String, dynamic> map) {
    if (map == null) throw new ArgumentError.notNull("map");

    try {
      if (map['timestamp'] != null) timestamp = DateTime.parse(map['timestamp']);
    } catch (e) {
      logger.warning('DeviceData: Unable to parse timestamp '
          '${map['timestamp']}', e);
    }

    values = new List<DataValue>();
    var points = map['datapoints'] as Map<String, Map>;
    points.forEach((String dataname, Map<String, dynamic> map) {
      var datapoint = profile[dataname];
      values.add(new DataValue.fromJson(datapoint, map, dataname, timestamp));
    });
  }
}

class DataValue {
  DateTime updated;
  dynamic value;
  DataPoint _dp;
  String get id => _dp?.id;
  String get type => _dp?.type;
  String get name => _dp?.name ?? _defName;
  String _defName;

  DataValue(this._dp, this.value);

  DataValue.fromJson(this._dp, Map<String, dynamic> map, this._defName, this.updated) {
    if (map == null) throw new ArgumentError.notNull("map");

    value = map['value'];
  }
}

class DataSeries extends DataValue {
  DataSeries.fromJson(DataPoint dp, Map<String, dynamic> map):
        super(dp, map['value']) {
    if (map == null) throw new ArgumentError.notNull("map");

    try {
      if (map['timestamp'] != null) updated = DateTime.parse(map['timestamp']);
    } catch (e) {
      logger.warning('DataSeries: Unable to parse timestamp '
        '${map['timestamp']}', e);
    }
  }
}
