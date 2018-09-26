 <pre>
-[root](#root)
 |-[@Add_Account(displayName, username, password)](#add_account)
 |-[Account](#account)
 | |-[@Edit_Account(username, password)](#edit_account)
 | |-[@Remove_Account()](#remove_account)
 | |-[Owner](#owner)
 | | |-[id](#id) - string
 | | |-[type](#type) - string
 | | |-[Device](#device)
 | | | |-[@Get_Date_Point(date)](#get_date_point)
 | | | |-[@Timeseries_Data(dateRange, dataIds, numValues)](#timeseries_data)
 | | | |-[id](#id) - string
 | | | |-[name](#name) - string
 | | | |-[serial](#serial) - string
 | | | |-[devType](#devtype) - string
 | | | |-[dataProfile](#dataprofile) - string
 | | | | |-[id](#id) - string
 | | | |-[health](#health)
 | | | | |-[lastSeen](#lastseen) - string
 | | | | |-[state](#state) - string
 | | | | |-[description](#description) - string
 | | | |-[data](#data)
 | | | | |-[DataValue](#datavalue) - dynamic
 | | | | | |-[updated](#updated) - string
 | | | | | |-[dataId](#dataid) - string
 </pre>

---

### root  

Root node of the DsLink  

Type: Node   

---

### Add_Account  

Add a Belimo Cloud account to the Link.  

Type: Action   
$is: addAccountNode   
Parent: [root](#root)  

Description:  
Attempts to add a Belimo cloud account to the DSLink. It will first verify that the display name is not an existing node. It will also attempt to verify the credentials with the remote server. Returns an error message on failure.  

Params:  

Name | Type | Description
--- | --- | ---
displayName | `string` | Display Name is the name of the node that will be created to host the account.
username | `string` | Username used to log into the Belimo cloud account.
password | `string` | Password used to log into the Belimo cloud account.

Return type: value   
Columns:  

Name | Type | Description
--- | --- | ---
success | `bool` | A boolean which represents if the action succeeded or not. Returns false on failure and true on success. 
message | `string` | If the action succeeds, this will be "Success!", on failure, it will return the error message. 

---

### Account  

Account node manages the specific Belimo Cloud account.  

Type: Node   
$is: accountNode   
Parent: [root](#root)  

Description:  
Account Node handles updating the child owners (sites) and devices at each site. When the DSLink starts it will load all owners and devices reported by the remote server. It will then attempt to update these lists every 5 minutes.  


---

### Edit_Account  

Allows you to edit the Belimo Account credentials.  

Type: Action   
$is: editAccount   
Parent: [Account](#account)  

Description:  
Edit Account allows you to edit the account credentials, including username and password. If you omit the password value, it will attempt to use the previously provided password.  

Params:  

Name | Type | Description
--- | --- | ---
username | `string` | Username used to log into the Belimo cloud account.
password | `string` | Password used to log into the Belimo cloud account.

Return type: value   
Columns:  

Name | Type | Description
--- | --- | ---
success | `bool` | A boolean which represents if the action succeeded or not. Returns false on failure and true on success. 
message | `string` | If the action succeeds, this will be "Success!", on failure, it will return the error message. 

---

### Remove_Account  

Remove an account from the DSLink, closing the associated client.  

Type: Action   
$is: removeAccount   
Parent: [Account](#account)  

Description:  
Remove Account will remove the account and child nodes from the DSLink. It will also close the associated client for this account.  

Return type: value   
Columns:  

Name | Type | Description
--- | --- | ---
success | `bool` | A boolean which represents if the action succeeded or not. Returns false on failure and true on success. 
message | `string` | If the action succeeds, this will be "Success!", on failure, it will return the error message. 

---

### Owner  

Owner Node is the site and owner of Devices and acts as a collection of the associated devices. The node has a path name of the OwnerID and a display name of the Owner name provided by the remote server.  

Type: Node   
$is: ownerNode   
Parent: [Account](#account)  

---

### id  

Id is the owner ID supplied by the remove server.  

Type: Node   
Parent: [Owner](#owner)  
Value Type: `string`  
Writable: `never`  

---

### type  

Type is the owner type supplied by the remote server.  

Type: Node   
Parent: [Owner](#owner)  
Value Type: `string`  
Writable: `never`  

---

### Device  

Device Node is the device which collects the various data points.  

Type: Node   
$is: deviceNode   
Parent: [Owner](#owner)  

Description:  
There are several devices per site/owner. Each device has its own list of Datapoints which may different from points collected by another device, depending on its profile. It has the path name of the device ID, and the Display name of the device's display name provided by the server.  


---

### Get_Date_Point  

Get Date Point retrieves from the data values from a specified Date/Time.  

Type: Action   
$is: dataDatePointAction   
Parent: [Device](#device)  

Description:  
Get Date Point will attempt to retrieve the data values which were logged at or close to the specified time. This will return a table with the names of each DataPoint, the value (dynamic) and the value type specified by the server and DateTime the value was logged in ISO8601 Format.  

Params:  

Name | Type | Description
--- | --- | ---
date | `string` | Date/Time to retrieve the value for. Uses a DateRange editor, however only the first Date/Time of the range is used to retrieve the values.

Return type: table   
Columns:  

Name | Type | Description
--- | --- | ---
name | `string` | DataPoint name of the value. 
value | `dynamic` | The value of the DataValue at that time. 
valueType | `string` | The value type specified by the server. May be String, bool, Integer, Double, etc. 
updatedAt | `string` | ISO8601 formatted string indicating when the value was actually updated on the remote server. 

---

### Timeseries_Data  

Get historical data of a device as a time series.  

Type: Action   
$is: dataTimeseries   
Parent: [Device](#device)  

Description:  
Timeseries Data retrieves the mean values of the DataValues over a specified Date/Time range with the total number of results to be provided specified. (Eg: 7 day period with 14 results would be 2 results per day). Results are returned as a table, grouped by datapoint name.  

Params:  

Name | Type | Description
--- | --- | ---
dateRange | `string` | Date/Time range to load the values.
dataIds | `string` | A comma separated list of DataPoint Ids to retrieve values for over the specified time range.
numValues | `num` | Integer number of values over the specified time range to return.

Return type: table   
Columns:  

Name | Type | Description
--- | --- | ---
name | `string` | Data point name of the value. 
value | `dynamic` | Mean value of the datapoint over the specified range. 
timestamp | `string` | ISO8601 formatted string of the timestamp for the data 

---

### id  

Id is the id of the device as provided by the remote server.  

Type: Node   
Parent: [Device](#device)  
Value Type: `string`  
Writable: `never`  

---

### name  

Name of the device provided by the server. May differ from display name.  

Type: Node   
Parent: [Device](#device)  
Value Type: `string`  
Writable: `never`  

---

### serial  

Serial number of the device provided by the remote server.  

Type: Node   
Parent: [Device](#device)  
Value Type: `string`  
Writable: `never`  

---

### devType  

Device Type specified by the remote server.  

Type: Node   
Parent: [Device](#device)  
Value Type: `string`  
Writable: `never`  

---

### dataProfile  

Data profile used by the device. Specifies the type of data points the device collects.  

Type: Node   
Parent: [Device](#device)  
Value Type: `string`  
Writable: `never`  

---

### id  

Data profile ID specified by the remote server.  

Type: Node   
Parent: [dataProfile](#dataprofile)  
Value Type: `string`  
Writable: `never`  

---

### health  

Collection of device health related values.  

Type: Node   
Parent: [Device](#device)  

---

### lastSeen  

Date the device was last seen, in ISO8601 Format  

Type: Node   
Parent: [health](#health)  
Value Type: `string`  
Writable: `never`  

---

### state  

The last known device state as provided by remote server.  

Type: Node   
Parent: [health](#health)  
Value Type: `string`  
Writable: `never`  

---

### description  

Description of the device's last known state/health.  

Type: Node   
Parent: [health](#health)  
Value Type: `string`  
Writable: `never`  

---

### data  

Collection of DataValues for this device.  

Type: Node   
Parent: [Device](#device)  

Description:  
The collection of DataValues may differ, from other devices depending on the device profiles. These nodes are automatically generated.  


---

### DataValue  

DataValue is a data point in the associated Device.  

Type: Node   
$is: deviceValueNode   
Parent: [data](#data)  

Description:  
The DataValues will be automatically generated by the DSLink based on the data points received from the remote server for a device. The path name is the data value's datapoint ID, and the display name is the data value name or description (it will attempt to use a name which does not contain a '/' character from those two fields). The value type may be a bool, number, or string depending on the type provided by the remote server. The value will be the value specified by the remote server.  

Value Type: `dynamic`  
Writable: `never`  

---

### updated  

ISO8601 String of when the value was last updated on server.  

Type: Node   
Parent: [DataValue](#datavalue)  
Value Type: `string`  
Writable: `never`  

---

### dataId  

Datapoint ID of the value.  

Type: Node   
Parent: [DataValue](#datavalue)  
Value Type: `string`  
Writable: `never`  

---

