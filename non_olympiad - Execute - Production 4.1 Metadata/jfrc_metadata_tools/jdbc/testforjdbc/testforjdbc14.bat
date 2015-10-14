echo off
rem
rem  Test For JDBC Tool - Startup Script
rem
rem  The PATH and CLASSPATH environment variables should be set according to
rem  the documentation of your JAVA Virtual Machine
rem  

setlocal

rem
rem Location of the SequeLink Java Client driver classes
rem
set SLJC_DRIVER=..\driver\lib\sljc.jar;..\driver\lib\slssl14.jar;..\driver\lib\iaik_jce_full.jar

rem
rem Location of the SPY driver classes
rem
set SPY_DRIVER=..\spy\lib\spy.jar

rem
rem location of the JNDI classes
rem
set JNDIFS=..\sun\lib\fs\fscontext.jar;..\sun\lib\fs\providerutil.jar
set JNDILDAP=..\sun\lib\ldap\ldap.jar;..\sun\lib\ldap\ldapbp.jar;..\sun\lib\providerutil.jar;..\sun\lib\ldap\jaas.jar

rem
rem location of the TestForJDBC classes and the Config.txt file
rem
set TESTJDBC=.\lib\testforjdbc.jar;.

rem
rem setting the CLASSPATH variable
rem
set CLASSPATH=%TESTJDBC%;%SLJC_DRIVER%;%SPY_DRIVER%;%JNDIFS%;%JNDILDAP%;%CLASSPATH%

rem
rem construction the URL of the configuration file
rem
set CONFIG=Config.txt

rem
rem Start Test For JDBC
rem
java JDBCTest %CONFIG%

endlocal
