import 'dart:collection' show HashMap;

class DataProfile {
  static final HashMap<String, DataProfile> _cache =
      new HashMap<String,DataProfile>();

  final String name;
  final String ref;
  final HashMap<String, DataPoint> _points = new HashMap<String, DataPoint>();
  bool loaded = false;

  DataProfile._(this.ref, this.name);

  factory DataProfile(String ref, String name) {
    var dp = _cache[ref];
    if (dp == null) {
      _cache[ref] = new DataProfile._(ref, name);
      dp = _cache[ref];
      dp['metadata.1012'] = new DataPoint._('metadata.1012', 'Latitude', 'meta');
      dp['metadata.1013'] = new DataPoint._('metadata.1013', 'Longitude', 'meta');
      dp['metadata.1014'] = new DataPoint._('metadata.1014', 'Location', 'meta');
      dp['metadata.1001'] = new DataPoint._('metadata.1001', 'SomeName?', 'meta');
    }
    return dp;
  }

  factory DataProfile.fromJson(Map<String, String> map) =>
      new DataProfile(map['ref'], map['displayName']);

  DataPoint operator [](String key) => _points[key];
  void operator []=(String key, DataPoint dp) {
    _points[key] = dp;
  }

  Iterable<String> get keys => _points.keys;
}

class DataPoint {
  String id;
  String name;
  String type;

  DataPoint.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    name = map['featureValues']['default.name'];
    if (name.contains('/')) {
      name = map['featureValues']['default.description'];
    }
    type = map['featureValues']['sharedLogicType.type'];
  }

  DataPoint._(this.id, this.name, this.type);
}
