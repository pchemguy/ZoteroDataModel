# Exploring Zotero Data Model for Direct Database Access

This tutorial aims to provide technical information necessary for direct access to data stored in Zotero's local bibliographic database. The official documentation [mentions][Zotero Client Data Model] the present topic briefly, so I decided to post a more detailed discussion.

Zotero's local bibliographic database is an [SQLite][] database, the leading open-source relational database management system (RDBMS). Hence, direct access to this data necessitates basic familiarity with [relational databases][RDBMS] and [SQL][] (free SQL resources are readily available on the Internet, including the [official documentation][SQLite docs] focused on the SQLite SQL dialect and [this tutorial][SQLite SQL Tutorial]).

<!-- [TOC] -->

## General Remarks and Motivation

[Zotero][] is an information manager designed for managing bibliographic information, which

- is open-source software,
- has a competitive feature set,
- has a long history of active development,
- employs the leading open-source data storage format.

The characteristics above are essential for an information manager that helps get the job done while not getting in the way, can be relied on in the long run, and doesn't lock the data.

Selected Zotero's item organization and retrieval feature highlights:

&nbsp;&nbsp;&nbsp;&nbsp;&#128077;  
   
- item organizations using tags and hierarchical collections (categories)
- full-text search, including search on tag names
- tag-based filters and complex metadata search queries via GUI
- items may belong to multiple collections

&nbsp;&nbsp;&nbsp;&nbsp;&#128078; missing collection features  

- full-text search on collection names
- selecting/dragging/dropping multiple collections
- directory-like name uniqueness enforcement

Even though Zotero provides a wide variety of export data options, none of them, except, perhaps, for the native XML, preserves all metadata. Each export format has certain limitations, and the more truthful and complete formats will likely require more elaborate post-processing to suit particular needs. For this reason, it is a good idea to understand how Zotero models and stores the data and how to access/retrieve it directly, bypassing the Zotero software completely.

## Database Administration Software

As an information manager, Zotero facilitates interaction between the user and the data storage backend. In this capacity, Zotero performs three core data functions - ***presentation*** (the GUI), ***modeling*** (transformation of data for optimal handling by the database), and ***transfer*** (storage/retrieval to/from the data storage backend). Bypassing Zotero software means using general-purpose database-specific tools (*database administration software*) for direct data retrieval from the database (and, possibly, its modification).

Because Zotero relies on the ubiquitous [SQLite][] RDBMS for its data storage, well-developed database administration tools are readily available. Some examples of free and open-source software include, for example:  

