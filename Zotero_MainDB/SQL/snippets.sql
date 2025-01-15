-- ASCII ID Generation

WITH
    symbols(symbol) AS (VALUES ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')),
    id_specs(num, len) AS (VALUES (1, 8)),
    placeholders AS (SELECT '[' || replace(hex(zeroblob(len*num-1)), '00', '0,') || '0]' AS json_template FROM id_specs),
    ascii_ids AS (
        SELECT
            group_concat(substr(symbol, (random() & 31) + 1, 1), '') AS ascii_id,
            "key"/8 AS counter
        FROM symbols, placeholders, json_each(placeholders.json_template) AS terms
        GROUP BY counter
    ),
    ids AS (
        SELECT
            group_concat(substr(symbol, (random() & 31) + 1, 1), '') AS ascii_id
        FROM symbols, placeholders, json_each(placeholders.json_template) AS terms
        GROUP BY "key"/8
    )
SELECT * FROM ids;


WITH
    tools(symbol, template) AS (VALUES(
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', '[0,0,0,0,0,0,0,0]'
    )),
    ids AS (
        SELECT
            group_concat(substr(symbol, (random() & 31) + 1, 1), '') AS ascii_id
        FROM tools, json_each(tools.template)
        GROUP BY "key"/8
    )
SELECT * FROM ids;



WITH
    dummies(dummy_key) AS (VALUES 
		('000'), ('001'), ('010'), ('011'), ('01A'), ('0A0'), ('0A1'), ('0AA'),
		('100'), ('101'), ('10A'), ('110'), ('111'), ('1A0'), ('1A1'), ('1AA'),
		('A00'), ('A01'), ('A0A'), ('A10'), ('A1A'), ('AA0'), ('AA1'), ('AAA')
	),
	tools(symbol, template) AS (VALUES(
        '01A01A01', '[0,0,0]'
    )),
	new_ids  AS (
        SELECT
            group_concat(substr(symbol, (random() & 7) + 1, 1), '') AS ascii_id
        FROM tools, json_each(tools.template)
        GROUP BY "key"/8
    ),
    ids AS (
		SELECT ascii_id, dummy_key
		FROM new_ids
		LEFT JOIN dummies
		ON ascii_id = dummy_key
    )
SELECT * FROM ids ;


