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
  }
}