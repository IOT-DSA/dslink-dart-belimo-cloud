import "package:dslink/dslink.dart";

import "package:dslink_belimo_cloud/belimo_cloud.dart";
import "package:dslink_belimo_cloud/src/client.dart";
import "package:args/args.dart";

main(List<String> args) async {
  LinkProvider link;

  link = new LinkProvider(args, "Belimo-", autoInitialize: false, profiles: {
      AddAccount.isType: (String path) => new AddAccount(path, link),
      AccountNode.isType: (String path) => new AccountNode(path),
      EditAccount.isType: (String path) => new EditAccount(path, link),
      RemoveAccount.isType: (String path) => new RemoveAccount(path, link),
      RefreshDevices.isType: (String path) => new RefreshDevices(path),
      OwnerNode.isType: (String path) => new OwnerNode(path),
      DeviceNode.isType: (String path) => new DeviceNode(path),
      DataValueNode.isType: (String path) => new DataValueNode(path),
      DataDatePoint.isType: (String path) => new DataDatePoint(path),
      DataTimeseries.isType: (String path) => new DataTimeseries(path),
      QueueLevel.isType: (String path) => new QueueLevel(path)
  }, defaultNodes: {
      AddAccount.pathName: AddAccount.definition(),
      QueueLevel.pathName: QueueLevel.def()
  });
  
  var ap = new ArgParser(allowTrailingOptions: true);
  ap..addOption("endpoint", help: "Belimo Cloud endpoint URL", defaultsTo: "https://cloud.belimo.com")
    ..addOption("basic-token", help: "Basic authentication token");

  link.configure(argp: ap);

  BClient.rootUrl = link.parsedArguments['endpoint'];
  BClient.basicToken = link.parsedArguments['basic-token'];

  link.init();
  await link.connect();
}

