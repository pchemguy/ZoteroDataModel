-- "main" database - newer zotero.sqlite
-- "prev" database - backup copy of zotero.sqlite

WITH RECURSIVE
    -- COLLECTIONS from the "main" [zotero.sqlite] database (newer)
    main_cols_unsorted AS (
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_array(col.collectionName) AS pathName,
                json_array(col."key") AS pathKey
            FROM main.collections AS col
            WHERE parentColID IS NULL
        UNION ALL
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_insert(main_cols_unsorted.pathName, '$[#]', col.collectionName
                           ) AS pathName,
                json_insert(main_cols_unsorted.pathKey, '$[#]', col."key") AS pathKey
            FROM main_cols_unsorted, main.collections AS col
            WHERE main_cols_unsorted.colID = col.parentCollectionID
    ),
    main_cols_unpacked AS (
        SELECT *
        FROM  main_cols_unsorted 
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    main_cols_packed AS (
        SELECT
            colID,
            colKey,
            pathName,
            json_object('colID', colID, 'colName', colName,
                        'colKey', colKey, 'pathName', json(pathName),
                        'pathKey', json(pathKey)) AS collection
        FROM  main_cols_unpacked
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    -- COLLECTIONS from the "prev" [zotero.sqlite] database (attached backup copy)
    prev_cols_unsorted AS (
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_array(col.collectionName) AS pathName,
                json_array(col."key") AS pathKey
            FROM prev.collections AS col
            WHERE parentColID IS NULL
        UNION ALL
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_insert(prev_cols_unsorted.pathName, '$[#]', col.collectionName
                           ) AS pathName,
                json_insert(prev_cols_unsorted.pathKey, '$[#]', col."key") AS pathKey
            FROM prev_cols_unsorted , prev.collections AS col
            WHERE prev_cols_unsorted.colID = col.parentCollectionID
    ),
    prev_cols_unpacked AS (
        SELECT *
        FROM  prev_cols_unsorted 
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    prev_cols_packed AS (
        SELECT
            colID,
            colKey,
            pathName,
            json_object('colID', colID, 'colName', colName,
                        'colKey', colKey, 'pathName', json(pathName),
                        'pathKey', json(pathKey)) AS collection
        FROM  prev_cols_unpacked
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    -- COLLECTIONS from the "prev" database not present in the "main" database
    -- (colKey-based comparison)
    missing_cols AS (
        SELECT
            prevdb.colID, prevdb.pathName, prevdb.collection
        FROM prev_cols_packed AS prevdb
        LEFT JOIN main_cols_packed AS maindb
        ON prevdb.colKey = maindb.colKey
        WHERE maindb.colKey IS NULL
        ORDER BY substr(prevdb.pathName, 1, length(prevdb.pathName) - 1)
    ),
    missing_values AS (
        SELECT collections.*
        FROM missing_cols, prev.collections
        WHERE missing_cols.colID = prev.collections.collectionID
          AND missing_cols.pathName like '["Projects"%'
        ORDER BY prev.collections.collectionID
    ),
    deleted_cols AS (
        SELECT prevdb.colID, prevdb.pathName
        FROM prev_cols_packed AS prevdb, prev.collections
        WHERE prevdb.colID = prev.collections.collectionID
          AND prevdb.pathName like '["Projects"%'
        ORDER BY substr(prevdb.pathName, 1, length(prevdb.pathName) - 1)
    ),
    deleted_collectionItems AS (
        SELECT collectionItems.*
        FROM deleted_cols, prev.collectionItems
        WHERE deleted_cols.colID = prev.collectionItems.collectionID
    ),
    check_deleted_items AS (
        SELECT deleted_collectionItems.*, main.items.itemID AS itemIDdel
        FROM deleted_collectionItems
        LEFT JOIN main.items
        ON deleted_collectionItems.itemID = main.items.itemID
        ORDER BY main.items.itemID
    ),
    deleted_items AS (
        SELECT prev.itemData.itemID, prev.itemDataValues.value
        FROM prev.itemDataValues, prev.itemData, check_deleted_items
        WHERE check_deleted_items.itemIDdel IS NULL
          AND check_deleted_items.itemID = prev.itemData.itemID
          AND prev.itemData.fieldID = 1
          AND prev.itemData.valueID = prev.itemDataValues.valueID
    )
-- Insert missing collections
-- INSERT INTO main.collections
-- SELECT * FROM missing_values;

-- Insert item associations
-- INSERT INTO main.collectionItems
-- SELECT collectionID, itemID, orderIndex
-- FROM check_deleted_items 
-- WHERE check_deleted_items.itemIDdel IS NOT NULL;

SELECT * FROM missing_cols;
