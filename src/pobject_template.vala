/**
 * This method loads all objects from the database and returns them.
 * @return An array containing every PObject from the database.
 * @throws PObject.Error.DBERROR when an error occurs while loading the objects from the database.
 */
public static :object_class:[] all( ) throws PObject.Error.DBERROR
{
  return (:object_class:[]):object_class:.select( ).exec( );
}

/**
 * This method creates a new PObjectSelector object which can be used to load PObjects from the database.
 * @param fields A string containig the fields which should be selected from the database (this string will be used in a select statement).
 * @return A PObjectSelector object with the settings to load PObjects.
 * @throws PObject.Error.DBERROR when an error occurs while loading the objects from the database.
 */
public static PObjectSelector select( string fields = "*" ) throws PObject.Error.DBERROR
{
  return new PObjectSelector( typeof( :object_class: ), fields ); 
}