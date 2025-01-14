-- Generates code for dumping core Zotero SQLite data next to
-- the 'main' db (the database must be attached as 'main').
-- After execution, generated code (the "sql" column) needs to
-- be executed. Data from each table is dumped as an INSERT VALUES
-- statement in files named "data_{table_name}.sql".
-- Note: generated code incorporates writefile() routine from the
-- fileIO extension.


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

    -- Generates prefix (path to opened Zotero.sqlite)
    db_path AS (
        SELECT
            replace(replace(replace(terms, '["', ''), '"]', ''), '","', '/') AS prefix
        FROM path_terms
    ),

    -- Template for dumping data.
    dump_template(template) AS (VALUES(concat_ws(x'0A',
        'SELECT',
        '    writefile(''{@output}'',',
        '        ''INSERT OR IGNORE INTO "{@tbl}"({@cols}) VALUES'' || x''0A'' ||',
        '        group_concat(',
		'            ''    ('' || concat_ws('', '',',
        '                {@vals}',
        '            ) || '')'',',
		'            '','' || x''0A'' ORDER BY ROWID',
		'        ) || '';'' || x''0A''',
        '    ) AS code',
        'FROM "{@tbl}";'
    ))),

    -- Core Zotero data tables
    core_tables(name) AS (VALUES
        ('itemTypes'), ('items'), ('creatorTypes'), ('creators'), ('itemCreators'),
        ('fields'), ('fieldsCombined'), ('baseFieldMappings'), ('itemDataValues'),
        ('itemData'), ('charsets'), ('itemAttachments'), ('itemNotes'), ('itemRelations'),
        ('tags'), ('itemTags'), ('itemTypeFields'), ('itemTypeCreatorTypes'), ('collections'),
        ('collectionItems')
    ),

    -- Retrieves the list of columns for each table in the list (table_info skips generated
    -- columns, whereas table_xinfo does not)
    columns AS (
        SELECT core_tables.name AS tbl_name, cid, cols.name AS col_name
        FROM core_tables, pragma_table_info(core_tables.name) AS cols
    ),

    -- Prepares snippets to be replaced into the dump template (the list of columns and
    -- the list of appropriately quoted values to be used as part of an INSERT statement).
    metadata AS (
        SELECT
            tbl_name,
            group_concat('"' || col_name || '"', ', ' ORDER BY cid) AS cols,
            group_concat('quote("' || col_name || '")', ', '  ORDER BY cid) AS vals
        FROM columns
        GROUP BY tbl_name
    ),

    -- Formats final code generating dump snippets.
    queries AS (
        SELECT
            tbl_name,
            replace(replace(replace(replace(template,
                '{@tbl}', tbl_name),
                '{@cols}', cols),
                '{@vals}', vals),
                '{@output}', prefix || '/data_' || tbl_name || '.sql'
            ) AS code
        FROM metadata, dump_template, db_path
    )
SELECT tbl_name, code FROM queries;