- [DB Browser for SQLite](https://sqlitebrowser.org)
- [SQLiteStudio](https://sqlitestudio.pl)
- [HeidiSQL](https://heidisql.com)

These tools still perform the data *transfer* function (mentioned above) but not *modeling*. Because the latter is absent, data *presentation* (which relies on appropriate modeling) is limited, only reflecting the storage format of raw data chunks supported by the database. While having full access to all data and metadata, the user becomes responsible for any necessary data interpretation, such as structure reconstruction.  
 
**Side notes**  

 - While all these tools provide comparable functionality, the convenience of individual features varies between programs, so it might be a good idea to learn a few of them.
 - Remembering one of the essential differences between SQLite and typical client/server databases (such as MySQL or PostgreSQL) may save a lot of trouble when using an SQLite manager and running SQL queries. Because a single small library file incorporates the entire SQLite engine, programs usually use their private (rather than the system) copy, which resides next to the GUI starting executable (a common practice on Windows). These private copies have different version numbers and slightly different feature sets (because of varying build options and continual development of new features). While these differences may have no immediate manifestation, if in doubt, always run basic SQLite [introspection queries][SQLiteIntro] (for each client used!), checking the actual library version and available features. 
 - Sample SQL queries below require SQLite 3.46.0. For all mentioned clients, replace the "sqlite3.dll" file (on Windows) with the [official current release][SQLiteDistro] or a [custom build][SQLiteICU].
 - The sample SQL queries below extensively use [Common table expressions (CTE)][CTE]. Without CTEs, developing and understanding any practical query rapidly turns into intractable nightmares with size. Various tutorials on CTEs are available on the Internet, including one of my [own][SQLite SQL Tutorial].

## Modeling Semi-structured Data for Storing in RDBMS

Any data/information stored in a database only realizes its value when accessed, retrieved, and used. Hence, information management is about capturing/preserving/organizing (both individual values and the associated structure) information and ensuring that relevant information can be efficiently retrieved and used. An RDBMS is often a backend of choice, even when handling information outside the original scope of well-structured tabular data. The ubiquity and maturity of established RDBMSs usually outweigh the limitations associated with managing semi-structured information. Meanwhile, appropriate [data modeling][] provides guidelines for chopping and shaping the original data for optimal storage and handling.

Typical mapping for structured datasets (composed of items sharing the same fixed set of data fields) involves storing individual dataset items (aka records) as table rows, with each field mapping to a dedicated table column. Establishing a similar mapping for semi-structured information, such as bibliographic records, is not as straightforward. Each bibliographic record/item describes a particular bibliographic source. Different source types (e.g., *journal article,*  *patent,* *report,* etc.) may have shared (e.g., *title,* *authors/creators,* and *URL*) and source-specific (e.g., *patent number* and *report type*) fields. Further, some fields may possess a structure of their own. Notably, each bibliographic record may have one or multiple authors/creators, with different citation styles having varying rules regarding the use and formatting of this information.

One of the common approaches to storing semi-structured information in relational databases and implemented by Zotero is the ["entity-attribute-value"][EAV] (EAV) model. Instead of having the *"table row per item"* and *"table column per field value"* arrangement, an EAV data table follows a non-relational (or, rather, [denormalized][DB Norm]) *"table row per field value"* design, with all fields of an item "stacked" in the same table column of separate records ("vertical" design). An EAV table contains three columns:

- entity/item (e.g., a particular bibliographic record) identifier
- attribute/field (e.g., *"title"* or *"URL"*) identifier
- value (e.g., "Zotero" or "https://zotero.org")

Because the EAV tables only store non-empty field values, this design may save considerable space for "sparse" data.

## Zotero's Data Model

The [ERD diagram][] below shows the "core" tables of the bibliographic Zotero database. Two-thirds of all database tables correspond to "secondary" features, apparently non-implemented features, or are otherwise irrelevant in the present context and not included in the diagram.  

---
<a id="ERD_Diagram"></a>
**ERD diagram showing "core" Zotero tables**
![][Zotero_MainDB-ERD_Concepts_8.svg]

N.B. This diagram was produced  by reverse engineering a Zotero database using [ERD Concepts][], removing less relevant tables, and manually rearranging the remaining tables for best fit.

---

Each bibliographic record stored in a Zotero database has a corresponding row in the "central" ***items*** table shown (and highlighted) in the center of the [ERD diagram][]. The ***items*** table is a conventional table, providing item identifiers used by other tables (the *itemID* and *key* fields). The table also includes several general fields, particularly the associated *itemTypeID* referring to the record's *Item Type* (the first field in Zotero's "info" page shown for all records).

### Item and Creator Type

The three tables in the bottom-left quadrant of the [ERD Diagram][] contain item type information. Two of them, ***itemTypes*** and ***fields***, define programmatic codes for all record types (*"typeName"*) and fields (*"fieldName"*). Each item type from the former table is a subset of fields from the latter. Hence, the many-to-many table ***itemTypeFields*** provides actual type definitions. This table also contains the *"orderIndex"* field, which indicates the order (top to bottom) in which Zotero's "info" pane shows the fields. The fourth table, ***baseFieldMappings***, instructs Zotero which fields from different item types are considered equivalent for display and search purposes. Each of the four tables also contains a "companion" table with an additional suffix *"Combined"* in their names. These tables essentially contain the same information. There is also a second set of "companion" tables, having the prefix *"custom"* in their names but no data or references from the source code.

The associated textual localized labels for both type and field names presented to the user in Zotero GUI are located in the "chrome/locale" subfolders of the source tree (and the same path inside the "zotero.jar" file found in the program directory). Item types do not have other references in Zotero's source code. Therefore, it might be [possible][Zotero Client Data Model] to define/add new types to Zotero by adding appropriate rows to the three type tables and the labeling information to locale files in the "chrome/locale" subfolders.

#### Items with type names - Query

The following query returns the list of item identifiers and the associated type names (the query is intentionally wrapped in a CTE clause so that it could be directly copy-pasted and used in more complex queries):

```sql
WITH
    itemsEx AS (
        SELECT
            items.itemID, items.itemTypeID,
            itemTypes.typeName, items."key" AS itemKey
        FROM items, itemTypes
        WHERE items.itemTypeID = itemTypes.itemTypeID
    )
SELECT * FROM itemsEx;
```

#### Item type - core fields - Query

The following query returns the list of types and the associated field lists formatted as JSON arrays:

```sql
SELECT
    itemTypeFields.itemTypeID, itemTypes.typeName,
    json_group_array(fieldName ORDER BY orderIndex) AS fieldNames
FROM itemTypeFields, fields, itemTypes
WHERE itemTypeFields.fieldID = fields.fieldID
  AND itemTypeFields.itemTypeID = itemTypes.itemTypeID
GROUP BY itemTypeFields.itemTypeID
ORDER BY itemTypeFields.itemTypeID;
```

The tables and queries above do not include author/creator fields. Each item type may contain certain creator types (per many-to-many table ***itemTypeCreatorTypes***) from the list defined in the ***creatorTypes*** table (top-left quadrant of the [ERD diagram][]).

#### Item type creators - Query

The following query returns a list of item types and associated permissible creator types as JSON arrays:

```sql
SELECT
    itemTypes.typeName,
    json_group_array(creatorType
        ORDER BY primaryField DESC,itemTypeCreatorTypes.creatorTypeID
    ) AS creatorTypeNames
FROM itemTypes, creatorTypes, itemTypeCreatorTypes
WHERE itemTypeCreatorTypes.creatorTypeID = creatorTypes.creatorTypeID
  AND itemTypeCreatorTypes.itemTypeID = itemTypes.itemTypeID
GROUP BY itemTypes.typeName
ORDER BY itemTypes.itemTypeID;
```

#### Item type fields - Query

A combination of the two queries yields a consolidated list of types with corresponding fields and creator names:

```sql
WITH
    fieldNames AS (
        SELECT
            itemTypeFields.itemTypeID, itemTypes.typeName,
            json_group_array(fieldName ORDER BY orderIndex) AS fieldNamesJSON
        FROM itemTypeFields, fields, itemTypes
        WHERE itemTypeFields.fieldID = fields.fieldID
          AND itemTypeFields.itemTypeID = itemTypes.itemTypeID
        GROUP BY itemTypeFields.itemTypeID
    ),
    creatorTypeNames AS (
        SELECT
            itemTypes.typeName,
            json_group_array(creatorType
                ORDER BY primaryField DESC,itemTypeCreatorTypes.creatorTypeID
            ) AS creatorTypeNamesJSON
        FROM itemTypes, creatorTypes, itemTypeCreatorTypes
        WHERE itemTypeCreatorTypes.creatorTypeID = creatorTypes.creatorTypeID
          AND itemTypeCreatorTypes.itemTypeID = itemTypes.itemTypeID
        GROUP BY itemTypes.typeName
    )
SELECT fieldNames.*, creatorTypeNamesJSON
FROM fieldNames, creatorTypeNames
WHERE fieldNames.typeName = creatorTypeNames.typeName
ORDER BY itemTypeID
```

### EAV Item Data

#### EAV core data - Query

The right half of the [ERD Diagram][]'s top row shows two EAV tables, ***itemData*** and ***itemDataValues***. It is unclear why developers split the EAV table into two. Naturally, the third column of the ***itemData*** table would be *itemDataValues.value*, not *valueID*. The following query reconstructs items and returns them as JSON objects:  

```sql
WITH
    eav AS (
        SELECT itemData.itemID, itemData.fieldID, itemDataValues.value
        FROM itemData, itemDataValues
        WHERE itemData.valueID = itemDataValues.valueID
    ),
    eav_ex AS (
        SELECT items.itemTypeID, eav.itemID, eav.fieldID, orderIndex, eav.value
        FROM eav, items, itemTypeFields
        WHERE (items.itemID, items.itemTypeID, eav.fieldID) =
              (eav.itemID, itemTypeFields.itemTypeID, itemTypeFields.fieldID)
    ),
    item_data AS (
        SELECT
            itemTypeID, itemID,
            json_group_object(fields.fieldName, value) AS data
        FROM eav_ex, fields
        WHERE eav_ex.fieldID = fields.fieldID AND itemTypeID NOT IN (2, 26)
        GROUP BY itemID
        ORDER BY itemID
    )    
SELECT * FROM item_data;
```

Most relational databases require that each table column defines a specific type for all stored values. This requirement necessitates that the EAV value column stores any numeric value as text, and the attribute should include information used for original data reconstruction. SQLite, however, does not have this requirement and permits, by default, the storage of all data types in a single column.

Again, a dedicated table ***creators*** holds eponymous data, and the many-to-many table ***itemCreators*** defines creator names for each item (top-left quadrant in the [ERD diagram][]) and their order (the *orderIndex* field). The table ***itemCreators*** contains the *creatorTypeID* field, which describes creators, not the item/creator relation, and should be in the ***creators*** table. The present design is more consistent with the ***creatorNames*** table name.

#### Item creators - Query

The following query returns creators for each item as JSON objects:

```sql
SELECT
    items.itemID,
    items."key",
    json_object('creators',
        json_group_array(
            CASE creators.fieldMode
                WHEN 0 THEN
                    json_object('creatorType', creatorTypes.creatorType,
                                'firstName', creators.firstName,
                                'lastName', creators.lastName)
                ELSE
                    json_object('creatorType', creatorTypes.creatorType,
                                'fullName', creators.lastName)
            END
            ORDER BY orderIndex
        )
    ) AS creators
FROM creators, creatorTypes, items, itemCreators
WHERE (itemCreators.creatorTypeID, itemCreators.creatorID, itemCreators.itemID) = 
      (creatorTypes.creatorTypeID, creators.creatorID, items.itemID)
GROUP BY itemCreators.itemID
ORDER BY itemCreators.itemID;
```

### Attachments

The ***itemTypes*** table includes two specialized types: *attachment* and *note* (which employ somewhat  clunky, inconsistent, and questionable design decisions).

Each *attachment* object (I intentionally avoid calling it an *item*) has an associated record in the main *items* table, and the EAV tables discussed above may include three fields defined for this item type. At the same time, a dedicated table (***itemAttachments***, located below the ***items*** table in the [ERD diagram][]) stores additional attachment metadata. The motivation for splitting attachment object fields between the EAV tables and the dedicated attachments table is unclear; IMHO, placing all fields in the attachments table would make more sense.

The *parentItemID* field is consistent with the idea that attachments are to be attached to regular (anything but *attachment* or *note*) items. Even though Zotero does not provide an option to create new "standalone" attachment items, a file may be dragged onto the main Zotero window, causing Zotero to make one (setting *parentItemID* to NULL). An existing attachment may also be dragged and dropped onto a different item, changing the parent item, or dropped onto the whitespace area in the central pane, which converts the status of an attachment object from attached  to standalone. Attachments are not meant for use as standalone items, and such use is discouraged.

The other noteworthy field is *linkMode*, which defines the attachment subtype. The meaning of this field is not included in the database as a hypothetical ***linkModeTypes*** table but is defined in the "chrome/content/zotero/xpcom/attachments.js" source file as having five possible values:

- LINK_MODE_IMPORTED_FILE = 0;
- LINK_MODE_IMPORTED_URL = 1;
- LINK_MODE_LINKED_FILE = 2;
- LINK_MODE_LINKED_URL = 3;
- LINK_MODE_EMBEDDED_IMAGE = 4;

Contrary to what value names might suggest, files are never stored inside the database. The two linked types merely store information about their target location. The other three make a copy of the target file in the local storage directory and link to that copy. The last embedded image subtype does not have any associated values in the EAV tables.

The *path* field encodes the file system path of the attached file. Its value and interpretation depend on the attachment subtype:

- *LINK_MODE_LINKED_URL*  
  The *path* field is NULL because the attachment is merely an Internet address
- *LINK_MODE_LINKED_FILE*  
  If a file is stored within the "Linked Attachment Base Directory" (as defined in "Preferences-\>Advanced-\>Files and Folders"), the field contains  the prefix "attachments:" followed by the file's relative path. Otherwise, Zotero probably stores absolute paths, but this option should generally be avoided.
- *LINK_MODE_IMPORTED_FILE*, *LINK_MODE_IMPORTED_URL*, *LINK_MODE_EMBEDDED_IMAGE*  
  The file is copied to a directory named after the *key* field from the ***items*** table record of the attachment item. This directory is, in turn, created inside the "storage" directory located inside the "Data Directory" (as defined in "Preferences-\>Advanced-\>Files and Folders"). The path includes the prefix "storage:" followed by the file name.
  
#### Consolidated attachment data - Query

The following query returns consolidated attachment information as JSON objects for all items. The parent reference of standalone attachments is set to point to the item itself.

```sql
WITH
    -- Based on the definition in "chrome\content\zotero\xpcom\attachments.js"
    --    LINK_MODE_IMPORTED_FILE = 0;
    --    LINK_MODE_IMPORTED_URL = 1;
    --    LINK_MODE_LINKED_FILE = 2;
    --    LINK_MODE_LINKED_URL = 3;
    --    LINK_MODE_EMBEDDED_IMAGE = 4;
    linkModeTypes(linkModeID, linkModeName) AS (
        VALUES
            (0, 'importedFile'),
            (1, 'importedURL'),
            (2, 'linkedFile'),
            (3, 'linkedURL'),
            (4, 'embeddedImage')
    ),
    attachmentsEAV AS (
        SELECT itemData.itemID, json_group_object(fieldName, value) AS fieldData
        FROM itemData, itemDataValues, fields, items
        WHERE (itemData.itemID, itemData.fieldID, itemData.valueID) =
              (items.itemID, fields.fieldID, itemDataValues.valueID)
          AND items.itemTypeID = 2
        GROUP BY itemData.itemID
    ),
    attachmentsMain AS (
        SELECT
            itemAttachments.itemID,
            items."key" AS itemKey,
            -- Take care of standalone attachment items (parentItemID IS NULL)
            coalesce(parentItemID, itemAttachments.itemID) AS parentItemIDex,
            parentItems."key" AS parentItemKey,
            linkMode,
            linkModeName,
            iif(contentType IS NOT NULL,
                '"contentType": "' || contentType || '",', '') AS contentType,
            iif(path IS NOT NULL, '"path": "' || path || '",', '') AS path,
            CASE linkMode
                WHEN 2 THEN
                    '"pathSpec": "' ||
                    replace(path, 'attachments:', 'attachments:{BaseDir}/') || '",'
                WHEN 3 THEN
                    ''
                ELSE
                    '"pathSpec": "' ||
                    replace(path, 'storage:', 'storage:{DataDir}/storage/' ||
                    items."key" || '/') || '",'
            END AS pathSpec
        FROM itemAttachments, linkModeTypes, items, items AS parentItems
        WHERE itemAttachments.itemID = items.itemID
          AND parentItemIDex = parentItems.itemID
          AND linkMode = linkModeID
    ),
    attachmentsPre AS (
        SELECT
            attachmentsMain.itemID, itemKey, parentItemIDex AS parentItemID,
            parentItemKey, linkMode, linkModeName, contentType, path, pathSpec,
            json_object('$.itemID', attachmentsMain.itemID,
                        '$.itemKey', itemKey,
                        '$.linkMode', linkMode,
                        '$.linkModeName', linkModeName
            ) AS dataA,
            json('{' || contentType || path || pathSpec || '}') AS dataB,
            coalesce(fieldData, '') AS fieldData
        FROM attachmentsMain LEFT JOIN attachmentsEAV
        ON attachmentsMain.itemID = attachmentsEAV.itemID
    ),
    attachmentsCombined AS (
        SELECT
            itemID, itemKey, parentItemID, parentItemKey,
            replace(replace(
                dataA || dataB || fieldData, '{}', ''),'}{', ',') AS data
        FROM attachmentsPre
        ORDER BY itemID
    ),
    itemattAchmentsCombined AS (
        SELECT
            parentItemID, parentItemKey,
            json_object('Attachments',
                json_group_array(
                    json(data) ORDER BY data ->> '$.title' COLLATE NOCASE
                )
            ) AS Attachments
        FROM attachmentsCombined 
        GROUP BY parentItemID
        ORDER BY parentItemID
    )
SELECT * FROM itemattAchmentsCombined;
```

### Notes
 
Similar to attachments, notes may be attached or standalone. At the same time, Zotero provides direct support for standalone note creation and does not store any note information in the EAV tables. Instead, all note data is stored as HTML-formatted text in the dedicated ***itemNotes*** table, shown to the left from the ***items*** table in the [ERD diagram][]. There is no dedicated note *title* field; instead, the *title* column is populated automatically by Zotero, which extracts the first line (or part of it) from the note text.

Zotero (or the Zotfile extension?) automatically extracts TOC from the attached PDF files, adding associated notes but not creating associated records in the ***items*** table and not filling the *parentItemID* field. Therefore, associating these automatic notes with appropriate items is not straightforward.

#### Automatic TOC notes - Query

The following query returns all these TOC notes:

```sql
SELECT * FROM itemNotes
WHERE note LIKE '<div class="zotero-note znv1">' || 
    '<p xmlns="http://www.w3.org/1999/xhtml" id="title"><strong>Contents</strong></p>' || 
    '<ul xmlns="http://www.w3.org/1999/xhtml" ' ||
    'style="list-style-type: none; padding-left:0px" id="toc">%'
```

#### Manual notes - Query

The following query returns data for manually created notes:

```sql
WITH
    entities AS (
        SELECT itemID, "key" AS itemKey
        FROM items
        WHERE itemTypeID = 26
        ORDER BY itemID
    ),
    notes AS (
        SELECT itemNotes.*, itemKey
        FROM itemNotes
        LEFT JOIN entities
        ON itemNotes.itemID = entities.itemID
        WHERE itemKey IS NOT NULL
    )
SELECT * FROM notes;
```

### Collections

Collections are directory-like (to a certain extent) hierarchical containers designed for reference organization. Collection information is contained in the ***collections*** and ***collectionItems*** tables, appearing in the bottom-right corner of the [ERD diagram][]. Zotero's collections obey the following rules:

- Each collection has exactly one parent, except for the top-level collections, which do not have parents.
- Each item may be a member of zero or more collections.
- Items belonging to the same collection may have identical titles.
- Sibling collections may have identical names.

The ***collectionItems*** table is a conventional many-to-many table (additionally marking the order of items assigned to the same collection).

The ***collections*** table needs to store both collection names and hierarchy information. There are several approaches to handling trees/hierarchies in relational databases. Zotero implements the *adjacency list* model: each record contains a reference to its parent (*parentCollectionID*). Another helpful representation is *materialized paths* (aka *path enumeration*).

#### Collections - materialized paths - Query

Converts collections (*adjacency list*) to *materialized paths*. Collection names and keys form two synonymous paths  as JSON arrays of path elements, starting from the root element as the first array member.

```sql
WITH RECURSIVE
    cols_unsorted AS (
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
                json_insert(cols_unsorted.pathName, '$[#]', col.collectionName
                           ) AS pathName,
                json_insert(cols_unsorted.pathKey, '$[#]', col."key") AS pathKey
            FROM cols_unsorted, main.collections AS col
            WHERE cols_unsorted.colID = col.parentCollectionID
    ),
    cols_unpacked AS (
        SELECT *
        FROM  cols_unsorted
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    cols_packed AS (
        SELECT
            colID,
            pathName,
            json_object('colID', colID, 'colName', colName,
                        'colKey', colKey, 'pathName', json(pathName),
                        'pathKey', json(pathKey)) AS collection
        FROM  cols_unpacked
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    )
SELECT * FROM cols_packed;
```

#### Collections - Query

The following query returns the list of all <i><u>"filed"</u></i> items and associated collections as JSON objects.

```sql
WITH RECURSIVE
    cols_unsorted AS (
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_array(col.collectionName) AS pathName,
                json_array(col."key") AS pathKey
            FROM collections AS col
            WHERE parentColID IS NULL
        UNION ALL
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_insert(cols_unsorted.pathName, '$[#]', col.collectionName
                           ) AS pathName,
                json_insert(cols_unsorted.pathKey, '$[#]', col."key") AS pathKey
            FROM cols_unsorted, collections AS col
            WHERE cols_unsorted.colID = col.parentCollectionID
    ),
    cols_unpacked AS (
        SELECT *
        FROM  cols_unsorted
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    cols_packed AS (
        SELECT
            colID,
            pathName,
            json_object('colID', colID, 'colName', colName,
                        'colKey', colKey, 'pathName', json(pathName),
                        'pathKey', json(pathKey)) AS collection
        FROM  cols_unpacked
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    itemCollections AS (
        SELECT
            itemID, 
            json_object('collections',
                        json_group_array(
                            json(collection)
                            ORDER BY substr(pathName, 1, length(pathName) - 1)
                        )
            ) AS collections
        FROM collectionItems, cols_packed AS cols
        WHERE collectionItems.collectionID = cols.colID
        GROUP BY itemID
        ORDER BY itemID
    )
SELECT * FROM itemCollections;
```

#### Duplicated Path Collections - Query

```sql
WITH RECURSIVE
    cols_unsorted AS (
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_array(col.collectionName) AS pathName,
                json_array(col."key") AS pathKey
            FROM collections AS col
            WHERE parentColID IS NULL
        UNION ALL
            SELECT
                col.collectionID AS colID,
                col.collectionName AS colName,
                col.parentCollectionID AS parentColID,
                col."key" AS colKey,
                json_insert(cols_unsorted.pathName, '$[#]', col.collectionName
                           ) AS pathName,
                json_insert(cols_unsorted.pathKey, '$[#]', col."key") AS pathKey
            FROM cols_unsorted, collections AS col
            WHERE cols_unsorted.colID = col.parentCollectionID
    ),
    cols_unpacked AS (
        SELECT *
        FROM  cols_unsorted
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    ),
    cols_packed AS (
        SELECT
            colID,
            pathName,
            json_object('colID', colID, 'colName', colName,
                        'colKey', colKey, 'pathName', json(pathName),
                        'pathKey', json(pathKey)) AS collection
        FROM  cols_unpacked
        ORDER BY substr(pathName, 1, length(pathName) - 1)
    )
SELECT * FROM cols_packed
GROUP BY pathName
HAVING count(*) > 1;
```

#### Retrieve Missing  Collections - Query

Assuming a newer version of the main Zotero database is attached as "main", and a previous version is attached as "prev", obtain the list of collections present only in the older database (match collection keys).

```sql
```

### Tags

Tags help organize items. Zotero implements a standard tag model (any regular item may be assigned any tags). Hence, the ***tags*** and many-to-many ***itemTags*** tables (shown to the right from the ***items*** table in the [ERD diagram][]) store the tags and assignment information, respectively. 

#### Tags - Query

The following query lists items and all associated tags as JSON objects:

```sql
SELECT itemTags.itemID,
       json_object('tags',
           json_group_array(
               json_object('id', itemTags.tagID, 'name', name, 'auto', type)
               ORDER BY tags.name COLLATE NOCASE
           )
       ) AS tags
FROM itemTags, tags
WHERE itemTags.tagID = tags.tagID
GROUP BY itemTags.itemID
ORDER BY itemTags.itemID;
```

### Relations

In addition to conventional tags and hierarchical collections, Zotero provides a third tool for organizing items - relations, which defines related collections. The associated information is stored in the many-to-many ***itemRelations*** table (shown next to the bottom-right corner of the ***items*** table in the [ERD diagram][]). While there are particular scenarios for which this feature might be a natural fit, the same information can be encoded using tags or collections. Further, because no metadata can be associated with relations, it is, IMHO, barely usable.

### Better BibTex for Zotero

#### Better BibTex citation keys - Query

If Better BibTex for Zotero is installed, the following query attempts to attach its database and return citation keys.

```sql
DETACH better_bibtex;

ATTACH (
	SELECT substr(file, 1, length(file) - 13) || 'better-bibtex.sqlite' AS prefix
	FROM pragma_database_list()
	WHERE name = 'main'
) AS better_bibtex;

SELECT itemID, itemKey, citationKey, pinned
FROM better_bibtex.citationkey
ORDER BY itemID;
```


## Dumping Core Zotero Schema and Data

### Schema

```sql
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
)  AS written_char_count
FROM schema, db_path;
```

### Data as SQL

```sql
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
```

### Data as JSON with Array Values

```sql
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
        '        json_pretty(json_object(',
        '            ''table_name'', ''collections'',',
        '            ''column_names'', json(''{@cols}''),',
        '            ''values'',',
        '            json_group_array(',
        '                json_array(',
        '                    {@vals}',
        '                ) ORDER BY ROWID',
        '            )',
        '        ) || x''0A''',
        '    )) AS code',
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
            json_group_array(json_quote(col_name) ORDER BY cid) AS cols,
            group_concat('json_quote("' || col_name || '")', ', ' ORDER BY cid) AS vals
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
                '{@output}', prefix || '/data_' || tbl_name || '.json'
            ) AS code
        FROM metadata, dump_template, db_path
    )
SELECT tbl_name, code FROM queries;
```

### Data as JSON with Object Values

```sql
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
        '        json_pretty(json_group_array(',
        '                json_object(',
        '                    {@vals}',
        '                ) ORDER BY ROWID',
        '            )',
        '        ) || x''0A''',
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
            json_group_array(json_quote(col_name) ORDER BY cid) AS cols,
            group_concat(
                '''' || col_name || ''', ' || 'json_quote("' || col_name || '")',
                ', ' ORDER BY cid
            ) AS vals
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
                '{@output}', prefix || '/data_' || tbl_name || '.json'
            ) AS code
        FROM metadata, dump_template, db_path
    )
SELECT tbl_name, code FROM queries;
```


<!-- References -->

[Zotero]: https://zotero.org
[SQLite]: https://sqlite.org
[Zotero Client Data Model]: https://zotero.org/support/dev/client_coding/direct_sqlite_database_access
[RDBMS]: https://en.wikipedia.org/wiki/Relational_database
[SQL]: https://en.wikipedia.org/wiki/SQL
[SQLite docs]: https://sqlite.org/docs.html
[SQLite SQL Tutorial]: https://pchemguy.github.io/SQLite-SQL-Tutorial/
[SQLiteIntro]: https://pchemguy.github.io/SQLite-SQL-Tutorial/meta/engine
[SQLiteDistro]: https://www.sqlite.org/download.html
[SQLiteICU]: https://pchemguy.github.io/SQLite-ICU-MinGW/
[EAV]: https://en.wikipedia.org/wiki/Entity-attribute-value_model
[DB Norm]: https://en.wikipedia.org/wiki/Database_normalization
[ERD Concepts]: https://erdconcepts.com
[ERD Diagram]: #ERD_Diagram
[Data Modeling]: https://en.wikipedia.org/wiki/Data_modeling
[CTE]: https://sqlite.org/lang_with.html
[DB]: https://en.wikipedia.org/wiki/Database
[Zotero_MainDB-ERD_Concepts_8.svg]: https://raw.githubusercontent.com/pchemguy/ZoteroDataModel/refs/heads/main/MainDB/Zotero_MainDB-ERD_Concepts_8.svg
