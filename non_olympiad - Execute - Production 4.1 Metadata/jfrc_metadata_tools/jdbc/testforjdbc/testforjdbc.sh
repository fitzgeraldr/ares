#
#  Test For JDBC Tool - Startup Script
#
#  The PATH and CLASSPATH environment variables should be set according to
#  the documentation of your JAVA Virtual Machine
#  

#
# Location of the SequeLink Java Client driver classes
#
SLJC_DRIVER=../driver/lib/sljc.jar:../driver/lib/slssl.jar
export SLJC_DRIVER

#
# Location of the SPY driver classes
#
SPY_DRIVER=../spy/lib/spy.jar
export SPY_DRIVER

#
# location of the JNDI classes
#
JNDIFS=../sun/lib/fs/fscontext.jar:../sun/lib/fs/providerutil.jar
JNDILDAP=../sun/lib/ldap/ldap.jar:../sun/lib/ldap/ldapbp.jar:../sun/lib/providerutil.jar:../sun/lib/ldap/jaas.jar
export JNDIFS
export JNDILDAP

#
# location of the TestForJDBC classes
#
TESTJDBC=./lib/testforjdbc.jar:.
export TESTJDBC

#
# setting the CLASSPATH variable
#
CLASSPATH=$TESTJDBC:$SLJC_DRIVER:$SPY_DRIVER:$JNDIFS:$JNDILDAP:$CLASSPATH
export CLASSPATH

#
# construction the URL of the configuration file
#
CONFIG=file://$PWD/Config.txt
export CONFIG

#
# Start Test For JDBC
#
java JDBCTest "$CONFIG"
