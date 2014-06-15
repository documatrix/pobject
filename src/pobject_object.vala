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

    /**
     * This variable indicates if the object data was modified.
     * It is used in the save method to determine if an update statement has to be executed.
     */
    public bool pobject_dirty;

    /**
     * This method will be called to initialize the variables of this object using the given result from the database.
     * @param db_data The data from the database.
     * @param contains_joins This flag specifies if the given data row contains the data of joined tables.
     */
    public abstract void set_db_data( HashTable<string?,string?> db_data, bool contains_joins );

    /**
     * When you call this method the object will be inserted or updated in the database.
     * @throws PObject.Error.DBERROR when an error occurs while inserting or updating the record.
     */
    public void save( ) throws PObject.Error.DBERROR
    {
      try
      {
        if ( this.new_record )
        {
          /* The object has to be inserted. */
          this.insert( );
          
          this.new_record = false;
        }
        else if ( this.pobject_dirty )
        {
          /* The object has te be updated. */
          this.update( );
          
          this.pobject_dirty = false;
        }
      }
      catch ( DBLib.DBError e )
      {
        throw new PObject.Error.DBERROR( "Error while saving object in the database! %s", e.message );
      }
    }

    /**
     * This method will insert the object into the database using an insert into statement.
     * @throws DBLib.DBError when an error occurs while inserting the object.
     */
    public abstract void insert( ) throws DBLib.DBError;

    /**
     * This method will update the object into the database using an update statement.
     * @throws DBLib.DBError when an error occurs while updating the object.
     */
    public abstract void update( ) throws DBLib.DBError;

    /**
     * This method will delete the object from the database using the delete statement.
     */
    public abstract void delete( ) throws PObject.Error.DBERROR;

    /**
     * This method will reload the object from the database if it was already stored
     * to the database.
     * @return true if the object was reloaded or false if the object was not stored in the database until now.
     * @throws PObject.Error.DBERROR if an error occured while executing SQL statements.
     */
    public abstract bool reload( ) throws PObject.Error.DBERROR;

    /**
     * This method will return a json encoded string which represents this object as json object.
     * @return A json encoded string representing this object.
     */
    public abstract string to_json( );

    /**
     * This method will return a Json.Object object which represents this object as json object.
     * @return A json object filled with the object data.
     */
    public abstract Json.Object to_json_object( );
  }
}
