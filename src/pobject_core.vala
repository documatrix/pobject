/**
 * This class contains some core definitions and functionalities of the pobject framework.
 */

namespace PObject
{
  /**
   * This errordomain contains the possible errors which can occur using the pobject library.
   */
  public errordomain Error
  {
    DBERROR;
  }

  /**
   * This variable contains the DBLib connection which is used to communicate with the database.
   */
  public DBLib.Connection? connection;

  /**
   * Call this method to initialize the pobject system.
   * @param db_type The type of the database to use.
   * @param connection_string The connection string which should be used to connect to the database.
   * @param user The user which should be used to connect to the database.
   * @param password The password which should be used to connect to the database.
   * @throws PObject.Error.DBERROR when an error occurs while connecting to the database.
   */
  public static void init( DBLib.DBType db_type, string connection_string, string? user, string? password ) throws PObject.Error.DBERROR
  {
    try
    {
      PObject.connection = DBLib.Connection.connect( db_type, connection_string, user, password );

      PObject.ensure_schema_table( );
    }
    catch ( DBLib.DBError.CONNECTION_ERROR e )
    {
      throw new PObject.Error.DBERROR( "Error while connecting to the database! %s", e.message );
    }
  }

  /**
   * This method will ensure that the schema_versions table exists.
   * If it does not exist it will create the table.
   * @throws PObject.Error.DBERROR 
   */
  public void ensure_schema_table( ) throws PObject.Error.DBERROR
  {
    try
    {
      string create_statement = "
CREATE TABLE IF NOT EXISTS schema_versions (
  id BIGINT(20) PRIMARY KEY AUTO_INCREMENT NOT NULL,
  schema_name VARCHAR(1024) NOT NULL,
  schema_date_time VARCHAR(1024) NOT NULL,
  schema_index BIGINT(20) NOT NULL DEFAULT 0
)
";
      DMLogger.log.debug( 0, false, "Ensuring that schema_versions table exists..." );
      PObject.connection.execute( create_statement );
    }
    catch ( DBLib.DBError e )
    {
      throw new PObject.Error.DBERROR( "Error while creating the schema_versions table! %s", e.message );
    }
  }
}
