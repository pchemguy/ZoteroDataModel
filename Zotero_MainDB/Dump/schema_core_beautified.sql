CREATE TABLE IF NOT EXISTS "itemTypes" (
    "itemTypeID"          INTEGER PRIMARY KEY,
    "typeName"            TEXT,
    "templateItemTypeID"  INTEGER,
    "display"             INTEGER DEFAULT 1
);


CREATE TABLE IF NOT EXISTS "items" (
    "itemID"              INTEGER PRIMARY KEY,
    "itemTypeID"          INTEGER NOT NULL REFERENCES "itemTypes"("itemTypeID"),
    "dateAdded"           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dateModified"        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "clientDateModified"  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "libraryID"           INTEGER NOT NULL,
    "key"                 TEXT NOT NULL,
    "version"             INTEGER NOT NULL DEFAULT 0,
    "synced"              INTEGER NOT NULL DEFAULT 0,
    UNIQUE("libraryID","key")
);


CREATE TABLE IF NOT EXISTS "creatorTypes" (
    "creatorTypeID"       INTEGER PRIMARY KEY,
    "creatorType"         TEXT
);


CREATE TABLE IF NOT EXISTS "creators" (
    "creatorID"           INTEGER PRIMARY KEY,
    "firstName"           TEXT,
    "lastName"            TEXT,
    "fieldMode"           INTEGER,
    UNIQUE("lastName","firstName","fieldMode")
);


CREATE TABLE IF NOT EXISTS "itemCreators" (
    "itemID"              INTEGER NOT NULL REFERENCES "items"("itemID") ON DELETE CASCADE,
    "creatorID"           INTEGER NOT NULL REFERENCES "creators"("creatorID") ON DELETE CASCADE,
    "creatorTypeID"       INTEGER NOT NULL DEFAULT 1
                              REFERENCES "creatorTypes"("creatorTypeID"),
    "orderIndex"          INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("itemID","creatorID","creatorTypeID","orderIndex"),
    UNIQUE("itemID","orderIndex")
);


CREATE TABLE IF NOT EXISTS "fields" (
    "fieldID"             INTEGER PRIMARY KEY,
    "fieldName"           TEXT,
    "fieldFormatID"       INTEGER
);


CREATE TABLE IF NOT EXISTS "fieldsCombined" (
    "fieldID"             INTEGER PRIMARY KEY,
    "fieldName"           TEXT NOT NULL,
    "label"               TEXT,
    "fieldFormatID"       INTEGER REFERENCES "fieldFormats"("fieldFormatID"),
    "custom"              INTEGER NOT NULL
);


CREATE TABLE IF NOT EXISTS "itemTypes" (
    "itemTypeID"          INTEGER PRIMARY KEY,
    "typeName"            TEXT,
    "templateItemTypeID"  INT,
    "display"             INT DEFAULT 1
);


CREATE TABLE IF NOT EXISTS "baseFieldMappings" (
    "itemTypeID"          INTEGER REFERENCES "itemTypes"("itemTypeID"),
    "baseFieldID"         INTEGER REFERENCES "fields"("fieldID"),
    "fieldID"             INTEGER REFERENCES "fields"("fieldID"),
    PRIMARY KEY("itemTypeID","baseFieldID","fieldID")
);


CREATE TABLE IF NOT EXISTS "itemDataValues" (
    "valueID"             INTEGER PRIMARY KEY,
    "value"               UNIQUE
);


CREATE TABLE IF NOT EXISTS "itemData" (
    "itemID"              INTEGER REFERENCES "items"("itemID") ON DELETE CASCADE,
    "fieldID"             INTEGER REFERENCES "fieldsCombined"("fieldID"),
    "valueID"             INTEGER REFERENCES "itemDataValues"("valueID"),
    PRIMARY KEY("itemID","fieldID")
);


CREATE TABLE IF NOT EXISTS "charsets" (
    "charsetID"           INTEGER PRIMARY KEY,
    "charset"             TEXT UNIQUE
);


CREATE TABLE IF NOT EXISTS "itemAttachments" (
    "itemID"                        INTEGER PRIMARY KEY REFERENCES "items"("itemID") ON DELETE CASCADE,
    "parentItemID"                  INTEGER REFERENCES "items"("itemID") ON DELETE CASCADE,
    "linkMode"                      INTEGER,
    "contentType"                   TEXT,
    "charsetID"                     INTEGER REFERENCES "charsets"("charsetID") ON DELETE SET NULL,
    "path"                          TEXT,
    "syncState"                     INTEGER DEFAULT 0,
    "storageModTime"                INTEGER,
    "storageHash"                   TEXT,
    "lastProcessedModificationTime" INTEGER
);


