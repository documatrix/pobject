/**
 * This file contains the abstract class for generated PObject migrations.
 */
namespace PObject
{
  public abstract class Migration : GLib.Object
  {
    /**
     * This variable contains the name of the migration.
     */
    public string migration_name;

    /**
     * This variable contains the date and time of the migration.
     */
    public string migration_date_time;

    /**
     * This method will be called to execute the migration on the docPIPE database.
     * @throws DBLib.DBError when a (low-level) database error occurs.
     * @throws PObject.Error if a pobject error occurs.
     */
    public abstract void up( ) throws DBLib.DBError, PObject.Error;

    /**
     * This method will be called to revert the migration on the docPIPE database.
     * @throws DBLib.DBError when a (low-level) database error occurs.
     * @throws PObject.Error if a pobject error occurs.
     */
    public abstract void down( ) throws DBLib.DBError, PObject.Error;

    /**
     * This method checks if this migration is already done on the database.
     * @return true when the migration was done already, false if it was not executed on the database until now.
     * @throws PObject.Error.DBERROR if an error occurs while checking if the migration was executed.
     */
    public bool migrated( ) throws PObject.Error.DBERROR
    {
      try
      {
        DBLib.Statement stmt = PObject.connection.execute( "select id from schema_versions where schema_name = ? and schema_date_time = ?", this.migration_name, this.migration_date_time );

        if ( stmt.result.fetchrow_array( ) != null )
        {
          return true;
        }
        return false;
      }
      catch ( DBLib.DBError e )
      {
        throw new PObject.Error.DBERROR( "Error while checking if migration %s was already executed! %s", this.migration_name, e.message ); 
      }
    }

    /**
     * This method will insert the migration name and date to the schema_versions table of the database.
     * @param migration_index The index of the migration in the migrations array. 
     * @throws DBLib.DBError when a (low-level) database error occurs.
     */
    public void insert_into_database( uint64 migration_index ) throws DBLib.DBError
    {
      PObject.connection.execute( "insert into schema_versions (schema_name, schema_date_time, schema_index) values (?, ?, ?)", this.migration_name, this.migration_date_time, migration_index.to_string( ) );
    }
  }

  /**
   * Call this method to do ensure, that the database is migrated to the current state.
   * @param migrations_json The filename of the JSON file which contains the migration infos.
   * @throws DBLib.DBError when a (low-level) database error occurs.
   * @throws PObject.Error if a pobject error occurs.
   * @throws Error if an error occurs while reading the migrations json file.
   */
  public static void migrate( string migrations_json ) throws DBLib.DBError, PObject.Error, Error
  {
    Json.Parser parser = new Json.Parser( );
    if ( !parser.load_from_file( migrations_json ) )
    {
      DMLogger.log.warning( 0, false, "Could not load migrations json ${1}! Unknown error!", migrations_json ); 
      return;
    }

    Json.Object root_object = parser.get_root( ).get_object( );
    Json.Array migrations = root_object.get_array_member( "migrations" );

    for ( uint i = 0; i < migrations.get_length( ); i ++ )
    {
      Json.Object migration_object = migrations.get_object_element( i );

      string migration_name = migration_object.get_string_member( "migration" );
      Type migration_type = Type.from_name( migration_name );
      PObject.Migration migration = (PObject.Migration)GLib.Object.new( migration_type );

      if ( migration.migrated( ) )
      {
        /* This migration was executed already. */
        DMLogger.log.debug( 2, false, "Migration ${1} is already done.", migration_name ); 
      }
      else
      {
        /* This migration has to be executed. */
        migration.up( );
        migration.insert_into_database( (uint64)i );
      }
    }
  }
}
