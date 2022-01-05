
#---------------------------------------------------------------------------------------------
# Script Name: maintenance_wl-log-config.sh
# Created: 2019/01/14
# Modified: 2019/11/01
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
sessionName = ('Trellis Log Configuration Script' + scriptVersion)

# TODO: Load from /etc/sysconfig/trellis (Linux)
# TODO: Load from registry (Windows)
loadProperties('domain.properties')


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


def domainLogRetention(weblogicDomain, retentionCount, minimumFileSize):
    """
    Configures rotated logs retention for domain.

    Parameters
    ----------
    serverName : string
    serverRetentionCount :  int
    serverMinimumFileSize : int

    """
    try:
        cd('/Log/' + weblogicDomain)
    except:
        print '[Fatal]: Invalid domain.'

    try:
        # if timestampFormat:
        #     cmo.setDateFormatPattern(timestampFormat)
        # else:
        cmo.setDateFormatPattern('yyyyMMdd hh:mm:ss a z')

        cmo.setRotateLogOnStartup(true)

        if retentionCount != 0:
            cmo.setNumberOfFilesLimited(true)
            cmo.setFileCount(int(retentionCount))
        else:
            cmo.setNumberOfFilesLimited(false)
            cmo.setFileCount(int(0))

        if logFileRotationDir:
            # TODO: Cleanup input handling to stip leading ./
            # TODO: Verify permissions on location defined.
            # TODO: Add some sane limits on the subfoler.
            targetLogDir = '/u02/domain/' + weblogicDomain + '/servers/' + targetServerName + '/logs/' + logFileRotationDir
            if os.path.isdir(targetLogDir) & os.path.exists(targetLogDir):
                cmo.setLogFileRotationDir(targetLogDir)
            else:
                cmo.setLogFileRotationDir('')
                print '[Error]: Target folder ' + targetLogDir + ' does not exist or is inaccesible.'
        else:
            cmo.setLogFileRotationDir('')

        if rotationType == 'bySize':
            cmo.setRotationType('bySize')
            cmo.setFileMinSize(int(minimumFileSize))  # in KB
        elif rotationType == 'byTime':
            cmo.setRotationType('byTime')
            cmo.setRotationTime('00:00')
        elif rotationType == 'none':
            cmo.setRotationType('none')
        else:
            cmo.setRotationType('bySize')
            print '[Warning]: Invalid rotation type passed in conifguration.'

    except Exception, e:
        print '[Error]: Error setting values.'
        print str(e)

    try:
        save()
        print '[Info]: Changes saved.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit()


def serverLogRotation(targetServerName, retentionCount, minimumFileSize, timestampFormat):
    """
    Configures rotated logs retention for managed server.

    Parameters
    ----------
    serverName : string
    serverRetentionCount :  int
    serverMinimumFileSize : int
    timestampFormat : string, optional

    """
    try:
        cd('/Servers/' + targetServerName + '/Log/' + targetServerName)
    except:
        print '[Fatal]: Invalid server.'

    try:
        # if timestampFormat:
        #     cmo.setDateFormatPattern(timestampFormat)
        # else:
        cmo.setDateFormatPattern('yyyyMMdd hh:mm:ss a z')

        cmo.setRotateLogOnStartup(true)

        if retentionCount != 0:
            cmo.setNumberOfFilesLimited(true)
            cmo.setFileCount(int(retentionCount))
        else:
            cmo.setNumberOfFilesLimited(false)
            cmo.setFileCount(int(0))

        cmo.setFileMinSize(int(minimumFileSize))  # in KB

        if logFileRotationDir:
            # TODO: Cleanup input handling to stip leading ./
            # TODO: Verify permissions on location defined.
            # TODO: Add some sane limits on the subfoler.
            targetLogDir = '/u02/domain/' + weblogicDomain + '/servers/' + targetServerName + '/logs/' + logFileRotationDir
            if os.path.isdir(targetLogDir) & os.path.exists(targetLogDir):
                cmo.setLogFileRotationDir(targetLogDir)
            else:
                cmo.setLogFileRotationDir('')
                print '[Error]: Target folder ' + targetLogDir + ' does not exist or is inaccesible.'
        else:
            cmo.setLogFileRotationDir('')

        # TODO: Add as parameter LogFileSeverity
        cmo.setLogFileSeverity(wlServerLogLevel)
        # TODO: Add as parameter StdoutSeverity
        cmo.setStdoutSeverity(wlServerStdErrLevel)
        # TODO: Add as parameter StdoutLogStack
        cmo.setStdoutLogStack(true)

        # TODO: Add as parameter (default 8KB)
        cmo.setBufferSizeKB(int(1024))

        if rotationType == 'bySize':
            cmo.setRotationType('bySize')
            cmo.setFileMinSize(int(minimumFileSize))  # in KB
        elif rotationType == 'byTime':
            cmo.setRotationType('byTime')
            cmo.setRotationTime('00:00')
        elif rotationType == 'none':
            cmo.setRotationType('none')
        else:
            cmo.setRotationType('bySize')
            print '[Warning]: Invalid rotation type passed in configuration.'

        # cmo.setRedirectStderrToServerLogEnabled(true)
        # cmo.setRedirectStdoutToServerLogEnabled(true)

    except Exception, e:
        print '[Error]: Error setting values.'
        print str(e)

    try:
        save()
        print '[Info]: Changes saved.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit()


