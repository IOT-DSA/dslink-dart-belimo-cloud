import 'dart:async';
import 'dart:convert' show JSON, UTF8;
import 'dart:io';

import 'package:dslink/utils.dart' show logger;

import '../models.dart';

abstract class PathHelper {
  static String oauth() => 'oauth/token';

  static const String _v3 = 'api/v3';
  static String devices() => '$_v3/devices';
  static String user() => '$_v3/user';
  static String deviceData(String id) => '${devices()}/$id/data';
  static String timeseries(String id) => '${deviceData(id)}/history/timeseries';

  static String dataProfiles(String ref) => '$_v3$ref';
}

// DataRequests are only when trying to query deviceData (see path helper).
// This is because only these requests are rate limited to 2 requests per second.
class DataRequest {
  final BClient client;
  final Device device;
  final Map<String, String> query;
  final String path;

  Future<Map<String,dynamic>> get future => _completer.future;

  Completer<Map<String,dynamic>> _completer;

  DataRequest(this.client, this.device, this.query, this.path) {
    _completer = new Completer<Map<String,dynamic>>();
  }
}

class BClient {
  static const Duration _timeOut = const Duration(seconds: 30);
  static const String _headerAuth = 'Authorization';
  static const String _basicAuth = 'Basic ';
  static const String _bearerAuth = 'Bearer';
  static const int _maxPending = 5;

  static StreamController<int> _controller = new StreamController<int>();
  static Stream<int> get stream => _controller.stream;
  static String rootUrl;
  static String basicToken;

  static final List<DataRequest> _queue = <DataRequest>[];
  static final Map<String, BClient> _cache = <String, BClient>{};
  static int _pendingDataRequests = 0;

//  Client _client;
  HttpClient _client;
  String user;
  String _pass;
  Uri _root;
  String _accessTok;
  int _queuedRequests = 0;
  bool get _authed => _accessTok != null && _accessTok.isNotEmpty;

  static Future<Map<String,dynamic>> _addDataRequest(DataRequest data) {
    _queue.add(data);
    _controller.add(_queue.length);
    _sendDataRequests();
    return data.future;
  }

  static Future _sendDataRequests() async {
    while (_queue.isNotEmpty && _pendingDataRequests < _maxPending) {
      var dr = _queue.removeAt(0);
      _controller.add(_queue.length);
      // Don't use await here, or it will block the loop
      dr.client._sendRequest(dr.query, dr.path).then(_processDataResult(dr));
      _pendingDataRequests += 1;
    }
  }

  static Function _processDataResult(DataRequest data) {
    return (Map<String, dynamic> map) {
      _pendingDataRequests -= 1;
      _sendDataRequests(); // Trigger another cycle

      if (map.containsKey('error')) {
        logger.warning('Received error loading device data: Device: ' +
            '${data.device.name} Response: $map');
        data._completer.complete(null);
        return;
      }

      data._completer.complete(map);
    };
  }

  factory BClient(String username, String password) {
    var cl = _cache[username] ??= new BClient._(username, password);
    if (password != cl._pass) {
      cl._pass = password;
      cl._accessTok = null;
    }
    return cl;
  }

  BClient._(this.user, this._pass) {
    _client = new HttpClient();
    _root = Uri.parse(rootUrl);
  }

  /// Attempt to authenticate to remote cloud server with the credentials
  /// provided. Returns true on success and false on failure.
  Future<bool> authenticate() async {
    if (_authed) return _authed;

    if (basicToken == null || basicToken.isEmpty) {
      throw new StateError('Required basic-token has not been supplied.');
    }

    var uri = _root.replace(path: PathHelper.oauth());

    Map bd;
    HttpClientResponse resp;
    try {
      var req = await _client.postUrl(uri);
      req.headers.set(_headerAuth, _basicAuth + basicToken);
      req.headers.contentType =
          ContentType.parse('application/x-www-form-urlencoded');
      req.write('grant_type=password&' +
          'username=${Uri.encodeQueryComponent(user)}&' +
          'password=${Uri.encodeQueryComponent(_pass)}');

      resp = await req.close();
      bd = await JSON.decode(await UTF8.decodeStream(resp));
    } catch (e) {
      logger.warning('Failed to decode response body', e);
    }

    if (resp.statusCode != HttpStatus.OK) {
      logger.warning('Failed to authenticate. Status code ${resp.statusCode}');
      if (bd != null) {
        logger.warning('Error: ${bd['error']} '
            'Description: ${bd['error_description']}');
      }
      return false;
    }

    if (bd == null || bd['access_token'] == null) {
      logger.warning('Authorization: Status OK but no access_token available.' +
        'body is: $bd');
      return false;
    }
    _accessTok = bd['access_token'];

    return true;
  }

  // getUser returns a [User] object associated with the user for this account.
  Future<User> getUser() async {
    var resp = await _sendRequest(null, PathHelper.user());

    return new User.fromJson(resp);
  }

  /// getDevicesByOwner will return a list of [Owner]s and the associated
  /// devices with each Owner.
  Future<List<Owner>> getDevicesByOwner() async {
    var owners = new Set<Owner>();
    var q = {
      'state': 'ALL',
      'parts': 'ALL',
    };

    Owner.clearDevices();

    await for(var data in _getMultiRequest(q, PathHelper.devices())) {
      if (data.containsKey('error')) break;

      for (var dev in data['data'] as List) {
        var device = new Device.fromJson(dev);
        if (!device.profile.loaded) {
          await getDataProfiles(device.profile);
        }

        owners.add(device.owner);
      }
    }

    return owners.toList();
  }

