---
title: "How to Compare Data Consistency between MySQL and PostgreSQL"
date: 2021-05-09T18:13:00+08:00
draft: false
---

## Background

Recently, I encountered a problem where a user wanted to synchronize data from PostgreSQL to TiDB (which uses the same protocol as MySQL) and wanted to know whether the data after synchronization is consistent. I hadn't dealt with this kind of issue before, so I did a bit of research.

Typically, to verify data consistency, you compute a checksum on both sides and compare them.

## TiDB (MySQL) Side

For the verification of a specific table, the following SQL is used:

```SQL
SELECT bit_xor(
    CAST(crc32(
        concat_ws(',',
            col1, col2, col3, …, colN,
            concat(isnull(col1), isnull(col2), …, isnull(colN))
        )
    ) AS UNSIGNED)
)
FROM t;
```

Let's look at a specific example:

```SQL
DROP TABLE IF EXISTS t;
CREATE TABLE t (i INT, j INT);
INSERT INTO t VALUES (2, 3), (NULL, NULL);
SELECT bit_xor(
    CAST(crc32(
        concat_ws(',',
            i, j,
            concat(isnull(i), isnull(j))
        )
    ) AS UNSIGNED)
)
FROM t;
```

The result is:

```text
+-------------------------------------------------------------------------------------------------------------------------------------------+
| bit_xor(
    CAST(crc32(
        concat_ws(',',
            i, j,
            concat(isnull(i), isnull(j))
        )
    ) AS UNSIGNED)
) |
+-------------------------------------------------------------------------------------------------------------------------------------------+
|                                                           5062371 |
+-------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

## PostgreSQL Side

The goal is simply to write the same SQL as above, but PostgreSQL does not support `bit_xor`, `crc32`, `isnull`, nor does it have unsigned types. Therefore, the solution is relatively straightforward—relying on UDFs (User-Defined Functions).

After some research, the main missing functions can be addressed with a few custom implementations.

`bit_xor`:

```SQL
CREATE OR REPLACE AGGREGATE bit_xor(IN v bigint) (SFUNC = int8xor, STYPE = bigint);
```

`crc32`:

```SQL
CREATE OR REPLACE FUNCTION crc32(text_string text) RETURNS bigint AS $$
DECLARE
    tmp bigint;
    i int;
    j int;
    byte_length int;
    binary_string bytea;
BEGIN
    IF text_string = '' THEN
        RETURN 0;
    END IF;

    i = 0;
    tmp = 4294967295;
    byte_length = bit_length(text_string) / 8;
    binary_string = decode(replace(text_string, E'\\', E'\\\\'), 'escape');
    LOOP
        tmp = (tmp # get_byte(binary_string, i))::bigint;
        i = i + 1;
        j = 0;
        LOOP
            tmp = ((tmp >> 1) # (3988292384 * (tmp & 1)))::bigint;
            j = j + 1;
            IF j >= 8 THEN
                EXIT;
            END IF;
        END LOOP;
        IF i >= byte_length THEN
            EXIT;
        END IF;
    END LOOP;
    RETURN (tmp # 4294967295);
END
$$ IMMUTABLE LANGUAGE plpgsql;
```

`isnull`:

```SQL
CREATE OR REPLACE FUNCTION isnull(anyelement) RETURNS int AS $$
BEGIN
    RETURN CAST(($1 IS NULL) AS INT);
END
$$ LANGUAGE plpgsql;
```

After creating the three UDFs above, let's test the previous example. Note that `UNSIGNED` should be changed to `BIGINT`.

```SQL
DROP TABLE IF EXISTS t;
CREATE TABLE t (i INT, j INT);
INSERT INTO t VALUES (2, 3), (NULL, NULL);
SELECT bit_xor(
    CAST(crc32(
        concat_ws(',',
            i, j,
            concat(isnull(i), isnull(j))
        )
    ) AS BIGINT)
)
FROM t;
```

The result:

```text
 bit_xor
---------
 5062371
(1 row)
```

It's exactly the same as on the TiDB (MySQL) side.

## Postscript

1. I haven't tested more extensively; this is just a simple test.
2. UDFs are indeed a great feature that greatly enhance flexibility.
