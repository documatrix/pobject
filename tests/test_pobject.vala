using Testlib;

public class TestPObject
{
  public static int main( string[] args )
  {
    GLib.Test.init( ref args );

    GLib.TestSuite ts_dblib = new GLib.TestSuite( "PObject" );
    GLib.TestSuite.get_root( ).add_suite( ts_dblib );

    GLib.Test.run( );
    return 0;
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
