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
     * This method will execute a select statement which is represented by this PObjectSelector and creates and fills
     * the PObjects.
     * @return The resulting PObjects as array.
     * @throws PObject.Error.DBERROR when an error occurs while loading the data from the database.
     */
    public PObject.Object[] exec( ) throws PObject.Error.DBERROR
    {
      return { };
    }

    /**
     * This constructor will create a new PObject selector with the given PObject class and the required fields.
     * @param pobject_class the class of the required pobject.
     * @param fields The fields to load from the database.
     */
    public PObjectSelector( Type pobject_class, string fields )
    {
      stdout.printf( "Creating pobject selector for class %s\n", pobject_class.name( ) );
    }
  }
}