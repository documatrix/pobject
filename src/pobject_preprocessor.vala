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
   * This class represents a code annotation for the pobject library
   */
  public class PObjectAnnotation : GLib.Object
  {
    /**
     * This variable contains the original code line which lead to this annotation object.
     */
    public string code_line;

    /**
     * This hashtable contains every value defined in the annotation.
     */
    public HashTable<string?,string?> values;

    /**
     * This constructor creates an annotation object for the given code line.
     * @param code_line The source code line which should be parsed.
     */
    public PObjectAnnotation( string code_line )
    {
      MatchInfo mi;
      this.code_line = code_line;
      this.values = new HashTable<string?,string?>( str_hash, str_equal );

      if ( /^\s*\[PObject\s*\(([^\)]*)\)\s*\]\s*$/.match( this.code_line, 0, out mi ) )
      {
        DMLogger.log.debug( 0, false, "Found annotation values ${1}", mi.fetch( 1 ) );
        string[] values = mi.fetch( 1 ).split( "," );
        foreach ( string val in values )
        {
          string[] tokens = val.split( "=" );

          string k = tokens[ 0 ].strip( );
          string v = tokens[ 1 ].strip( ).replace( "\"", "" );
          DMLogger.log.debug( 0, false, "Found key ${1} = value ${2}", k, v );
          this.values[ k ] = v;
        } 
      }
    }

    /**
     * This method checks if a given code line contains an annotation.
     * @param code_line The code line to check.
     * @return true if the given code_line contains an annotation, false otherwise.
     */
    public static bool contains_annotation( string code_line )
    {
      return /^\s*\[PObject[^\]]*\]\s*$/.match( code_line );
    }
  }

  /**
   * Objects of this class represent a found class in the preprocessing-step.
   */
  public class PObjectClass : GLib.Object
  {
    /**
     * This variable contains the annotation found before the class definition.
     */
    public PObjectAnnotation class_annotation;

    /**
     * This variable contains the class name.
     */
    public string class_name;

    /**
     * This variable will be used by the get_template_code method to store the class template code.
     */
    public static string? class_template_code = null;

    /**
     * This constructor creates a new PObjectClass object.
     * @param class_name The name of the class in the input file.
     * @param class_annotation The annotation which was before the class definition.
     */
    public PObjectClass( string class_name, PObjectAnnotation class_annotation )
    {
      this.class_name = class_name;
      this.class_annotation = class_annotation;
    }

    /**
     * This method returns the template code for this class.
     * The template code can then be injected in the preprocessed file.
     * @return A code snippet containing the class template code with replaced placeholders.
     */
    public string get_template_code( )
    {
      if ( PObjectClass.class_template_code == null )
      {
        FileUtils.get_contents( PObject.template_path + "pobject_template.vala", out PObjectClass.class_template_code );
      }

      return class_template_code.replace( ":object_class:", this.class_name )
                                 .replace( ":table_name:", this.class_annotation.values[ "table_name" ] );
    }
  }

  /**
   * This method will preprocess the given file.
   * @param path A path to a file which should be preprocessed.
   */
  public void preprocess_file( string path )
  {
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
    string? current_class_name = null;
    PObjectAnnotation? current_annotation = null;
    PObjectClass? current_class = null;

    fout.puts( PObject.PREPROCESSED_HEADER + "\n" );
    while ( ( line = fin.read_line( ) ) != null )
    {
      MatchInfo mi;
      if ( /class\s+([a-zA-Z0-9_]+)\s+:\s+PObject.Object/.match( line, 0, out mi ) )
      {
        current_class_name = mi.fetch( 1 );
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
      if ( in_class && current_class_name != null && current_annotation != null )
      {
        DMLogger.log.debug( 0, false, "${1}: Injecting class code after line ${2}.", path, line_nr.to_string( ) );

        current_class = new PObjectClass( current_class_name, current_annotation );
        fout.puts( current_class.get_template_code( ) );

        current_class_name = null;
        current_annotation = null;
        in_class = false;
      }
      else if ( PObjectAnnotation.contains_annotation( line ) )
      {
        DMLogger.log.debug( 0, false, "${1}: Line ${2} contains a pobject annotation.", path, line_nr.to_string( ) );
        current_annotation = new PObjectAnnotation( line );
      }

      line_nr ++;
    }
    fout = null;
    fin = null;

    OpenDMLib.IO.copy( out_file, path );
  }
}