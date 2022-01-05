
#---------------------------------------------------------------------------------------------
# Script Name: maintenance_wl-protocols+ciphers.py
# Created: 2021/06/09
# Modified: 2021/06/09
# Author: Scott Donaldson [VERTIV/AVOCENT/UK]
# Company: Vertiv Infrastructure Ltd.
# Group: Life-Cycle Engineering, IT Systems
# Email: global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------

#
#  Run
#   . /u02/domains/<DOMAIN>/bin/setOSBDomainEnv.sh & . /u02/domains/<DOMAIN>/bin/setDomainEnv.sh
#   java -Dpython.verbose=debug weblogic.WLST ./maintenance_log-configuration.py
#   java weblogic.WLST ./maintenance_log-configuration.py
#   java -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.TrustKeyStore=/u02/trelliskeys/trellis-trust.jks weblogic.WLST ./maintenance_log-configuration.py

#
#  Prepare WLST credentials.
#
#   bash$ mkdir ~oracle/.wlst
#   bash$ java weblogic.WLST
#   wls:/offline> connect('weblogic', '<WL_PASS>', 't3://trellis-front:7001')
#   wls:/offline> storeUserConfig('/home/oracle/.wlst/UserConfigFile','/home/oracle/.wlst/KeyFile')
#   wls:/offline> disconnect()
#   wls:/offline> connect(userConfigFile='/home/oracle/.wlst/UserConfigFile',userKeyFile='/home/oracle/.wlst/KeyFile',url='t3://trellis-front:7001')
#   wls:/offline> disconnect()
#   wls:/offline> exit()

#
# Imports
#
import wlstModule
from weblogic.management.scripting.utils import WLSTUtil
from java.lang import String
from com.bea.wli.config import Ref
from com.bea.wli.monitoring import ServiceDomainMBean
from com.bea.wli.monitoring import ServiceResourceStatistic
from com.bea.wli.monitoring import StatisticType
from com.bea.wli.monitoring import StatisticValue
from com.bea.wli.monitoring import ResourceType
from com.bea.wli.sb.management.configuration import ALSBConfigurationMBean
from com.bea.wli.sb.management.configuration import BusinessServiceConfigurationMBean
from com.bea.wli.sb.management.configuration import CommonServiceConfigurationMBean
from com.bea.wli.sb.management.configuration import SessionManagementMBean
from com.bea.wli.sb.management.configuration import ServiceConfigurationMBean
from com.bea.wli.sb.management.configuration import ProxyServiceConfigurationMBean
from com.bea.wli.sb.management.query import BusinessServiceQuery
from com.bea.wli.sb.management.query import ProxyServiceQuery
from com.bea.wli.sb.util import Refs
from com.bea.wli.sb.util import EnvValueTypes
from com.bea.wli.sb.util import Refs

import sys
import os
import base64

# import http.client
# import ssl
# import json
#####

scriptVersion = '0.1'
sessionName = ('Trellis Protocol & Cipher Configuration Script' + scriptVersion)

# TODO: Load from /etc/sysconfig/trellis (Linux)
# TODO: Load from registry (Windows)
loadProperties('domain.properties')

ciphersTrellis515 = ['TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384','TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256','TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384','TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256','TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384','TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256','TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384','TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384','TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384','TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384','TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384','TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256','TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384','TLS_RSA_WITH_AES_256_GCM_SHA384','TLS_RSA_WITH_AES_256_CBC_SHA256','TLS_RSA_WITH_AES_128_CBC_SHA256','TLS_EMPTY_RENEGOTIATION_INFO_SCSV']
validProto = ['SSL3.0','TLSv1','TLSv1.1','TLSv1.2']
# TODO: Complete list of supported ciphers.
validCiphers = []

def println(): print '#' * 80


def editMode():
    edit()
    startEdit()


def saveActivate():
    save()
    activate()


def exitDisconnect():
    disconnect()
    exit()


