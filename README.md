

Vertiv™ Trellis™ - Unofficial/Community Maintenance Scripts
===========================================================

License
-------
This collection of scripts is subject to BSD 3-Clause license included [here](./LICENSE.md), they are unsupported and are provided for convenience.

Please ensure you have familiarized yourself with the license, usage of these scripts in part or whole constitute acceptance of these terms.

Document Change History
-----------------------
| Release   | Release Date      | Notes                                     | QR   |
|-----------|-------------------|-------------------------------------------|------|
| 0.1       | 2019/11/01        | Initial draft                             | N/A  |

Scripts
-------
### Clear Aged Logs

#### File Name
`maintenance_log-archive.sh`

#### Type
Bash Shell (Linux)

#### Description
This script will collect logs between the current date and the limit N days (default 7) and archive them into a single tar.gz file. This can be used for reactive support tasks to collect logs for troubleshooting or proactively to archive log files off to a separate location.

The script will auto detect whether it is running on the front or back server, on the front server it will detect the WebLogic domain then proceed to recursively collect logs in the following locations.

#### Instructions
The script has potential to be damaging if it is tampered with, thus it is recommended that it is marked as read-only to prevent tampering.

1. Create scripts folder.
   ```shell
   mkdir /u05/scripts
   ```

2. Copy script to the folder as root or similar elevated user.

3. Ensure owner is root or similar.
   ```shell
   chown root:root /u05/scripts/maintenance_log-archive.sh
   ```

4. Modify permissions so it is read
   ```shell
   chmod 755 /u05/scripts/maintenance_log-archive.sh
   ```

#### Scheduling
The script can be scheduled for running every Sunday by editing the oracle user's crontab, if different intervals are required the script should be modified accordingly.

```shell
1 0 * * 0       /u05/scripts/maintenance_log-archive.sh
```

#### Versions
| Release   | Release Date      | Notes             | Bugs Fixed    |
|-----------|-------------------|-------------------|---------------|
| 0.1       | 2019/11/01        | Initial Release   |               |

#### Authors & Contributors
| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Scott Donaldson      | Vertiv            | global.services.delivery.development@vertivco.com                |

#### Compatibility
| Release   | Status          | Notes         |
|-----------|-----------------|---------------|
| 4.0.x     | Not Supported   | N/A           |
| 5.0.1     | Supported       | N/A           |
| 5.0.2     | Supported       | N/A           |
| 5.0.3     | Supported       | N/A           |
| 5.0.4     | Supported       | N/A           |
| 5.0.5     | Supported       | N/A           |
| 5.0.6     | Supported       | N/A           |

#### To Do
* Implement argument handler for setting age of logs to archive in days.
* Implement argument handler for setting output directory.
* Implement option for encrypting content of archive.

