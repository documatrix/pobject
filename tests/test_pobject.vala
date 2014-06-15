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
        "test_f_save",
        TestPObject.default_setup,
        TestPObject.test_pobject_object_f_save,
        TestPObject.default_teardown
      )
    );
    ts_pobject_object.add(
      new GLib.TestCase(
        "test_f_all",
        TestPObject.default_setup,
        TestPObject.test_pobject_object_f_all,
        TestPObject.default_teardown
      )
    );
    ts_pobject_object.add(
      new GLib.TestCase(
        "test_f_reload",
        TestPObject.default_setup,
        TestPObject.test_pobject_object_f_reload,
        TestPObject.default_teardown
      )
    );
    ts_pobject_object.add(
      new GLib.TestCase(
        "test_s_has_one_relation",
        TestPObject.default_setup,
        TestPObject.test_pobject_object_s_has_one_relation,
        TestPObject.default_teardown
      )
    );
    ts_pobject.add_suite( ts_pobject_object ); 
    
    GLib.TestSuite.get_root( ).add_suite( ts_pobject );

    GLib.Test.run( );
    return 0;
  }

  /**
   * This class can be used for testing.
   */
  [PObject ( table_name = "my_object", field_prefix = "my_" )]
  public class MyObject : PObject.Object
  {
    [PObject ( field_name="id", primary_key = true ) ]
    public uint64 id { get; set; }

    [PObject ( field_name = "comment" )]
    public string comment { get; set; }
  }

  [PObject ( table_name = "my_object_b", field_prefix = "my_" )]
  public class MyObjectB : PObject.Object
  {
    [PObject ( field_name="id", primary_key = true ) ]
    public uint64 id { get; set; }

    [PObject ( has_one="MyObject" )]
    public uint64 my_object_id { get; set; }
  }

  /**
   * This testcase tests the save method.
   * It will test the insert and update functionality.
   */
  public static void test_pobject_object_f_save( )
  {
    try
    {
      MyObject m = new MyObject( );
      m.comment = "obj1";
      assert( m.id == 0 );
      assert( m.new_record == true );
      m.save( );
      assert( m.id == 1 );
      assert( m.new_record == false );

      MyObject? m2 = (MyObject)MyObject.select( ).where( "my_id = ?", "1" ).first( );
      assert( m2 != null );
      assert( m2.comment == "obj1" );

      m.comment = "obj1_changed";
      assert( m.pobject_dirty == true );
      m.save( );
      assert( m.id == 1 );
      assert( m.pobject_dirty == false );

      m2 = (MyObject)MyObject.select( ).where( "my_id = ?", "1" ).first( );
      assert( m2 != null );
      assert( m2.comment == "obj1_changed" );
    }
    catch ( PObject.Error e )
    {
      assert_not_reached( );
    }
  }

  /**
   * This testcase tests the .all method which will return every object
   * from the databse/table.
   */
  public static void test_pobject_object_f_all( )
  {
    MyObject m = new MyObject( );
    m.comment = "obj1";
    m.save( );
    m = new MyObject( );
    m.comment = "obj2";
    m.save( );
    m = new MyObject( );
    m.comment = "obj3";
    m.save( );

    MyObject[] objects = MyObject.all( );
    assert( objects.length == 3 );
    for ( uint8 i = 0; i < objects.length; i ++ )
    {
      assert( objects[ i ].comment == "obj%u".printf( i + 1 ) );
    }
  }

  /**
   * This testcase tests the has_one relation type between objects.
   */
  public static void test_pobject_object_s_has_one_relation( )
  {
    MyObject m = new MyObject( );
    m.comment = "obj1";
    m.save( );
    assert( m.id == 1 );

    MyObjectB m_b = new MyObjectB( );
    m_b.my_object = m;
    assert( m_b.my_object_id == m.id );
    m_b.save( );

    MyObjectB? m_b2 = (MyObjectB?)MyObjectB.select_join( ).first( );
    assert( m_b2 != null );
    assert( m_b2.my_object.id == m.id );

    m_b.my_object_id = 0;
    m_b.save( );

    m_b2.reload( );
    assert( m_b2.my_object == null );
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
      PObject.connection.execute( "drop table if exists my_object_b" );
      PObject.connection.execute( "create table my_object_b ( my_id bigint auto_increment primary key, my_my_object_id bigint unsigned not null )" );
    }
    catch ( PObject.Error.DBERROR e )
    {
      assert_not_reached( );
    }
  }

  /**
   * This testcase tests the reload method which can be used to reload an object from
   * the database.
   */
  public static void test_pobject_object_f_reload( )
  {
    try
    {
      MyObject m = new MyObject( );
      m.comment = "obj1";
      assert( m.reload( ) == false );
      m.save( );

      MyObject? m2 = (MyObject)MyObject.select( ).where( "my_id = ?", "1" ).first( );
      assert( m2 != null );
      assert( m2.comment == "obj1" );

      m.comment = "obj1_changed";
      assert( m.pobject_dirty == true );
      m.save( );

      assert( m2.reload( ) == true );
      assert( m2.comment == "obj1_changed" );
    }
    catch ( PObject.Error e )
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
