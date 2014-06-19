# DeviceDump

Displays info about the currently connected iOS devices.

## Installation

1. Clone the repository:

`$ git clone https://github.com/qiffp/DeviceDump.git`

2. Build and install `devicedump` to `/usr/bin/local/`:

`$ rake install`

## Use

Default output:
`$ devicedump`

```
1 device connected:

Device name: Someone's iPad
Model: iPad Mini
OS version: 7.1.1
Type: iPad2,5
Model number: MD528
Serial number: [device serial number]
UDID: [40 character device identifier]
```

Format output as JSON with `--json` option:

```
{
  "devices" : [
    {
      "model" : "iPad Mini",
      "os_version" : "7.1.1",
      "udid" : "[40 character device identifier]",
      "model_number" : "MD528",
      "type" : "iPad2,5",
      "name" : "Someone's iPad",
      "serial_number" : "[device serial number]"
    }
  ]
}
```

==

Built using a modified version of [MobileDeviceAccess](https://bitbucket.org/tristero/mobiledeviceaccess) by [Jeff Laing (tristero)](https://bitbucket.org/tristero).
