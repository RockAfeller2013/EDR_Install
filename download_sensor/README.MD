## Download Carbon Black EDR Sensors

https://developer.carbonblack.com/reference/enterprise-response/latest/rest-api/#download-sensor-installer

Download Sensor Installer
/api/v1/group/<groupid>/installer/windows/exe

/api/v1/group/<groupid>/installer/windows/msi

/api/v1/group/<groupid>/installer/osx

/api/v1/group/<groupid>/installer/linux

Download a zip archive including a sensor installer for Windows, Mac OS X or Linux.

Supports: GET

Parameters None

Returns

(Windows) ZIP archive including a signed Windows EXE or MSI sensor installer and settings file
(Mac OS X) ZIP archive including a signed OSX PKG sensor installer and settings file
(Linux) compressed tarball (tar.gz) archive including a Linux sensor installer and settings f
