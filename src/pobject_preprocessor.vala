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

      if ( /^\s*\[\s*PObject\s*\(([^\)]*)\)\s*\]\s*$/.match( this.code_line, 0, out mi ) )
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
      return /^\s*\[\s*PObject[^\]]*\]\s*$/.match( code_line );
    }
  }

  /**
   * Objects of this class represent relations between objects which should be generated.
   */
  public class PObjectRelation : GLib.Object
  {
    public string relation_name;

    public string related_class_name;

    public unowned PObjectField foreign_key;
  }

  /**
   * Objects of this class represent fields of PObject classes.
   */
  public class PObjectField : GLib.Object
  {
    /**
     * This variable contains the vala field name.
     */
    public string field_name;

    /**
     * This variable contains the gobject-style field name.
     */
    public string gobject_field_name;

    /**
     * This variable contains the database field name.
     */
    public string db_field_name;

    /**
     * This variable contains the vala type of the field.
     */
    public string type;

    /**
     * This variable contains the vala type of the field (like @see PObjectField.type) but it just contains the non-null
     * version of the type.
     * So non_null_type may contain the same value like type does.
     */
    public string non_null_type;

    /**
     * This variable indicates if the field may contain null values.
     */
    public bool nullable_type;

    /**
     * This variable contains the annotation which was just before the field definition.
     */
    public PObjectAnnotation field_annotation;

    /**
     * The PObjectClass object which contains the newly created field.
     */
    public unowned PObjectClass klass;

    /**
     * This variable is true if the field is the primary key field of the object (can be set via primary_key annotation).
     */
    public bool primary_key;
    
    /**
     * This constructor creates a new PObjectField object and initializes the values.
     * @param klass @see PObjectField.klass
     * @param field_name @see PObjectField.field_name
     * @param type @see PObjectField.type
     * @param field_annotation @see PObjectField.field_annotation
     */
    public PObjectField( PObjectClass klass, string field_name, string type, PObjectAnnotation field_annotation )
    {
      this.klass = klass;
      this.field_name = field_name;
      this.gobject_field_name = this.field_name.replace( "_", "-" );
      this.type = type;
      this.field_annotation = field_annotation;

      if ( this.type.has_suffix( "?" ) )
      {
        this.nullable_type = true;
        this.non_null_type = this.type.substring( 0, -2 );
      }
      else
      {
        this.nullable_type = false;
        this.non_null_type = this.type;
      }

      this.db_field_name = ( this.klass.class_annotation.values[ "field_prefix" ] ?? "" ) + this.field_annotation.values[ "field_name" ];
      this.primary_key = bool.parse( this.field_annotation.values[ "primary_key" ] ?? "false" );

      DMLogger.log.debug( 0, false, "Found field ${1} - db field ${2}", this.field_name, this.db_field_name );
    }

    /**
     * This method returns the code which will convert the db data type (string) to the vala data type.
     * @param val_expr The expression which will return the value in the final code.
     * @return The code which will convert the db data type to the vala data type.
     */
    public string get_convert_from_db( string val_expr )
    {
      switch ( this.non_null_type )
      {
        case "string":
          return val_expr;

        case "int64":
          return "int64.parse( %s )".printf( val_expr );

        case "uint64":
          return "uint64.parse( %s )".printf( val_expr );

        case "int32":
          return "(int32)int64.parse( %s )".printf( val_expr );

        case "uint32":
          return "(uint32)uint64.parse( %s )".printf( val_expr );

        case "int16":
          return "(int16)int64.parse( %s )".printf( val_expr );

        case "uint16":
          return "(uint16)uint64.parse( %s )".printf( val_expr );

        case "int8":
          return "(int8)int64.parse( %s )".printf( val_expr );

        case "uint8":
          return "(uint8)uint64.parse( %s )".printf( val_expr );

        case "bool":
          return "int.parse( %s ) != 0".printf( val_expr );

        default:
          return "";
      }
    }

    /**
     * This method returns the code which will convert the vala data type to the db data type (string).
     * @param val_expr The expression which will return the value in the final code.
     * @return The code which will convert the vala data type to the db data type.
     */
    public string get_convert_to_db( string val_expr )
    {
      switch ( this.non_null_type )
      {
        case "string":
          return val_expr;

        case "int64":
        case "uint64":
        case "int32":
        case "uint32":
        case "int16":
        case "uint16":
        case "int8":
        case "uint8":
          return "%s.to_string( )".printf( val_expr );

        case "bool":
          return "%s ? \"1\" : \"0\"".printf( val_expr );

        default:
          return "";
      }
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
     * The fields of this class.
     * The key is the field name.
     */
    public HashTable<string?,PObjectField?> fields;

    /**
     * This variable contains the primary key field of the object.
     */
    public PObjectField? primary_key_field;

    /**
     * This constructor creates a new PObjectClass object.
     * @param class_name The name of the class in the input file.
     * @param class_annotation The annotation which was before the class definition.
     */
    public PObjectClass( string class_name, PObjectAnnotation class_annotation )
    {
      this.class_name = class_name;
      this.class_annotation = class_annotation;
      this.fields = new HashTable<string?,PObjectField?>( str_hash, str_equal );
      this.primary_key_field = null;
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

      string code = PObjectClass.class_template_code.replace( ":object_class:", this.class_name )
                                 .replace( ":table_name:", this.class_annotation.values[ "table_name" ] );

      /* Add pobject_..._changed fields */
      string[] _field_names = { };
      string[] _values = { };

      foreach ( unowned PObjectField field in this.fields.get_values( ) )
      {
        code += "\nprivate bool pobject_%s_changed = false;\n".printf( field.field_name );

        _field_names += field.db_field_name;
        _values += "PObject.connection.escape(" + field.get_convert_to_db( "this." + field.field_name ) + ")";
      }
      string field_names = string.joinv( ", ", _field_names );
      string values = "\" + " + string.joinv( " + \", \" + ", _values ) + " + \"";

      /* Add pobject_field_changed method */
      code += "\nprivate void pobject_field_changed( ParamSpec field )\n" +
              "{\n" +
              "  string field_name = field.get_name( );\n" +
              "  switch ( field_name )\n" +
              "  {\n";
      foreach ( unowned PObjectField field in this.fields.get_values( ) )
      {
        code += ( "    case \"%s\":\n" +
                  "      this.pobject_%s_changed = true;\n" +
                  "      this.pobject_dirty = true;\n" +
                  "      break;\n\n" ).printf( field.gobject_field_name, field.field_name );
      }
      code += "  }\n}\n";

      /* Add set_db_data method */
      code += "\npublic override void set_db_data( HashTable<string?,string?> db_data )\n" +
              "{\n" +
              "  this.new_record = false;\n" +
              "  this.freeze_notify( );\n" +
              "  foreach ( unowned string? db_field in db_data.get_keys( ) )\n" +
              "  {\n" +
              "    if ( db_data[ db_field ] != null )\n" +
              "    {\n" +
              "      switch ( db_field )\n" +
              "      {\n";
      foreach ( unowned PObjectField field in this.fields.get_values( ) )
      {
        
        code += ( "        case \"%s\":\n" +
                  "          this.%s = %s;\n" +
                  "          break;\n\n" ).printf( field.db_field_name, field.field_name, field.get_convert_from_db( "db_data[ db_field ]" ) );
      }
      code += "      }\n" +
              "    }\n" +
              "  }\n" +
              "  this.thaw_notify( );\n" +
              "}\n";

      /* Add insert method */
      code += "public override void insert( ) throws DBLib.DBError\n" +
              "{\n" +
              "  string statement = \"insert into " + this.class_annotation.values[ "table_name" ] + " (" + field_names + ") value (" + values + ")\";\n" +
              "  PObject.connection.execute( statement );\n";
      if ( this.primary_key_field != null )
      {
        code += "  uint64 last_id = PObject.connection.get_insert_id( );\n" +
                "  if ( last_id != 0 )\n" +
                "  {\n" +
                "    this." + this.primary_key_field.field_name + " = last_id;\n" +
                "  }\n";
      }
      code += "}\n";

      if ( this.primary_key_field != null )
      {
        /* Add update method */
        code += "public override void update( ) throws DBLib.DBError\n" +
                "{\n" +
                "  bool first = true;\n" +
                "  StringBuilder statement = new StringBuilder( \"update " + this.class_annotation.values[ "table_name" ] + " set \" );\n";
        foreach ( unowned PObjectField field in this.fields.get_values( ) )
        {
          code += "  if ( this.pobject_" + field.field_name + "_changed == true )\n" +
                  "  {\n" +
                  "    if ( first == false )\n" +
                  "    {\n" +
                  "      statement.append( \", \" );\n" +
                  "    }\n" +
                  "    else\n" +
                  "    {\n" +
                  "      first = false;\n" +
                  "    }\n" +
                  "    statement.append( \"" + field.db_field_name + " = \" + PObject.connection.escape( " + field.get_convert_to_db( "this." + field.field_name ) + " ) );\n" +
                  "  }\n";
        }
        code += "  statement.append( \" where " + this.primary_key_field.db_field_name + " = \" + PObject.connection.escape( " + primary_key_field.get_convert_to_db( "this." + primary_key_field.field_name ) + ") );\n" +
                "  PObject.connection.execute( statement.str );\n" +
                "}\n";

        /* Add find method */
        code += "public static " + this.class_name + "? find( " + this.primary_key_field.non_null_type + " " + this.primary_key_field.field_name + " ) throws PObject.Error.DBERROR\n" +
                "{\n" +
                "  return (" + this.class_name + "?)" + this.class_name + ".select( ).where( \"" + this.primary_key_field.db_field_name + " = ?\", " + this.primary_key_field.get_convert_to_db( this.primary_key_field.field_name ) + " ).first( );\n" +
                "}\n";

        /* Add delete method */
        code += "public override void delete( ) throws PObject.Error.DBERROR\n" +
                "{\n" +
                "  if ( this.new_record )\n" +
                "  {\n" +
                "    throw new PObject.Error.DBERROR( \"Tried to delete a record which does not exist in the database!\" );\n" +
                "  }\n" +
                "  else\n" +
                "  {\n" +
                "    try\n" +
                "    {\n" +
                "      PObject.connection.execute( \"delete from " + this.class_annotation.values[ "table_name" ] + " where " + this.primary_key_field.db_field_name + " = \" + PObject.connection.escape( " + this.primary_key_field.get_convert_to_db( "this." + this.primary_key_field.field_name ) + " ) );\n" +
                "    }\n" +
                "    catch ( DBLib.DBError e )\n" +
                "    {\n" +
                "      throw new PObject.Error.DBERROR( \"Error while deleting a record from database! %s!\", e.message );\n" +
                "    }\n" +
                "    this.new_record = true;\n" +
                "  }\n" +
                "}\n";
      }

      return code;
    }

    /**
     * This method will check if the given line is a field definition line.
     * If it is so it will add the field definition to the class.
     * @param line A code line which may contain a field definition.
     * @param field_annotation An annotation object which contains the last annotation.
     * @return true if a field definition was found, false otherwise.
     */
    public bool check_field_definition( string line, PObjectAnnotation field_annotation )
    {
      MatchInfo mi;
      
      if ( /^\s*(public|private|protected)?\s+([a-z0-9]+)\s+([a-zA-Z0-9_]+)\s+\{.*\}\s*$/.match( line, 0, out mi ) )
      {
        PObjectField field = new PObjectField( this, mi.fetch( 3 ), mi.fetch( 2 ), field_annotation );
        this.fields[ mi.fetch( 3 ) ] = field;

        if ( field.primary_key )
        {
          this.primary_key_field = field;
        }

        return true;
      }

      return false;
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

    int64 line_nr = 0;

    bool class_found = false;
    bool in_class = false;
    string? current_class_name = null;
    PObjectAnnotation? current_annotation = null;
    PObjectClass? current_class = null;

    HashTable<string?,PObjectClass?> classes = new HashTable<string?,PObjectClass?>( str_hash, str_equal );
    HashTable<int64?,string?> class_lines = new HashTable<int64?,string?>( int64_hash, int64_equal );

    while ( ( line = fin.read_line( ) ) != null )
    {
      line_nr ++;

      MatchInfo mi;
      if ( /class\s+([a-zA-Z0-9_]+)\s+:\s+PObject.Object/.match( line, 0, out mi ) )
      {
        current_class_name = mi.fetch( 1 );
        DMLogger.log.debug( 0, false, "${1}: Found class ${2} at line ${3}.", path, current_class_name, line_nr.to_string( ) );

        class_found = true;
      }

      if ( class_found && line.contains( "{" ) )
      {
        in_class = true;
        class_found = false;
      }

      /**
       * Inject template code.
       */
      if ( in_class && current_class_name != null && current_annotation != null )
      {
        DMLogger.log.debug( 0, false, "${1}: Will inject class code after line ${2}.", path, line_nr.to_string( ) );

        current_class = new PObjectClass( current_class_name, current_annotation );
        classes[ current_class_name ] = current_class;
        class_lines[ line_nr ] = current_class_name;

        current_class_name = null;
        current_annotation = null;
        in_class = false;
      }
      else if ( PObjectAnnotation.contains_annotation( line ) )
      {
        DMLogger.log.debug( 0, false, "${1}: Line ${2} contains a pobject annotation.", path, line_nr.to_string( ) );
        current_annotation = new PObjectAnnotation( line );
      }
      else
      {
        if ( current_class != null && current_annotation != null )
        {
          current_class.check_field_definition( line, current_annotation );
          current_annotation = null;
        }
      }
    }

    fin.seek( 0, FileSeek.SET );
    line_nr = 0;

    fout.puts( PObject.PREPROCESSED_HEADER + "\n" );
    while ( ( line = fin.read_line( ) ) != null )
    {
      line_nr ++;
  
      fout.puts( line + "\n" );

      if ( class_lines[ line_nr ] != null )
      {
        PObjectClass? klass = classes[ class_lines[ line_nr ] ];
        if ( klass != null )
        {
          DMLogger.log.debug( 0, false, "Injecting class code of class ${1} after line ${2}", klass.class_name, line_nr.to_string( ) );

          fout.puts( "\n/* POBJECT_INJECTED */\n" + klass.get_template_code( ) + "\n/* POBJECT_INJECTED */\n\n" );
        }
      }
    }
    fout = null;
    fin = null;

    OpenDMLib.IO.copy( out_file, path );
  }
}