def serverOsbVerbosity(serverName, logLevel, logEnablement):
    """
    Configures retention quantity for rotated logs.

    Parameters
    ----------
    serverName : string
    logLevel: {'Info', 'Debug', 'Warning', 'Error' }
        Level of logging to apply.
    logEnablement: bool, optional
        Enable or disable logging.

    """
    print '[Info]: Changing log verbosity for ' + serverName + " to " + logLevel

    print '[Error]: Not implemented.'
    domainRuntime()
    sessionName = String("SessionScript" + Long(System.currentTimeMillis()).toString())
    sessionMBean = findService(SessionManagementMBean.NAME, SessionManagementMBean.TYPE)
    sessionMBean.createSession(sessionName)

    # bsQuery = BusinessServiceQuery()
    # bsQuery.setLocalName("DatapointService")
    # bsQuery.setPath("*")

    # ConfigurationMBean = findService(String("ALSBConfiguration.").concat(sessionName),
    #                                   "com.bea.wli.sb.management.configuration.ALSBConfigurationMBean")
    ALSBConfigurationMBean = findService(String("ALSBConfiguration.").concat(sessionName),
                                         "com.bea.wli.sb.management.configuration.ALSBConfigurationMBean")
    psQuery = ProxyServiceQuery()
    # psQuery.setPath('MSS_*/*')
    psQuery.setPath('MSS_EngineManagmentService/*')
    psQuery.setLocalName('EngineManagmentService')
    refs = ALSBConfigurationMBean.getRefs(psQuery)

    print refs

    for ref in refs:
        try:
            print '[Info]: Updating ' + str(ref) + ' configuration.'
            pxyConf = "ProxyServiceConfiguration." + sessionName
            mbean = findService(pxyConf, 'com.bea.wli.sb.management.configuration.ProxyServiceConfigurationMBean')
            folderRef = Refs.makeParentRef(folder + '/')
            serviceRef = Refs.makeProxyRef(folderRef, serviceName)
            print serviceDefinition
        except Exception, e:
            print '[Error]: Error querying service.'
            print str(e)
    print '[Error]: Not implemented.'

    SessionMBean.activateSession('[Info]: ' + sessionName + " changes activated.")

    # print '[Info]: Server ' + tmpServerName + ' updated.'
    # cmo.createSession(sessionName)
    # cmo.activateSession(sessionName, 'Scripted log verbosity change to ' + logLevel)


def banner():
    println()
    print '#'
    print '#  Vertiv Trellis(tm) Enterprise - Log Configuration Script (v' + scriptVersion + ')'
    print '#'
    println()


def main():
    print ' '

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
    #  Process Log Behaviour
    #

    # Domain Configuration
    println()
    print '[Info]: Starting domain logs configurations '
    cd('/')
    editMode()
    domainLogRetention(wlDomain, wlDomainRetentionCount, wlDomainMinFileSize)

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
    ######

    # Managed Server Configurations
    println()
    print '[Info]: Starting log configuration for managed servers.'
    cd('/')
    editMode()
    for tmpServerName in ls('Servers', returnMap='true'):
        if tmpServerName == 'AdminServer':
            serverLogRotation(tmpServerName, wlAdminRetentionCount, wlAdminMinFilesize, timeStampFormat)
        else:
            serverLogRotation(tmpServerName, wlServerRetentionCount, wlServerMinFilesize, timeStampFormat)
        println()
        print '[Info]: Server ' + tmpServerName + ' updated.'

    try:
        saveActivate()
        print '[Info] Changes saved & activated successfully.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit('y')
    #####

    println()
    print '[Info]: Starting service bus component configurations.'

    ##
    #  Process Log Verbosity
    #
    cd('/')
    editMode()
    for tmpServerName in ls('Servers', returnMap='true'):
        if tmpServerName == 'osb_server':
            serverOsbVerbosity(tmpServerName, 'Info', true)
        else:
            print '[Info]: Server ' + tmpServerName + ' not suitable.'

    try:
        saveActivate()
        print '[Info] Changes saved & activated successfully.'
    except:
        print '[Error]: Failure to commit changes.'
        cancelEdit('y')

    println()
    print '[Info]: Completed.'

    #####

    # Exit
    exitDisconnect()


banner()
if main():
    sys.exit(0)
else:
    sys.exit(1)
