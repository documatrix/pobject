/**
 * This file contains the functionality to select PObjects from the database.
 */

namespace PObject
{
  /**
   * This class provides the functionality to select pobjects from a database.
   */
  public class PObjectSelector : GLib.Object
  {
    /**
     * This variable contains the type information of the class which's data should be loaded.
     */
    public Type pobject_class;

    /**
     * This variable contains the name of the database table which should be used to select data.
     */
    public string table_name;

    /**
     * This variable contains the field-part for the select statement (the fields which will be selected).
     */
    public string fields;

    /**
     * This method will execute a select statement which is represented by this PObjectSelector and creates and fills
     * the PObjects.
     * @return The resulting PObjects as array.
     * @throws PObject.Error.DBERROR when an error occurs while loading the data from the database.
     */
    public PObject.Object[] exec( ) throws PObject.Error.DBERROR
    {
      string statement = "select %s from %s".printf( this.fields, this.table_name );

      try
      {
        DMLogger.log.debug( 0, false, "[SQL] ${1};", statement );
        DBLib.Statement stmt = PObject.connection.execute( statement );

        PObject.Object[] result = { };

        HashTable<string?,string?>? row;
        while ( ( row = stmt.result.fetchrow_hash( ) ) != null )
        {
          PObject.Object o = (PObject.Object)GLib.Object.new( this.pobject_class );
          o.set_db_data( row );
          result += o;
        }

        return result;
      }
      catch ( DBLib.DBError e )
      {
        throw new PObject.Error.DBERROR( "Error while selecting objects from the database using statement %s! %s", statement, e.message );
      }
    }

    /**
     * This constructor will create a new PObject selector with the given PObject class and the required fields.
     * @param pobject_class the class of the required pobject.
     * @param fields The fields to load from the database.
     */
    public PObjectSelector( Type pobject_class, string table_name, string fields )
    {
      this.pobject_class = pobject_class;
      this.table_name = table_name;
      this.fields = fields;

      stdout.printf( "Creating pobject selector for class %s\n", pobject_class.name( ) );
    }
  }
}