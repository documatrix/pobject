using Testlib;
using PObject;

public class TestPObject
{
  public static int main( string[] args )
  {
    GLib.Test.init( ref args );

    GLib.TestSuite ts_pobject = new GLib.TestSuite( "PObject" );

    GLib.TestSuite ts_pobject_object = new GLib.TestSuite( "PObject" );
    ts_pobject_object.add(
      new GLib.TestCase(
        "test_f_all",
        TestPObject.default_setup,
        TestPObject.test_pobject_object_f_all,
        TestPObject.default_teardown
      )
    );
    ts_pobject.add_suite( ts_pobject_object ); 
    
    GLib.TestSuite.get_root( ).add_suite( ts_pobject );

    GLib.Test.run( );
    return 0;
  }

  [PObject ( table_name = "my_object", field_prefix = "my_" )]
  public class MyObject : PObject.Object
  {
    [PObject ( field_name="id", primary_key = true ) ]
    public uint64 id { get; set; }

    [PObject ( field_name = "comment" )]
    public string comment { get; set; }
  }

  public static void test_pobject_object_f_all( )
  {
    MyObject m = new MyObject( );
    m.comment = "obj4";
    m.save( );
    m.comment = "obj3";
    m.save( );
    
    MyObject[] objects = MyObject.all( );
    foreach ( MyObject object in objects )
    {
      stdout.printf( "id: %llu, comment: %s\n", object.id, object.comment );
    }
  }
  
  /**
   * This is the default setup method for the PObject tests.
   * It will setup a DMLogger.Logger object and then invoke the default_setup method from Testlib.
   */
  public static void default_setup( )
  {
    DMLogger.log = new DMLogger.Logger( null );
    DMLogger.log.set_config( true, "../log/messages.mdb" );
    DMLogger.log.start_threaded( );
    Testlib.default_setup( );

    try
    {
      PObject.init( DBLib.DBType.MYSQL, "hostname=localhost;database=test", "root", null );
      PObject.connection.execute( "drop table if exists my_object" );
      PObject.connection.execute( "create table my_object ( my_id bigint auto_increment primary key, my_comment varchar(255) )" );
      PObject.connection.execute( "insert into my_object (my_comment) value ('obj1'), ('obj2'), (NULL)" );
    }
    catch ( PObject.Error.DBERROR e )
    {
      assert_not_reached( );
    }
  }

  /**
   * This is the default teardown method for the PObject tests.
   * It will stop the DMLogger.Logger and then invoke the default_teardown method from Testlib.
   */
  public static void default_teardown( )
  {
    if ( DMLogger.log != null )
    {
      DMLogger.log.stop( );
    }
    Testlib.default_teardown( );
  }
}