  /// Get [DeviceData] from the specified Device ID *devId* optionally specify
  /// *at* as miliseconds since epoch to define when, otherwise it uses _now_
  Future<DeviceData> getDeviceData(Device dev, [int at]) async {
    if (dev == null) return null;
    Map query;
    if (at != null) {
      query = {'at': '$at'};
    }

    var dr = new DataRequest(this, dev, query, PathHelper.deviceData(dev.id));
    _queuedRequests += 1;
    Map map;
    try {
      map = await _addDataRequest(dr);
    } on CloseException {
      logger.info('Device Data request cancelled. Account removed.');
      return null;
    } finally {
      _queuedRequests -= 1;
    }

    DeviceData dd;
    try {
      dd = new DeviceData.fromJson(dev.profile, map);
    } catch (e) {
      logger.warning('Error parsing DeviceData: $map', e);
    }

    return dd;
  }

  Future<Null> getDataProfiles(DataProfile dp) async {
    if (dp.loaded) return;
    var resp = await _sendRequest(null, PathHelper.dataProfiles(dp.ref));

    if (resp == null || resp['datapoints'] == null) {
      logger.warning('Unable to retrieve datapoints for: ${dp.ref}');
      return;
    }
    for (Map pt in resp['datapoints'] as List) {
      var p = new DataPoint.fromJson(pt);
      dp[p.id] = p;
    }
    dp.loaded = true;
  }

  Future<List<DataSeries>> getTimeseriesData(Device dev, String ids,
      String from, String to, int resolution) async {
    if (dev == null) return null;

    Map query = {
      'datapointIds': ids,
      'resolution': '$resolution'
    };
    if (from != null) {
      query['from'] = '$from';
    }
    if (to != null) {
      query['to'] = '$to';
    }

    var dr = new DataRequest(this, dev, query, PathHelper.timeseries(dev.id));
    _queuedRequests += 1;
    Map resp;

    try {
      resp = await _addDataRequest(dr);
    } on CloseException {
      logger.info('Account being removed. Timeseries Request cancelled.');
      return <DataSeries>[];
    } finally {
      _queuedRequests -= 1;
    }

    var list = new List<DataSeries>();

    if (resp == null || resp.isEmpty) {
      logger.warning('[Account: $user] - Data request failed on device: ${dev.id}');
      return list;
    }

    List<Map> allSeries = resp['series'];
    if (allSeries == null || allSeries.isEmpty) {
      logger.warning('[Account: $user] - No series data to return for ids: $ids');
      return list;
    }

    for(var series in allSeries) {
      var dp = dev.profile[series['datapointId']];

      List<Map> values = series['values'];
      if (values == null || values.isEmpty) {
        logger.warning('No series values for datapoint: ${dp.name}');
        continue;
      }

      for(var v in (series['values'] as List<Map>)) {
        list.add(new DataSeries.fromJson(dp, v));
      }
    }

    return list;
  }

  /// Return a Stream of Map bodies to support requests with paging.
  Stream<Map> _getMultiRequest(Map<String, String> query, String path) async* {
    var q = query ?? <String, String>{};
    var offset = 0;
    var pageSize = 10;
    var total = 0;

    do {
      q['limit'] = '$pageSize';
      q['offset'] = '$offset';

      var body = await _sendRequest(q, path);
      if (body == null) break;
      yield body;

      var pg = body['paging'];
      if (pg == null) break;
      if (pg['total'] == null || pg['limit'] == null) break;
      total = pg['total'];
      offset += pg['limit'];
    } while (total >= offset);

  }

  /// Return single request
  Future<Map> _sendRequest(Map<String, String> query, String path) async {
    var q = query ?? <String,String>{};

    var uri = _root.replace(queryParameters: q, path: path);

    Map body;
    try {
      var req = await _client.getUrl(uri).timeout(_timeOut);
      req.headers.set(_headerAuth, '$_bearerAuth $_accessTok');
      var resp = await req.close().timeout(_timeOut);
      body = JSON.decode(await UTF8.decodeStream(resp));
      logger.finest('Request: "$path" Response body: $body');
    } catch (e) {
      logger.warning(
          'Error receiving response. Query: $query Path: $path', e);
    }

    if (body != null && body['error'] == 'invalid_token') {
      logger.info('Token expired, trying to reauthenticate.');
      _accessTok = null;

      var authed = await authenticate();
      if (authed) {
        return _sendRequest(query, path);
      }

      logger.warning('Failed to re-authenticate.');
    }

    return body;
  }

  /// Close the client connection and remove the client from cache.
  void close() {
    if (_queuedRequests > 0) {
      _queue.removeWhere((data) {
        if (data.client == this) {
          data._completer.completeError(new CloseException('Cancelled'));
          return true;
        }
        return false;
      });
    }

    _accessTok = null;
    _client.close(force: true);
    _cache.remove(user);
  }
}

class CloseException implements Exception {
  final String message;
  CloseException([this.message]);

  String toString() {
    if (message == null) return 'CloseException';
    return 'CloseException: $message';
  }
}
