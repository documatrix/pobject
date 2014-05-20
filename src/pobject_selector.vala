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
     * This method will execute a select statement which is represented by this PObjectSelector and creates and fills
     * the PObjects.
     * @return The resulting PObjects as array.
     * @throws PObject.Error.DBERROR when an error occurs while loading the data from the database.
     */
    public PObject.Object[] exec( ) throws PObject.Error.DBERROR
    {
      stdout.printf( "selecting data from table %s", this.table_name );
      return { };
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

      stdout.printf( "Creating pobject selector for class %s\n", pobject_class.name( ) );
    }
  }
}