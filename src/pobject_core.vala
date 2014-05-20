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
    }
    catch ( DBLib.DBError.CONNECTION_ERROR e )
    {
      throw new PObject.Error.DBERROR( "Error while connecting to the database! %s", e.message );
    }
  }
}
