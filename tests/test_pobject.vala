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

  public class MyObject : PObject.Object
  {
  }

  public static void test_pobject_object_f_all( )
  {
    MyObject[] objects = MyObject.all( );
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