def connectToAdmin():
    if (wlAdminConfig in globals() and wlAdminKey in globals()):
        print '[Debug]: Connecting with config file & key.'
        connect(userConfigFile=str(wlAdminConfig), userKeyFile=str(wlAdminKey), url=str(wlAdminServer))
    else:
        print '[Debug]: Connecting with username & passowrd.'
        connect(wlAdminUser, wlAdminPassword, wlAdminServer)
    # TODO: Cleanup
    # TODO: No plaintext, drive this off configuration hashed values.


def serverCiphers(targetServerName, ciphers):
    """
    Configures accepted ciphers for the specified WL server.

    Parameters
    ----------
    targetServerName : string
    ciphers :  [string]

    """
    try:
        cd('/Servers/' + targetServerName + '/SSL/' + targetServerName)
    except:
        print '[Fatal]: Invalid server.'

    try:
        # cmo.getSSL()
        cmo.setCiphersuites(ciphers)

    except Exception, e:
        print '[Error]: Error setting values.'
        print str(e)

    try:
        save()
        print '[Info]: Changes saved.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit()
        
        
def serverProtocols(targetServerName):
    """
    Configures accepted protocols for the specified WL server.

    Parameters
    ----------
    targetServerName : string
    clientProto :  [string]
    serverProto: [string]

    """
    try:
        cd('/Servers/' + targetServerName + '/ServerStart/' + targetServerName)
    except:
        print '[Fatal]: Invalid server.'

    try:
        # TODO: Replace with function to build string
        # set('Arguments',(clientProto + ' ' + serverProto)
        set('Arguments','-Djdk.tls.client.protocols=TLSv1.2 -Dhttps.protocols=TLSv1.1,TLSv1.2 -Dweblogic.ssl.SSLv2HelloEnabled=false')

    except Exception, e:
        print '[Error]: Error setting values.'
        print str(e)

    try:
        save()
        print '[Info]: Changes saved.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit()

# TODO: Check Trellis Version and load support ciphers.
# TODO: Verify JDK version.
        

def banner():
    println()
    print '#'
    print '#  Vertiv Trellis(tm) Enterprise - SSL/TLS Configuration Script (v' + scriptVersion + ')'
    print '#'
    println()


# def getTrellisVersion():
#     with open('/u01/trellis/trellis.version') as temp_f:
#         versionfile = temp_f.readlines()
#     for line in versionfile:
#         if 'trellis.version' in line:
#             pattern = re.compile(r'(5.[0-1].[0-9])|([4].[0-1].[0-3])')
#             teVersion = re.findall(pattern, line)
#             print('Version: ' + strin(teVersion))
#             return True # The string is found
#     return False  # The string does not exist in the file

def main():
    print ' '
    
    #getTrellisVersion()

    ##
    #  Connect to WebLogic Admin Server
    #
    try:
        # TODO: Grab target from file
        connectToAdmin()
        if isAdminServer:
            print '[Info]: Connected to WebLogic AdminServer.'
        else:
            print '[Error] Connected to non-Admin Server.'
            return false

    except Exception, e:
        print '[Error]: Unable to connect to WebLogic AdminServer.'
        print str(e)
        return false

    ##
    #  Process Managed Server Configurations
    #
    println()
    print '[Info]: Starting log configuration for managed servers.'
    cd('/')
    editMode()
    for tmpServerName in ls('Servers', returnMap='true'):
        serverProtocols(tmpServerName)
        serverCiphers(tmpServerName, ciphersTrellis515)
        println()
        print '[Info]: Server ' + tmpServerName + ' updated.'

    println()
    print '[Debug]: Pending changes...'
    print(showChanges())
    println()

    try:
        saveActivate()
        print '[Info] Changes saved & activated successfully.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit('y')
    #####

    println()
    print '[Info]: Starting service bus component configurations.'

    #####

    # Exit
    exitDisconnect()


banner()
if main():
    sys.exit(0)
else:
    sys.exit(1)
