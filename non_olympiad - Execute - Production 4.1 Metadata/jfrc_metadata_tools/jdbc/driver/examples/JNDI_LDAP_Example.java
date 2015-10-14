/*******************************************************************************
 * Copyright(c) 2002 DataDirect Technologies inc. All rights reserved.
 *
 * Description:
 * JNDI Example for SequeLink Java Client using the
 * LDAP JNDI provider from Sun Microsystems, Inc.
 *
 * This Example consists of three parts:
 *
 * 1. Set up the environment and create the initial LDAP context.
 * This code is required for both the bind and the lookup of data sources.
 * This is the only part that is different between the two JNDI examples
 * (LDAP and FileSystem).
 *
 * 2. Construct and bind the SequeLinkDataSource. This part is
 * normally performed by an administrator (using a JNDI tool).
 *
 * 3. Look up the data source and establish a connection. Typically,
 * applications that use JNDI to connect to a database contain this code.
 *
 * Remarks:
 * For more information about JNDI, consult "The JNDI Tutorial" at
 * http://java.sun.com
 *
 * To do:
 * Adapt this code to your specific environment.
 *
 * ----------------------------------------------------------------------------
 * @version $Revision:   1.0.4.0  $
 * @author $Author:   ArneT  $
 * ----------------------------------------------------------------------------
 */

import com.ddtek.jdbcx.sequelink.SequeLinkDataSource;

import java.util.Hashtable;
import javax.naming.*;
import javax.naming.directory.*;
import java.sql.Connection;
import java.sql.SQLException;
import javax.sql.DataSource;

public class JNDI_LDAP_Example
{
public static void main(String argv[])
    {
    String name = "cn=MyDatabase"; // The data source will be bound to this name

    try
        {
        /***********************************************************************
         * Part 1. Set up the environment and create the initial LDAP context. *
         ***********************************************************************/
        Hashtable env = new Hashtable();
        env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, "ldap://servername/ou=orgUnit,o=org");

        System.out.println("Trying to create the naming service initial context");
        Context ctx = new InitialContext(env);


        /****************************************************************
         * Part 2. Construct and bind the SequeLinkDataSource.          *
         ****************************************************************/
        SequeLinkDataSource sds = new SequeLinkDataSource();
        sds.setDescription("My SequeLinkDataSource");
        sds.setServerName("MyServer");
        sds.setPortNumber(19996);

        /*
        OPTIONAL ATTRIBUTES please specify.
        sds.setDatabaseName("...");
        sds.setPassword("...");
        sds.setUser("...");
        sds.setDBUser("...");
        sds.setDBPassword("...");
        sds.setServerDataSource("...");
        sds.setBlockFetchForUpdate(new Integer("..."));
        sds.setSLKStaticCursorLongColBuffLen(new Integer("..."));
        sds.setHUser("...");
        sds.setHPassword("...");
        sds.setNewPassword("...");
        sds.setNetworkProtocol("...");
        sds.setCipherSuites("...");
        sds.setCertificateChecker("...");
        sds.setORANumber0IsNumeric(new Integer("..."));
        sds.setMSSMapLongToDecimal(new Integer("..."));
        sds.setApplicationName("...");
        sds.setSpyAttributes("...");
        sds.setLoginTimeout(int);
        */

        System.out.println("Trying to bind for the naming service");
        ctx.bind(name, sds);


        /******************************************************************
        * Part 3. Look up the data source and establish a connection.     *
        *******************************************************************/
        System.out.println("Checking the JNDI binding");
        DataSource ds = (DataSource) ctx.lookup(name);

        // *** SEQUELINK SPECIFIC CODE ***
        // The following code is SequeLinkDataSource Specific.
        // It is only used here to print out the SequeLinkDataSource attributes.
        // Because this code is specific for SequeLink, your applications should not
        // contain this code. (If you want to print out the DataSource attributes
        // in your code, you should use Java's reflection capabilities.)
        if (ds instanceof SequeLinkDataSource)
            {
            SequeLinkDataSource jsds = (SequeLinkDataSource) ds;
            System.out.println("description=" + jsds.getDescription());
            System.out.println("serverName=" + jsds.getServerName());
            System.out.println("portNumber=" + jsds.getPortNumber());

            System.out.println();
            System.out.println("OPTIONAL ATTRIBUTES");
            System.out.println("===================");
            System.out.println("databaseName=" + jsds.getDatabaseName());
            System.out.println("password=" + jsds.getPassword());
            System.out.println("user=" + jsds.getUser());
            System.out.println("DBUser=" + jsds.getDBUser());
            System.out.println("DBPassword=" + jsds.getDBPassword());
            System.out.println("serverDataSource=" + jsds.getServerDataSource());
            Integer i = jsds.getBlockFetchForUpdate();
            System.out.println("blockFetchForUpdate=" + (i==null?null:i.toString()));
            i = jsds.getSLKStaticCursorLongColBuffLen();
            System.out.println("SLKStaticCursorLongColBuffLen=" + (i==null?null:i.toString()));
            System.out.println("HUser=" + jsds.getHUser());
            System.out.println("HPassword=" + jsds.getHPassword());
            System.out.println("newPassword=" + jsds.getNewPassword());
            System.out.println("networkProtocol=" + jsds.getNetworkProtocol());
            System.out.println("cipherSuites=" + jsds.getCipherSuites());
            System.out.println("certificateChecker=" + jsds.getCertificateChecker());
            i = jsds.getORANumber0IsNumeric();
            System.out.println("ORANumber0IsNumeric=" + (i==null?null:i.toString()));
            i = jsds.getMSSMapLongToDecimal();
            System.out.println("MSSMapLongToDecimal=" + (i==null?null:i.toString()));
            System.out.println("applicationName=" + jsds.getApplicationName());
            System.out.println("spyAttributes=" + jsds.getSpyAttributes());
            System.out.println("loginTimeout=" + jsds.getLoginTimeout());
            }
        // *** END OF SEQUELINK SPECIFIC CODE.

        // Try to make a connection
        System.out.println("*** Trying to make a connection ***");
        Connection con = ds.getConnection("john", "whatever");
        System.out.println("Connection established");
        con.close();
        System.out.println("Connection closed");
        }
    catch (SQLException se)
        {
        while (se!=null)
            {
            System.out.println("vendor code: " + se.getErrorCode());
            System.out.println("Message:     " + se.getMessage());
            System.out.println("SQLState:    " + se.getSQLState());
            se.printStackTrace();
            se=se.getNextException();
            }
        }
    catch (NamingException ne)
        {
        ne.printStackTrace();
        }
    } // main
} // JNDI_LDAP_Example.java
