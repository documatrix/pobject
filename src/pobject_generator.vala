/**
 * This file contains the code for the PObject generator utility.
 */

namespace PObject
{
  /**
   * This method can be called to generate someting.
   * @param argv The arguments passed to the pobject utility.
   */
  public static void generate( string[] argv )
  {
    switch ( argv[ 2 ].down( ) )
    {
      case "migration":
        if ( argv.length <= 3 )
        {
          DMLogger.log.error( 0, false, "No migration name specified! Please specify a migration name!" );
        }
        else
        {
          generate_migration( argv[ 3 ] );
        }
        break;

      default:
        DMLogger.log.error( 0, false, "Unknown object type ${1} for pobject generator!", argv[ 2 ] );
        break;
    }
  }

  /**
   * This method will create a given migration file.
   * @param migration_name The name of the migration which should be created.
   */
  public void generate_migration( string migration_name )
  {
    if ( !OpenDMLib.IO.file_exists( PObject.migrations_path ) || !OpenDMLib.IO.is_directory( PObject.migrations_path ) )
    {
      DMLogger.log.error( 0, false, "Specified migrations directory ${1} is not a valid directory!", PObject.migrations_path );
      return;
    }

    string migration_file = OpenDMLib.get_dir( PObject.migrations_path ) + migration_name + ".vala";
    DMLogger.log.info( 0, false, "Creating migration file ${1}", migration_file );
    string date_time = new OpenDMLib.DMDateTime.now_local( ).format( "%Y%m%d%H%M%S" );
    try
    {
      /* Write migration vala file */
      FileStream? fout = OpenDMLib.IO.open( migration_file, "wb" );
      fout.puts( "
public class " + migration_name + " : PObject.Migration
{
  public " + migration_name + "( )
  {
    this.migration_name = \"" + migration_name + "\";
    this.migration_date_time = \"" + date_time + "\";
  }

  /**
   * @see PObject.Migration.up
   */
  public void up( ) throws DBLib.DBError, PObject.Error
  {
    /* Write code to make changes on the database. */
  }

  /**
   * @see PObject.Migration.down
   */
  public void down( ) throws DBLib.DBError, PObject.Error
  {
    /* Write code to revert the changes made by \"up\" on the database. */
  }
}
" );

      /* Register migration in migrations.json */
      string migrations_json = OpenDMLib.get_dir( PObject.migrations_path ) + "migrations.json";
      try
      {
        Json.Object migrations;
        if ( OpenDMLib.IO.file_exists( migrations_json ) )
        {
          Json.Parser p = new Json.Parser( );
          p.load_from_file( migrations_json );

          migrations = p.get_root( ).get_object( );
        }
        else
        {
          migrations = new Json.Object( );
          migrations.set_array_member( "migrations", new Json.Array( ) );
        }

        Json.Array migrations_array = migrations.get_array_member( "migrations" );
        Json.Object migration_object = new Json.Object( );
        migration_object.set_string_member( "migration", migration_name );
        migration_object.set_string_member( "date_time", date_time );
        migrations_array.add_object_element( migration_object );

        Json.Node root = new Json.Node( Json.NodeType.OBJECT );
        root.set_object( migrations );
        Json.Generator g = new Json.Generator( );
        g.set_root( root );
        g.to_file( migrations_json );
      }
      catch ( Error e )
      {
        DMLogger.log.error( 0, false, "Error while writing migrations to json file ${1}! ${2}", migrations_json, e.message );
        return;
      }
    }
    catch ( OpenDMLib.IO.OpenDMLibIOErrors e )
    {
      DMLogger.log.error( 0, false, "Error while writing migration to ${1}! ${2}", migration_file, e.message );
    }
  }
}