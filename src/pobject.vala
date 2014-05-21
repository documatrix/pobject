/**
 * This file contains the code of the pobject util executable.
 * (c) 2014 by DocuMatrix
 */

namespace PObject
{
  /**
   * This is the product name.
   */
  public const string product_name = "pobject";

  /**
   * This is the product version.
   */
  public const string product_version = "0.1 :::DATETIME:::, :::GITVERSION:::";

  /**
   * If print_version is set, the product name and version will be displayed and the program will exit.
   */
  static bool print_version = false;

  /**
   * This is the log_file for the DMLogger object.
   */
  static string? log_file = null;

  /**
   * This is the message database file for the DMLogger object.
   */
  static string? mdb_file = null;

  /**
   * If log_to_console is set, the output will be logged to the console.
   */
  static bool log_to_console = true;

  /**
   * This variable contains the path to the template files for the preprocessor.
   */
  static string? template_path = null;

  /**
   * This variable contains the path which contains the migration files.
   */
  static string? migrations_path = null;

  /**
   * These option entries will be used to read the command-line parameters.
   */
  const OptionEntry[] entries = {
    { "version", 'v', 0, OptionArg.NONE, ref print_version, "Print Version", null },
    { "logfile", 'L', 0, OptionArg.STRING, ref log_file, "Filename of the Log-File", "Log-File" },
    { "log-to-console", 'l', 0, OptionArg.NONE, ref log_to_console, "Log output direct to console (default off)", null },
    { "mdbfile", 'm', 0, OptionArg.STRING, ref mdb_file, "Filename of the Message-Database-File", "Message-Database-File" },
    { "template-path", 't', 0, OptionArg.STRING, ref template_path, "Directory containing the template files for the pobject preprocessor", "Template directory" },
    { "migrations-path", 'M', 0, OptionArg.STRING, ref migrations_path, "Directory containing the migration files of the project", "Migrations directory" },
    { null }
  };

  public int main( string[] args )
  {
    stdout.printf( "Starting %s, Version %s\n", PObject.product_name, PObject.product_version );

    /* Check if threads are supported, if not, cancel execution. */
    if ( !Thread.supported( ) )
    {
      stderr.printf( "Cannot execute pobject without thread support!\n" );
      return 1;
    }

    /* Read command-line parameters */
    try
    {
      OptionContext context = new OptionContext( "- " + PObject.product_name + " Version " + PObject.product_version );
      context.set_help_enabled( true );
      context.add_main_entries( PObject.entries, "test" );
      context.parse( ref args );

      if ( PObject.template_path == null )
      {
        PObject.template_path = OpenDMLib.get_dir( OpenDMLib.get_dir( Constants.DATADIR ) + "pobject/templates" );
      }

      if ( PObject.migrations_path == null )
      {
        PObject.migrations_path = "./src/";
      }

      if ( mdb_file == null )
      {
        mdb_file = OpenDMLib.ensure_ps( OpenDMLib.get_dir( Constants.DATADIR ) + "pobject/log/messages.mdb" );
      }
      
      if ( PObject.print_version == true )
      {
        stdout.printf( "%s, Version %s\n", PObject.product_name, PObject.product_version );
        return 0;
      }

      if ( PObject.log_file == null )
      {
        TimeVal tv = TimeVal( );
        tv.get_current_time( );
        PObject.log_file = "%s_%s_%d.binlog".printf( args[ 0 ], tv.to_iso8601( ).replace( "-", "_" ).replace( ":", "_" ), OpenDMLib.getpid( ) );
        stdout.printf( "Falling back to log-file %s\n", PObject.log_file );
      }
    }
    catch ( Error e )
    {
      stderr.printf( "Error while parsing Options: %s!\n", e.message );
      return 1;
    }

    DMLogger.log = new DMLogger.Logger( PObject.log_file );
    DMLogger.log.set_config( PObject.log_to_console, PObject.mdb_file );
    DMLogger.log.start_threaded( );

    DMLogger.log.info( 0, false, "Starting ${1}, Version ${2}", PObject.product_name, PObject.product_version );

    if ( args.length == 1 )
    {
      DMLogger.log.error( 0, false, "No command specified for pobject util!" );
    }
    else
    {
      switch ( args[ 1 ].down( ) )
      {
        case "preprocess":
          DMLogger.log.debug( 0, false, "Using template path ${1}", PObject.template_path );
          for ( int i = 2; i < args.length; i ++ )
          {
            PObject.preprocess( args[ i ] );
          }
          break;

        case "generate":
          if ( args.length <= 2 )
          {
            DMLogger.log.error( 0, false, "I do not know what to generate! Please specify a generate-type!" );
          }
          else
          {
            PObject.generate( args );
          }
          break;

        default:
          DMLogger.log.error( 0, false, "Specified command ${1} is not a valid command!", args[ 1 ] );
          break;
      }
    }
    
    DMLogger.log.stop( );

    return 0;
  }
}