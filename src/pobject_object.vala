/**
 * This file contains the base class of the pobject framework.
 * When another class inherits from this class it can be stored in a database.
 */

namespace PObject
{
  /**
   * The PObject class can be used as base class to store object persistantly in a database.
   */
  public abstract class Object : GLib.Object
  {
    /**
     * This variable specifies if the object was already stored in the database or if it is a new record and has
     * to be inserted.
     */
    public bool new_record = true;

    /**
     * This variable will contain the name of the database table which will be used to store this PObject.
     */
    public string table_name;
  }
}
