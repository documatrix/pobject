/**
 * This file contains the pobject preprocessor which can be called from the pobject util.
 */

namespace PObject
{
  /**
   * This header will be written in every preprocess file to indicate, that it was already preprocessed.
   */
  public static const string PREPROCESSED_HEADER = "/* POBJECT PREPROCESSED */";

  /**
   * This method can be called for a file or directory to process it.
   * If the passed path is a directory it will iterate recursively through the directory tree.
   * The preprocess method will only preprocess vala files.
   * @param path A path to a directory or file which should be preprocessed using the preprocess_file method.
   */
  public void preprocess( string path )
  {
    if ( OpenDMLib.IO.file_exists( path ) )
    {
      if ( OpenDMLib.IO.is_directory( path ) )
      {
        Dir d = Dir.open( path );
        unowned string? name;
        while ( ( name = d.read_name( ) ) != null )
        {
          if ( name != "." && name != ".." )
          {
            preprocess( OpenDMLib.get_dir( path ) + name );
          }
        }
      }
      else if ( path.has_suffix( ".vala" ) )
      {
        preprocess_file( path );
      }
    }
    else
    {
      DMLogger.log.error( 0, false, "Path ${1} does not exist!", path );
    }
  }

  /**
   * This method will preprocess the given file.
   * @param path A path to a file which should be preprocessed.
   */
  public void preprocess_file( string path )
  {
    string class_template_code;
    FileUtils.get_contents( PObject.template_path + "pobject_template.vala", out class_template_code );
    
    DMLogger.log.info( 0, false, "Preprocessing ${1}", path );

    FileStream? fin = null;
    try
    {
      fin = OpenDMLib.IO.open( path, "rb" );
    }
    catch ( Error e )
    {
      DMLogger.log.error( 0, false, "Error while opening ${1} for reading! ${2}", path, e.message );
      return;
    }

    string? line = fin.read_line( );
    if ( line != null && line.contains( PObject.PREPROCESSED_HEADER ) )
    {
      return;
    }
    fin.seek( 0, FileSeek.SET );

    string out_file = OpenDMLib.get_temp_file( );
    FileStream? fout = null;
    try
    {
      fout = OpenDMLib.IO.open( out_file, "wb" );
    }
    catch ( Error e )
    {
      DMLogger.log.error( 0, false, "Error while opening ${1} for writing! ${2}", out_file, e.message );
      return;
    }

    int64 line_nr = 1;

    bool class_found = false;
    bool in_class = false;
    string? current_class = null;

    fout.puts( PObject.PREPROCESSED_HEADER + "\n" );
    while ( ( line = fin.read_line( ) ) != null )
    {
      MatchInfo mi;
      if ( /class\s+([a-zA-Z0-9_]+)\s+:\s+PObject.Object/.match( line, 0, out mi ) )
      {
        current_class = mi.fetch( 1 );
        DMLogger.log.debug( 0, false, "${1}: Found class ${2} at line ${3}.", path, current_class, line_nr.to_string( ) );

        class_found = true;
      }

      if ( class_found && line.contains( "{" ) )
      {
        in_class = true;
        class_found = false;
      }
        
      fout.puts( line + "\n" );

      /**
       * Inject template code.
       */
      if ( in_class && current_class != null )
      {
        DMLogger.log.debug( 0, false, "${1}: Injecting class code after line ${2}.", path, line_nr.to_string( ) );

        fout.puts( class_template_code.replace( ":object_class:", current_class ) );

        in_class = false;
      }

      line_nr ++;
    }
    fout = null;
    fin = null;

    OpenDMLib.IO.copy( out_file, path );
  }
}