#### Known Limitations
* Does not collect license server logs.
* Does not collect WebLogic domain level logs.
* Does not natively support encryption of the tar.gz.
* Does not allow file age or output path to be set via arguments, only via variables in script.
* Output folder restricted for safety to /var/tmp/*, /tmp/* /u03/* /u05/* further validation required.
* Does not validate if gzip or tar are available.

### Log Archive

#### File Name
`maintenance_log-clear-aged.sh`

#### Type
Bash Shell (Linux)

#### Description
This script removes log file older than N days (default 7), this value is configurable within the script.

#### Instructions
The script has potential to be damaging if it is tampered with, thus it is recommended that it is marked as read-only to prevent tampering.

1. Create scripts folder.
   ```shell
   mkdir /u05/scripts
   ```

2. Copy script to the folder as root or similar elevated user.

3. Ensure owner is root or similar.
   ```shell
   chown root:root /u05/scripts/maintenance_log-clear-aged.sh
   ```

4. Modify permissions so it is read
   ```shell
   chmod 755 /u05/scripts/maintenance_log-clear-aged.sh
   ```

#### Scheduling
The script can be scheduled for running every Sunday by editing the oracle user's crontab, if different intervals are required the script should be modified accordingly.
If being used with the archive log script then this should be scheduled to occur after the archiving has run, the following values reflect this with a 1hr gap.

```shell
1 1 * * 0       /u05/scripts/maintenance_log-clear-aged.sh
```

#### Versions
| Release   | Release Date      | Notes                                     |
|-----------|-------------------|-------------------------------------------|
| 0.1       | 2019/11/01        | Initial Release                           |

#### Authors & Contributors
| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Scott Donaldson      | Vertiv            | global.services.delivery.development@vertivco.com                |

#### Compatibility
| Release   | Status          | Notes         |
|-----------|-----------------|---------------|
| 4.0.x     | Not Supported   | N/A           |
| 5.0.1     | Supported       | N/A           |
| 5.0.2     | Supported       | N/A           |
| 5.0.3     | Supported       | N/A           |
| 5.0.4     | Supported       | N/A           |
| 5.0.5     | Supported       | N/A           |
| 5.0.6     | Supported       | N/A           |

#### To Do
* Implement argument handler for setting age of logs to archive in days.
* Implement argument handler for setting output directory.

#### Known Limitations
* Does not clean license server logs.
* Does not clean WebLogic domain level logs.
* Does not allow file age or output path to be set via arguments, only via variables in script.
* Output folder restricted for safety to /var/tmp/*, /tmp/* /u03/* /u05/* further validation required.

### WebLogic Log Level Configuration

#### File Name
`maintentance_wl-config.py`

#### Type
Jython (cross platform)

#### Description
This script provides functionality to set Oracle® WebLogic® domain & server logging levels, support is provided to define individual values or bulk setting.

_Note that support for project level logging in Oracle® Service Bus (OSB/ALSB) is incomplete._

#### Instructions
The script has potential to be damaging if it is tampered with, thus it is recommended that it is marked as read-only to prevent tampering.

#####  Run Insecurely
The WebLogic domain credentials and domain name must be set correctly in the `domain.properties` file, with `wlDomain`, `wlAdmin` & `wlAdminServer` properties set.

```properties
##
#  Target WebLogic Server
#
wlAdminServer=t3://trellis-front:7001
#wlAdminServer=t3s://trellis-front:7002
wlDomain=TrellisDomain

##
#  WebLogic Credentials
#
wlAdminUser=weblogic
```

_**Note:**_ _This configuration defaults to insecure plaintext password and plaintext connection to the WebLogic server, it is strongly advised that you review the steps in Run Securely with Profile._

```shell
. /u02/domains/<DOMAIN>/bin/setOSBDomainEnv.sh & . /u02/domains/<DOMAIN>/bin/setDomainEnv.sh
java -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=/u02/trelliskeys/trellis-trust.jks weblogic.WLST ./maintenance_log-configuration.py
```

##### Run Securely with Profile
Prepare WLST credentials.
```shell
export JAVA_HOME=/u01/jvm/jdk1.7
export PATH=$JAVA_HOME/bin:$PATH

mkdir ~oracle/.wlst
java weblogic.WLST
wls:/offline> connect('weblogic', '<WL_PASS>', 't3://trellis-front:7001')
wls:/offline> storeUserConfig('/home/oracle/.wlst/UserConfigFile','/home/oracle/.wlst/KeyFile')
wls:/offline> disconnect()
wls:/offline> connect(userConfigFile='/home/oracle/.wlst/UserConfigFile',userKeyFile='/home/oracle/.wlst/KeyFile',url='t3://trellis-front:7001')
wls:/offline> disconnect()
wls:/offline> exit()
```
Once the profile is prepared then edit the `domain.properties` file to use the profile such that the `wlAdminConfig` & `wlAdminKey` point to the profile created in the previous step.
```properties
# Default Properties
wlAdminConfig=/home/oracle/\.wlst/UserConfigFile
wlAdminKey=/home/oracle/\.wlst/KeyFile
```
Then launch the script.
```shell
. /u02/domains/<DOMAIN>/bin/setOSBDomainEnv.sh & . /u02/domains/<DOMAIN>/bin/setDomainEnv.sh
java -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=/u02/trelliskeys/trellis-trust.jks weblogic.WLST ./maintenance_log-configuration.py
```

#### Versions
| Release   | Release Date      | Notes                                     |
|-----------|-------------------|-------------------------------------------|
| 0.1       | 2019/11/01        | Initial Release                           |

#### Authors & Contributors
| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Scott Donaldson      | Vertiv            | global.services.delivery.development@vertivco.com                |

#### Compatibility
| Release   | Status          | Notes         |
|-----------|-----------------|---------------|
| 4.0.x     | Not Supported   | N/A           |
| 5.0.1     | Supported       | N/A           |
| 5.0.2     | Supported       | N/A           |
| 5.0.3     | Supported       | N/A           |
| 5.0.4     | Supported       | N/A           |
| 5.0.5     | Supported       | N/A           |
| 5.0.6     | Supported       | N/A           |

#### To Do
* Implement WebLogic domain detection.
* Implement support for back host WebLogic server(s).
* Implement wizard for generating WLST identity store.

#### Known Limitations
* Only supports front server.
* Incomplete handling of OSB project logging.
* Domain auto detection is not present, the domain has to be set in domain.properties.

### Cipher Test

#### File Name
`maintentance_cipher-test.sh`

#### Type
Bash Shell (Linux)

#### Description
This script provides allows for validation of protocols and ciphers supported by encrypted interfaces using OpenSSL, this is handy for validation in the absence of nmap or similar tooling available.

#### Instructions
The script should be modified to alter the `target_host` & `target_port` values to match test criteria.

Then launch the script.
```shell
./maintentance_cipher-test.sh
```
#### Versions
| Release   | Release Date      | Notes                                     |
|-----------|-------------------|-------------------------------------------|
| 0.1       | 2019/10/31        | Initial version by Mark.                  |
| 0.2       | 2019/10/31        | Bug fix to correctly handle failed connections, reworked loop for protocol & ciphers. Added UI colourization to aid readability, option for verbose output of rejected connections.                 |

#### Authors & Contributors
| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Mark Zagorski        | Vertiv            | global.services.delivery.development@vertivco.com                |
| Scott Donaldson      | Vertiv            | global.services.delivery.development@vertivco.com                |

#### Compatibility
| Release      | Status          | Notes                           |
|--------------|-----------------|---------------------------------|
| RHEL 6.x     | Supported       | N/A                             |
| RHEL 7.x     | Supported       | N/A                             |
| RHEL 8.x     | Untested        | Untested but should function.   |
| OEL 6.x      | Supported*      | Untested but should function.   |
| OEL 7.x      | Supported*      | Untested but should function.   |
| OEL 8.x      | Supported*      | Untested but should function.   |
| CentOS 6.x   | Supported*      | Untested but should function.   |
| CentOS 7.x   | Supported*      | Untested but should function.   |
| CentOS 8.x   | Supported*      | Untested but should function.   |

#### To Do
* Implement check to verify OpenSSL availability & version.
* Implement argument handler to accept target host by IPv4
* Implement argument handler to accept target host by IPv6
* Implement argument handler to accept target host by FQDN
* Implement argument handler to accept TCP port 1-65535 with validation

#### Known Limitations
* Host and port presently have to be defined in script.
