#### Item type creators - Query

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

