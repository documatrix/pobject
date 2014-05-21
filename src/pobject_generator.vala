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

    string migration_file = PObject.migrations_path + migration_name + ".vala";
    string class_init_file = PObject.migrations_path + "init_migrations.vala";
    DMLogger.log.info( 0, false, "Creating migration file ${1}", migration_file );
    string date_time = new OpenDMLib.DMDateTime.now_local( ).format( "%Y%m%d%H%M%S" );
    try
    {
      /* Write migration vala file */
      FileStream? fout = OpenDMLib.IO.open( migration_file, "wb" );
      fout.puts( "
public class " + migration_name + " : PObject.Migration
{
  construct
  {
    this.migration_name = \"" + migration_name + "\";
    this.migration_date_time = \"" + date_time + "\";
  }

  /**
   * @see PObject.Migration.up
   */
  public override void up( ) throws DBLib.DBError, PObject.Error
  {
    /* Write code to make changes on the database. */
  }

  /**
   * @see PObject.Migration.down
   */
  public override void down( ) throws DBLib.DBError, PObject.Error
  {
    /* Write code to revert the changes made by \"up\" on the database. */
  }
}
" );

      /* Register migration in migrations.json */
      string migrations_json = PObject.migrations_path + "migrations.json";
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

        /* Rewrite migration-class-initialization vala file */
        fout = OpenDMLib.IO.open( class_init_file, "wb" );
        fout.puts( "
/**
 * This file contains the initialize_migration_classes method which has to be called by PObject to initialize.
 */
public void initialize_migration_classes( )
{\n" );
        for ( uint i = 0; i < migrations_array.get_length( ); i ++ )
        {
          fout.puts( "  typeof( " + migrations_array.get_object_element( i ).get_string_member( "migration" ) + " ).name( );\n" );
        }
        fout.puts( "}\n" );

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