CREATE TABLE IF NOT EXISTS "itemAnnotations" (
    "itemID"              INTEGER PRIMARY KEY REFERENCES "items"("itemID") ON DELETE CASCADE,
    "parentItemID"        INTEGER NOT NULL REFERENCES "itemAttachments"("itemID"),
    "type"                INTEGER NOT NULL,
    "authorName"          TEXT,
    "text"                TEXT,
    "comment"             TEXT,
    "color"               TEXT,
    "pageLabel"           TEXT,
    "sortIndex"           TEXT NOT NULL,
    "position"            TEXT NOT NULL,
    "isExternal"          INTEGER NOT NULL
);


CREATE TABLE IF NOT EXISTS "itemNotes" (
    "itemID"              INTEGER PRIMARY KEY REFERENCES "items"("itemID") ON DELETE CASCADE,
    "parentItemID"        INTEGER REFERENCES "items"("itemID") ON DELETE CASCADE,
    "note"                TEXT,
    "title"               TEXT
);


CREATE TABLE IF NOT EXISTS "itemRelations" (
    "itemID"              INTEGER NOT NULL REFERENCES "items"("itemID") ON DELETE CASCADE,
    "predicateID"         INTEGER NOT NULL,
    "object"              TEXT NOT NULL,
    PRIMARY KEY("itemID","predicateID","object")
);


CREATE TABLE IF NOT EXISTS "tags" (
    "tagID"               INTEGER PRIMARY KEY,
    "name"                TEXT NOT NULL UNIQUE
);


CREATE TABLE IF NOT EXISTS "itemTags" (
    "itemID"              INTEGER NOT NULL REFERENCES "items"("itemID") ON DELETE CASCADE,
    "tagID"               INTEGER NOT NULL REFERENCES "tags"("tagID") ON DELETE CASCADE,
    "type"                INTEGER NOT NULL,
    PRIMARY KEY("itemID","tagID")
);


CREATE TABLE IF NOT EXISTS "itemTypes" (
    "itemTypeID"          INTEGER PRIMARY KEY,
    "typeName"            TEXT,
    "templateItemTypeID"  INTEGER,
    "display"             INTEGER DEFAULT 1
);


CREATE TABLE IF NOT EXISTS "itemTypeFields" (
    "itemTypeID"          INTEGER REFERENCES "itemTypes"("itemTypeID"),
    "fieldID"             INTEGER REFERENCES "fields"("fieldID"),
    "hide"                INTEGER,
    "orderIndex"          INTEGER,
    UNIQUE("itemTypeID","fieldID"),
    PRIMARY KEY("itemTypeID","orderIndex")
);


CREATE TABLE IF NOT EXISTS "itemTypeCreatorTypes" (
    "itemTypeID"          INTEGER REFERENCES "itemTypes"("itemTypeID"),
    "creatorTypeID"       INTEGER REFERENCES "creatorTypes"("creatorTypeID"),
    "primaryField"        INTEGER,
    PRIMARY KEY("itemTypeID","creatorTypeID")
);


CREATE TABLE IF NOT EXISTS "collections" (
    "collectionID"        INTEGER PRIMARY KEY,
    "collectionName"      TEXT NOT NULL,
    "parentCollectionID"  INTEGER DEFAULT NULL REFERENCES "collections"("collectionID") ON DELETE CASCADE,
    "clientDateModified"  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "libraryID"           INTEGER NOT NULL,
    "key"                 TEXT NOT NULL,
    "version"             INTEGER NOT NULL DEFAULT 0,
    "synced"              INTEGER NOT NULL DEFAULT 0,
    UNIQUE("libraryID","key")
);


CREATE TABLE IF NOT EXISTS "collectionItems" (
    "collectionID"        INTEGER NOT NULL REFERENCES "collections"("collectionID") ON DELETE CASCADE,
    "itemID"              INTEGER NOT NULL REFERENCES "items"("itemID") ON DELETE CASCADE,
    "orderIndex"          INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("collectionID","itemID")
);
