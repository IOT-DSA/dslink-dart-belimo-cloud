# Belimo Cloud DSLink

A DSLink for Belimo Cloud API (v3).

### Versions

* 1.5.4 - Cleanup and optimize remove account.
* 1.5.3 - Address some possible sources of null references if DeviceData API query returns invalid data, and a rare
          corner case where closing subscription caused a crash. 
* 1.5.1 - Fix bug in remove account. Ensure node is OwnerNode so we don't remove actions.
* 1.5.0 - On refresh interval, only update device datapoints not all owners and devices on a given account.
* 1.4.0 - Change Add_Account action to verify username/password if account is already added.
* 1.3.9 - Update User data (name, address etc) with each refresh every 5 minutes
* 1.3.8 - Update DSLink SDK for fix with updating list subscriptions
* 1.3.7 - Check for existing pending requests before adding a new one. Compare device, API and 
          query parameters.
* 1.3.6+1 - Remove more debug logging
* 1.3.6 - Provide a "Queue Level" metric on the root node to track current request queue. Remove some
  debug logging.
* 1.3.5 - Move Basic-token and endpoint to dslink configuration.
* 1.3.4 - Improve performance of Remove Account action. 
* 1.3.3 - Update to reflect change in dataprofile reference already including leading `/`
* 1.3.2 - Re-Authenticate if encountering a token error.
        - Remove any queued requests when removing accounts.
        - Fix issue with Timeseries Data calling wrong API
* 1.3.1 - Ensure Timeseries data also respects throttling.
* 1.3.0 - Respect queue and request throttling for remote server.
        - Only send a max of 5 simultaneous device data queries per DSLink instance.
        - Due to total queue length, prevent a device from being queued twice.
* 1.2.0 - Only load data for devices which have an active subscription.
        - Resolve a bug where the last ten devices of an account may not be retrieved.
* 1.1.7 - Add User details to account (First/last name, email, locale, account activated)
* 1.1.6 - Use username as account display name
* 1.1.5 - Better recursive node removal to ensure no memory leaks.
* 1.1.4 - Fix performance issue when removing nodes prior to re-populating.
* 1.1.3 - Remove HTTP dependency. Prevent redundant http requests on startup. 
* 1.1.2 - Fix crashes when refreshing devices.
* 1.1.1 - Fix link crash if DateTime parsing fails (also log when that occurs). Add checks for authentication when
  refreshing devices or editing configurations.
* 1.1.0 - Add Refresh Devices action accounts. This will re-poll for the devices associated with an account and
  repopulate any data with them.
* 1.0.7 - Allow unknown `metadata.*` points to prevent crashes. Add City/Country, Project Name and RemoteControlEnabled
  fields
* 1.0.6 - Add fake Datapoint for `metadata.1001` to prevent crash. Unknown
  datapoint type.
* 1.0.4 - Change pathnames to use Name rather than ID. So displayed path name
  should match the path
* 1.0.3 - Add support for Datapoints for Location, Longitude, and Latitude

## Usage

After installing the link, you will need to first configure the required basic-token and endpoint link configuration
values. This can be done within Solution Builder by expanding the `sys` > `links` > `<Link name, eg Belimo>` > `configs`
node, then locate the metric `basic-token` and right click and choose `@set`. Set the value to the basic authentication
token you were provided. You can also set the `endpoint` value, however if it is left blank, it will default
to `https://cloud.belimo.com`.