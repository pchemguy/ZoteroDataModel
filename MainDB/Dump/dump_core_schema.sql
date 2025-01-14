-- Dumps core Zotero SQLite schema as 'schema-core.sql' next to
-- the 'main' db (the database must be attached as 'main').

WITH
    -- Queries the list of databases, selects the path of the main
    -- database, splits the path via JSON, and extracts prefix.
    path_terms AS (
        SELECT
            json_remove(
                json('["' || replace(replace(file, x'5C', '/'), '/', '", "') || '"]'),
                '$[#-1]'
            ) AS terms
        FROM pragma_database_list()
        WHERE name = 'main'
    ),    
    db_path AS (
        SELECT
            replace(replace(replace(terms, '["', ''), '"]', ''), '","', '/') AS prefix
        FROM path_terms
    ),
    core_tables(name) AS (VALUES
        ('itemTypes'), ('items'), ('creatorTypes'), ('creators'), ('itemCreators'),
        ('fields'), ('fieldsCombined'), ('baseFieldMappings'), ('itemDataValues'),
        ('itemData'), ('charsets'), ('itemAttachments'), ('itemNotes'),
		('itemRelations'), ('tags'), ('itemTags'), ('itemTypeFields'),
		('itemTypeCreatorTypes'), ('collections'), ('collectionItems')
    ),
    schema AS (
        SELECT sql || ';' AS sql
        FROM sqlite_master, core_tables
        WHERE type = 'table' AND sqlite_master.name = core_tables.name
        ORDER BY sqlite_master.name
    )
SELECT writefile(
    prefix || '/schema-core.sql',
    x'2D2D' || ' AUTO GENERATED' || x'0A0A' || group_concat(
        replace(replace(substr(sql, 1, length(sql) - 1), x'0A', ''), '    ', x'0A' || '    '),
        x'0A' || ');' || x'0A0A'
    ) || x'0A' || ');' || x'0A'
) AS written_char_count
FROM schema, db_path;
