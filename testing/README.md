

Vertiv™ Trellis™ - Unofficial/Community Maintenance Scripts
===========================================================

License
-------
This collection of scripts is subject to BSD 3-Clause license included [here](../LICENSE.md), they are unsupported and are provided for convenience.

Please ensure you have familiarized yourself with the license, usage of these scripts in part or whole constitute acceptance of these terms.

Document Change History
-----------------------
| Release   | Release Date      | Notes                                     | QR   |
|-----------|-------------------|-------------------------------------------|------|
| 0.1       | 2019/11/20        | Initial draft                             | N/A  |

Scripts
-------
### Active Directory Discovery Test

#### File Name
`maintenance_ad-discovery.sh`

#### Type
Bash Shell (Linux)

#### Description
This script will query the defined domain to identity Active Directory / FreeIPA controllers advertised via _ldap._tcp.dc._msdcs.<domain>.<tld> SRV records. 

Once detected it will validate connectivity to ports 636 & 3269, dump out presented certificates and test supported protocol and ciphers supported by the AD controller.

#### Instructions

1. Copy scripts folder.
   ```shell
   mkdir /u05/support/scripts
   ```

2. Ensure owner is oracle or suitable user.
   ```shell
   chown oracle:oracle /u05/support/scripts/maintenance_ad-discovery.sh
   ```

3. Modify permissions so it is readable and executable.
   ```shell
   chmod 755 /u05/support/scripts/maintenance_ad-discovery.sh
   ```

#### Versions
| Release   | Release Date      | Notes                                                                               | Bugs Fixed    |
|-----------|-------------------|-------------------------------------------------------------------------------------|---------------|
| 0.2       | 2019/11/01        | Modification to DNS query to use TCP & added timeout to OpenSSL certificate dump.   |               |
| 0.1       | 2019/11/01        | Initial Release   |               |

#### Authors & Contributors
| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Scott Donaldson      | Vertiv            | scott.donaldson@vertivco.com                |

#### Compatibility
| Release   | Status          | Notes         |
|-----------|-----------------|---------------|
| N/A       | N/A             | N/A           |

#### To Do
* Implement argument handler for setting domain name.
* Implement argument handler for setting output directory.
* Implement option for limiting protocols.
* Implement option for limiting ports.
* Implement JSON output for results.
* Implement support for CA bundle for certificate validation.

#### Known Limitations
* Domain has to be set with TARGET_DOMAIN variable in script.
* Does not validate if host is up with ICMP ping prior to testing.
* Coloured shell output text outputs colour codes to log output.
