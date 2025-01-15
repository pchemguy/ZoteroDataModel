# Combining JSON, Virtual Generated Columns, and Partial Indexes

A potentially interesting hybrid approach incorporates several features:
- Core fields common to most references are stored in dedicated columns or tables (reference type, title, authors, date, item id type, item id).
- Other fields are stored in a `TEXT` column as JSON documents.
- Virtual generated columns are added as necessary for each commonly accessed field and contain values extracted from the JSON column (it is possible to add such columns for all fields).
- Partial indexes are created on each generated column, where the column value is not `NULL`.

This design provides several advantages: 
- Virtual generated columns
    - do not consume storage space;
    - can be added conveniently via the `ALTER TABLE` statement without affecting the rest of the schema;
    - can be used to define constrains, enforcing consistency and data format;
    - are only evaluated when accessed, limiting performance penalty in case when multiple generated columns are used;
    - new generated columns do not affect previous queries that retrieve desired columns explicitly, rather than using wildcards.
- A set of generated columns in combination with the core fields act as a partially denormalized flat table, enabling the use of basic SQL queries.
- Partial indexes on generated columns' non-null values only enabling robust filtering on generated columns without accessing the columns directly and causing associated recalculations. While indexes can be created on expressions directly, such approach is inherently fragile.
-  
  

<!-- References -->

[ZoteroDataModel]: https://github.com/pchemguy/ZoteroDataModel/blob/main/MainDB/Zotero_MainDB.md
