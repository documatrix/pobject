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
     * This variable contains the where-clause of the resulting select statement.
     */
    private string? where_clause = null;

    /**
     * This variable may contain parameters which are passed to the statement.
     */
    private string?[] statement_params = { };

    /**
     * This variabale specifies if the limit_count should be used in the limit clause of the resulting select statement.
     */
    private bool use_limit = false;

    /**
     * This variable will be used as limit count in the limit clause of the resulting select statement if
     * @see PObjectSelector.use_limit is true.
     */
    private uint64 limit_count = 0;

    /**
     * This variable specifies if the order_by should be used in the order-by clause of the resulting select statement.
     */
    public bool use_order_by = false;

    /**
     * This variable will be used as order-by-statement in the order-by clause of the resulting select statement if
     * @see PObjectSelector.use_order_by is true.
     */
    public string? order_by = null;

    /**
     * This method will call the @see PObjectSelector.exec method to execute the select statement.
     * The difference to exec is, that "first" will set the limit count to 1 and return the first found object
     * or null if no object was found.
     */
    public PObject.Object? first( ) throws PObject.Error.DBERROR
    {
      this.limit( 1 );

      PObject.Object[] result = this.exec( );

      if ( result.length > 0 )
      {
        return result[ 0 ];
      }
      return null;
    }
    
    /**
     * This method will execute a select statement which is represented by this PObjectSelector and creates and fills
     * the PObjects.
     * @return The resulting PObjects as array.
     * @throws PObject.Error.DBERROR when an error occurs while loading the data from the database.
     */
    public PObject.Object[] exec( ) throws PObject.Error.DBERROR
    {
      StringBuilder statement = new StringBuilder.sized( 10 );
      statement.append_printf( "select %s from %s", this.fields, this.table_name );

      if ( this.where_clause != null )
      {
        statement.append( " where " );
        statement.append( this.where_clause );
      }

      if ( this.use_order_by && this.order_by != null )
      {
        statement.append_printf( " order by %s", this.order_by );
      }

      if ( this.use_limit )
      {
        statement.append_printf( " limit %llu", this.limit_count );
      }

      try
      {
        DMLogger.log.debug( 0, false, "[SQL] ${1};", statement.str );
        DBLib.Statement stmt = PObject.connection.prepare( statement.str );
        if ( this.statement_params.length > 0 )
        {
          stmt.set_params( this.statement_params );
        }
        stmt.execute( );

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

    /**
     * This method can be used to set a where clause for the resulting select statement.
     * If there is already a where clause then it will connected to this where clause by an "and" operator.
     * @param code The code of the resulting where clause.
     * @param ... Parameters which replace question marks in the given code.
     * @return this
     */
    public PObjectSelector where( string code, ... )
    {
      va_list params = va_list( );
      unowned string? param;
      while ( ( param = params.arg<string?>( ) ) != null )
      {
        this.statement_params += param;
      }

      if ( this.where_clause == null )
      {
        this.where_clause = code;
      }
      else
      {
        this.where_clause += " and " + code;
      }

      return this;
    }

    /**
     * This method can be used to specify, that the resulting select statement should get a limit clause using the given
     * values.
     * @param limit_count The maximum count of rows returned by this selector.
     * @return this
     */
    public PObjectSelector limit( uint64 limit_count )
    {
      this.use_limit = true;
      this.limit_count = limit_count;

      return this;
    }

    /**
     * This method can be used to specify that the resulting select statement should get a order-by clause using
     * the given code.
     * Any previously set order-by code will be overwritten by this method.
     * @param order_by The code which should be used in the order-by clause.
     * @return this
     */
    public PObjectSelector order( string code )
    {
      this.use_order_by = true;
      this.order_by = code;

      return this;
    }
  }
}