# pobject

## General information
The pobject is a library which can be used to store objects persistantly in a database.
It relies on some other libraries (dmtestlib, open_dmlib, dm_logger, dblib).

## Usage
To use the library all you have to do is inherit a class from `PObject.Object` and preprocess your source files using the pobject preprocessor:
```bash
pobject preprocess <your_source_dir>
```

Inherit a class from `PObject.Object` to tell the preprocessor that this class supports persistant storage:
```vala
public class Cars : PObject.Object
{
}
```

### Code-Annotations
Settings for the classes and fields are done via code annotations:
```vala
[PObject (table_name="tbl_cars")]
public class Cars : PObject.Object
{
  [PObject (field_name="car_id", primary_key=true)]
  public int64 id;

  [PObject (field_name="car_model")]
  public string model;
}
```

Only classes which are inherited from `PObject.Object` and annotated will support persistant storage.
Only fields which are annotated will be used as fields in the database.

#### Class-Code-Annotations
There are following code annotations which can be made for classes:
* table_name - The name of the table in the database (required)
* field_prefix - A prefix which should be used for every field in the table (optional)

#### Field-Code-Annotations
There are following code annotations which can be made for fields in classes:
* field_name - The name of the field in the table (required)
* primary_key - A flag which specifies if this field is the primary key (true/false, optional)


### Generated code
When your source files are preprocessed by the pobject tool they will get following methods:
* object.save
* Class.all
* Class.select
* object.delete

## Copyright
This library is written by DocuMatrix and is published under the LGPLv3 license.
(c) 2014 by DocuMatrix (www.documatrix.com)
