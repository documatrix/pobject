/**
 * This file contains the pobject preprocessor which can be called from the pobject util.
 */

namespace PObject
{
  /**
   * This header will be written in every preprocess file to indicate, that it was already preprocessed.
   */
  public static const string PREPROCESSED_HEADER = "/* POBJECT PREPROCESSED */";

  private static HashTable<string?,PObjectClass?> classes;
  private static HashTable<string?,HashTable<int64?,string?>> class_lines;

  /**
   * This method can be called for a file or directory to process it.
   * If the passed path is a directory it will iterate recursively through the directory tree.
   * The preprocess method will only preprocess vala files.
   * @param path A path to a directory or file which should be preprocessed using the preprocess_file method.
   */
  public void preprocess( string path )
  {
    PObject.classes = new HashTable<string?,PObjectClass?>( str_hash, str_equal );
    PObject.class_lines = new HashTable<string?,HashTable<int64?,string?>>( str_hash, str_equal );

    OpenDMLib.DMArray<string> files = new OpenDMLib.DMArray<string>( );
    preprocess_first_pass( path, files );
    preprocess_second_pass( files );
  }

  /**
   * This method can be called to do the first pass of the preprocessing for a directory.
   * It will loop through the given path and call the @see PObject.preprocess_file method for each file.
   * It will also add each preprocessed file to the given files DMArray.
   * @param path A directory which should be used to search for files and preprocess them.
   * @param files A DMArray in which every preprocessed file should be added.
   */
  public void preprocess_first_pass( string path, OpenDMLib.DMArray<string> files )
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
            preprocess_first_pass( OpenDMLib.get_dir( path ) + name, files );
          }
        }
      }
      else if ( path.has_suffix( ".vala" ) )
      {
        preprocess_file( path );
        files.push( path );
      }
    }
    else
    {
      DMLogger.log.error( 0, false, "Path ${1} does not exist!", path );
    }
  }

  /**
   * This method will call the @see PObject.preprocess_file_second_pass method for each file which is stored
   * in the given files DMArray.
   * @param files A DMArray containing the files which should be preprocessed.
   */
  public void preprocess_second_pass( OpenDMLib.DMArray<string> files )
  {
    DMLogger.log.info( 0, false, "Preprocessing second pass..." );

    foreach ( string file in files )
    {
      DMLogger.log.info( 0, false, "Second pass for ${1}", file );
      preprocess_file_second_pass( file );
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

      this.db_field_name = ( this.klass.class_annotation.values[ "field_prefix" ] ?? "" ) + ( this.field_annotation.values[ "field_name" ] ?? this.field_name );
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

    /**
     * This method returns the code which will add the field to a json object.
     * It will only create the method call (not the object itself).
     * @param val_expr The expression which will return the value in the final code.
     * @return The code which will invoke a method on a Json.Object object to add the field value.
     */
    public string get_convert_to_json( string val_expr )
    {
      string code = "";
      switch ( this.non_null_type )
      {
        case "string":
          code = "set_string_member( \"%s\", %s )";
          break;

        case "int64":
        case "uint64":
        case "int32":
        case "uint32":
        case "int16":
        case "uint16":
        case "int8":
        case "uint8":
          code = "set_int_member( \"%s\", (int64)%s )";
          break;

        case "bool":
          code = "set_boolean_member( \"%s\", %s )";
          break;

        default:
          return "";
      }

      return code.printf( this.field_name, val_expr );
    }
  }

  /**
   * This enum contains the possible relation types.
   */
  public enum RelationType
  {
    /**
     * This relation type says that ObjectA has a reference to ObjectB via an object_b_id field in the ObjectA
     * class.
     */
    HAS_ONE;
  }

  /**
   * Objects of this class represent relations between objects.
   */
  public class PObjectRelation : GLib.Object
  {
    /**
     * This variable contains the vala variable name of the relation.
     */
    public string field_name;

    /**
     * This variable contains the (optionally created) foreign_key which references the object in this class.
     */
    public PObjectField? local_foreign_key;

    /**
     * This variable contains the type of the relation.
     */
    public RelationType relation_type;

    /**
     * This variable contains the annotation which was just before the field definition.
     */
    public PObjectAnnotation field_annotation;

    /**
     * The PObjectClass object which contains the newly created field.
     */
    public unowned PObjectClass klass;

    /**
     * This variable contains the vala data type of the related object.
     */
    public string type;

    /**
     * This variable contains the vala type of the field (like @see PObjectRelation.type) but it just contains the non-null
     * version of the type.
     * So non_null_type may contain the same value like type does.
     */
    public string non_null_type;

    /**
     * This variable indicates if the field may contain null values.
     */
    public bool nullable_type;

    /**
     * This variable contains the gobject-style field name.
     */
    public string gobject_field_name;

    /**
     * This constructor creates a new PObjectRelation object and initializes the values.
     * @param klass @see PObjectRelation.klass
     * @param field_name @see PObjectRelation.field_name
     * @param type @see PObjectRelation.type
     * @param field_annotation @see PObjectRelation.field_annotation
     */
    public PObjectRelation( PObjectClass klass, string field_name, string type, RelationType relation_type, PObjectField local_foreign_key )
    {
      this.klass = klass;
      this.field_name = field_name;
      this.gobject_field_name = this.field_name.replace( "_", "-" );
      this.non_null_type = type;
      this.field_annotation = field_annotation;
      this.local_foreign_key = local_foreign_key;

      if ( this.local_foreign_key.type.has_suffix( "?" ) )
      {
        this.nullable_type = true;
        this.type = type;
      }
      else
      {
        this.nullable_type = false;
        this.type = type + "?";
      }

      DMLogger.log.debug( 0, false, "Found relation ${1}", this.field_name );
    }

    /**
     * This method will return the vala code which represents the relation as property and will be inserted
     * to the final class code.
     * @return Vala code which represents the relation as property.
     */
    public string get_vala_code( )
    {
      PObjectClass? related_class = classes[ this.non_null_type ];

      string code = "private " + this.non_null_type + "? pobject_" + this.field_name + ";\n" +
                     "public " + this.type + " " + this.field_name + "{\n" +
                     "  get\n" +
                     "  {\n" +
                     "    if ( this.pobject_" + this.field_name + " == null )\n" +
                     "    {\n" +
                     "      this.pobject_" + this.field_name + " = " + this.non_null_type + ".find( this." + this.local_foreign_key.field_name + " );\n" + 
                     "    }\n" +
                     "    return this.pobject_" + this.field_name + ";\n" +
                     "  }\n" +
                     "  set\n" +
                     "  {\n" +
                     "    if ( value == null )\n" +
                     "    {\n" +
                     "      this." + this.local_foreign_key.field_name + " = 0;\n" +
                     "    }\n" +
                     "    else\n" +
                     "    {\n" +
                     "      this." + this.local_foreign_key.field_name + " = value." + related_class.primary_key_field.field_name + ";\n" +
                     "    }\n" +
                     "    this.pobject_" + this.field_name + " = value;\n" +
                     "  }\n" +
        "}\n";
      return code;
    }

    /**
     * This method returns the code which will be used by the get_join_code method of a pobject to
     * get the SQL join-code.
     * @return A string which can be used in a generated vala code which contains the SQL join-code to load this relation.
     */
    public string get_join_code( )
    {
      PObjectClass related_class = classes[ this.non_null_type ];
      string related_table = related_class.class_annotation.values[ "table_name" ];

      return " left outer join " + related_table + " on " + related_table + "." + related_class.primary_key_field.db_field_name + " = " + this.local_foreign_key.db_field_name;
    }

    /**
     * This method returns the addition to the fields clause of a select statement which joins this
     * relation.
     * @return A string which can be added before the from clause in a select statement which adds the
     *         fields of the joined table.
     */
    public string get_join_fields( )
    {
      PObjectClass? related_class = this.get_related_class( );
      if ( related_class == null )
      {
        DMLogger.log.error( 0, false, "Error while generating join fields code for relation ${1}! Related class ${2} not found!", this.field_name, this.non_null_type );
        return "";
      }
      
      string related_table = related_class.class_annotation.values[ "table_name" ];

      string[] fields = { };

      foreach ( PObjectField field in related_class.fields.get_values( ) )
      {
        fields += related_table + "." + field.db_field_name + " as `" + this.field_name + "." + field.db_field_name + "`";
      }

      return string.joinv( ", ", fields );
    }

    /**
     * This method will return the related class object of this relation.
     * @return The class which this relation relates to.
     */
    public PObjectClass get_related_class( )
    {
      return classes[ this.non_null_type ];
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
     * The relations of this class.
     * The key is the field name.
     */
    public HashTable<string?,PObjectRelation?> relations;

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
      this.relations = new HashTable<string?,PObjectRelation?>( str_hash, str_equal );
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
      code += "\npublic override void set_db_data( HashTable<string?,string?> db_data, bool contains_joins )\n" +
              "{\n" +
              "  this.new_record = false;\n" +
              "  this.freeze_notify( );\n";
      foreach ( unowned PObjectField field in this.fields.get_values( ) )
      {
        code += ( "  if ( db_data.lookup( \"%s\" ) != null )\n" +
                  "  {\n" +
                  "    this.%s = %s;\n" +
                  "  }\n\n" ).printf( field.db_field_name, field.field_name, field.get_convert_from_db( "db_data[ \"" + field.db_field_name + "\" ]" ) );
      }
      foreach ( unowned PObjectRelation relation in this.relations.get_values( ) )
      {
        code += "  this.pobject_%s = null;\n".printf( relation.field_name );
      }
      code += "  if ( contains_joins )\n" +
              "  {\n";
      foreach ( unowned PObjectRelation relation in this.relations.get_values( ) )
      {
        if ( relation.get_related_class( ) == null )
        {
          DMLogger.log.error( 0, false, "Error while generating template code for class ${1}! Related class ${2} for field ${3} not found!", this.class_name, relation.field_name, relation.non_null_type );
          continue;
        }
        foreach ( unowned PObjectField field in relation.get_related_class( ).fields.get_values( ) )
        {
          code += ( "    if ( db_data.lookup( \"%s.%s\" ) != null )\n" +
                    "    {\n" +
                    "      if ( this.pobject_%s == null )\n" +
                    "      {\n" +
                    "        this.pobject_" + relation.field_name + " = new " + relation.get_related_class( ).class_name + "( );\n" +
                    "      }\n" +
                    "      this.pobject_%s.%s = %s;\n" +
                    "    }\n" ).printf( relation.field_name, field.db_field_name, relation.field_name, relation.field_name, field.field_name, field.get_convert_from_db( "db_data[ \"" + relation.field_name + "." + field.db_field_name + "\" ]" ) );
        }
      }
      code += "  }\n" +
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

      /* Add to_json_object method */
      code += "public override Json.Object to_json_object( )\n" +
              "{\n" +
              "  Json.Object obj = new Json.Object( );\n";
      foreach ( unowned PObjectField field in this.fields.get_values( ) )
      {
        code += "  obj." + field.get_convert_to_json( field.field_name ) + ";\n";
      }
      foreach ( unowned PObjectRelation relation in this.relations.get_values( ) )
      {
        code += "  if ( this.pobject_" + relation.field_name + " != null )\n" +
                "  {\n" +
                "    obj.set_object_member( \"" + relation.field_name + "\", this.pobject_" + relation.field_name + ".to_json_object( ) );\n" +
                "  }\n";
      }
      code += "  return obj;\n" +
              "}\n";

      /* Add to_json method */
      code += "public override string to_json( )\n" +
              "{\n" +
              "  Json.Object obj = this.to_json_object( );\n" +
              "  Json.Node root = new Json.Node( Json.NodeType.OBJECT );\n" +
              "  root.set_object( obj );\n" +
              "  Json.Generator generator = new Json.Generator( );\n" +
              "  generator.set_root( root );\n" +
              "  return generator.to_data( null );\n" +
              "}\n";

      /* Add get_join_code method */
      string join_code = "";

      foreach ( PObjectRelation relation in this.relations.get_values( ) )
      {
        join_code += relation.get_join_code( );
      }
      if ( join_code == "" )
      {
        join_code = "null";
      }
      else
      {
        join_code = "\"" + join_code + "\"";
      }
      code += "public static string? get_join_code( )\n" +
              "{\n" +
              "  return " + join_code + ";\n" +
              "}\n";

      /* Add get_join_fields method */
      string join_fields = "";

      foreach ( PObjectRelation relation in this.relations.get_values( ) )
      {
        join_fields += ", " + relation.get_join_fields( );
      }
      code += "public static string get_join_fields( )\n" +
              "{\n" +
              "  return \"" + join_fields + "\";\n" +
              "}\n";

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

        /* Add reload method */
        code += "public override bool reload( ) throws PObject.Error.DBERROR\n" +
                "{\n" +
                "  if ( this.new_record )\n" +
                "  {\n" +
                "    return false;\n" +
                "  }\n" +
                "  try\n" +
                "  {\n" +
                "    DBLib.Statement stmt = PObject.connection.execute( \"select * from " + this.class_annotation.values[ "table_name" ] + " where " + this.primary_key_field.db_field_name + " = \" + PObject.connection.escape( " + this.primary_key_field.get_convert_to_db( "this." + this.primary_key_field.field_name ) + " ) );\n" +
                "    HashTable<string?,string?>? row;\n" +
                "    if ( ( row = stmt.result.fetchrow_hash( ) ) != null )\n" +
                "    {\n" +
                "      this.set_db_data( row, false );\n" +
                "      return true;\n" +
                "    }\n" +
                "    return false;\n" +
                "  }\n" +
                "  catch ( DBLib.DBError e )\n" +
                "  {\n" +
                "    throw new PObject.Error.DBERROR( \"Error while reloading object from the database! %s\", e.message );\n" +
                "  }\n" +
                "}\n";
      }

      /* Add relations */
      foreach ( unowned PObjectRelation relation in this.relations.get_values( ) )
      {
        code += relation.get_vala_code( );
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
      
      if ( /^\s*(public|private|protected)?\s+([A-Za-z0-9\?]+)\s+([a-zA-Z0-9_]+)\s+\{.*\}\s*$/.match( line, 0, out mi ) )
      {
        PObjectField field = new PObjectField( this, mi.fetch( 3 ), mi.fetch( 2 ), field_annotation );
        this.fields[ mi.fetch( 3 ) ] = field;
        if ( field.primary_key )
        {
          this.primary_key_field = field;
        }

        if ( field_annotation.values[ "has_one" ] != null )
        {
          string? field_name = field_annotation.values[ "relation_name" ];
          if ( field_name == null && field.field_name.has_suffix( "_id" ) )
          {
            field_name = field.field_name.substring( 0, field.field_name.length - 3 );
          }
          else if ( field_name == null )
          {
            field_name = field_annotation.values[ "has_one" ].down( );
          }
          PObjectRelation relation = new PObjectRelation( this, field_name, field_annotation.values[ "has_one" ], RelationType.HAS_ONE, field );
          this.relations[ field_name ] = relation;
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

    string? line;

    int64 line_nr = 0;

    bool class_found = false;
    bool in_class = false;
    string? current_class_name = null;
    PObjectAnnotation? current_annotation = null;
    PObjectClass? current_class = null;

    while ( ( line = fin.read_line( ) ) != null )
    {
      line_nr ++;

      MatchInfo mi;
      if ( /class\s+([a-zA-Z0-9_]+)\s+:\s+PObject.Object/.match( line, 0, out mi ) )
      {
        current_class_name = mi.fetch( 1 );
        DMLogger.log.debug( 0, false, "${1}: Found class ${2} at line ${3}.", path, current_class_name, line_nr.to_string( ) );

        class_found = true;
        current_class = null;
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

        if ( class_lines[ path ] == null )
        {
          class_lines[ path ] = new HashTable<int64?,string?>( int64_hash, int64_equal );
        }
        
        class_lines[ path ][ line_nr ] = current_class_name;

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
  }

  public void preprocess_file_second_pass( string file )
  {
    FileStream? fin = null;
    try
    {
      fin = OpenDMLib.IO.open( file, "rb" );
    }
    catch ( Error e )
    {
      DMLogger.log.error( 0, false, "Error while opening ${1} for reading! ${2}", file, e.message );
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

    fout.puts( PObject.PREPROCESSED_HEADER + "\n" );
    while ( ( line = fin.read_line( ) ) != null )
    {
      line_nr ++;
  
      fout.puts( line + "\n" );

      if ( class_lines[ file ] != null && class_lines[ file ][ line_nr ] != null )
      {
        PObjectClass? klass = classes[ class_lines[ file ][ line_nr ] ];
        if ( klass != null )
        {
          DMLogger.log.debug( 0, false, "Injecting class code of class ${1} after line ${2}", klass.class_name, line_nr.to_string( ) );

          fout.puts( "\n/* POBJECT_INJECTED */\n" + klass.get_template_code( ) + "\n/* POBJECT_INJECTED */\n\n" );
        }
      }
    }
    fout = null;
    fin = null;

    OpenDMLib.IO.move( out_file, file );
  }
}