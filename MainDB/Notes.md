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

The tables and queries above do not include author/creator fields. Each item type may contain certain creator types (per many-to-many table `itemTypeCreatorTypes`) from the list defined in the `creatorTypes` table (top-left quadrant of the ERD diagram).

#### Item type creators

The following query returns a list of item types and associated permissible creator types as JSON arrays:

```sql
SELECT
    itemTypes.typeName,
    json_group_array(creatorType
        ORDER BY primaryField DESC, itemTypeCreatorTypes.creatorTypeID
    ) AS creatorTypeNames
FROM itemTypes, creatorTypes, itemTypeCreatorTypes
WHERE itemTypeCreatorTypes.creatorTypeID = creatorTypes.creatorTypeID
  AND itemTypeCreatorTypes.itemTypeID = itemTypes.itemTypeID
GROUP BY itemTypes.typeName
ORDER BY itemTypes.itemTypeID;
```

#### Field Mapping

```sql
SELECT it.typeName, bf.fieldName AS baseFieldName, f.fieldName
FROM itemTypes AS it, fields AS bf, fields AS f, baseFieldMappings AS bfm
WHERE (bfm.itemTypeID, bfm.baseFieldID, bfm.fieldID) = (it.itemTypeID, bf.fieldID, f.fieldID)
ORDER BY bf.fieldName, f.fieldName;
```