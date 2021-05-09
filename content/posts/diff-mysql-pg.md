---
title:  "如何在比较 MySQL 跟 PostgreSQL 之间的数据是否一致"
date: 2021-05-09T18:13:00+08:00
draft: false
---

## 背景

最近遇到一个问题，有用户想从 PostgreSQL 同步数据到 TiDB（MySQL 相同的协议），希望知道同步后的数据是否是一致的。此类问题之前没接触过，稍微研究了一下。
校验一般就是两边都做一个 checksum，对比一下。

## TiDB（MySQL）侧

对于某张表的校验，其实用的是下面这个 SQL

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

具体找一个例子，

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

结果是，

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
|
                                                         5062371 |
+-------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

## PostgreSQL 侧

目的比较简单就是希望能写出跟上面一样的 SQL，但是 PostgreSQL 不支持 bit_xor、crc32、isnull，也没有 unsigned。所以，解决办法比较简单，就是靠 UDF。
于是，搜了一下，主要缺失的函数，通过一些改写，都可以解决。

bit_xor:

```SQL
CREATE OR REPLACE AGGREGATE BIT_XOR(IN v bigint) (SFUNC = int8xor, STYPE = bigint);
```

crc32:

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
    binary_string = decode(replace(text_string, E'\\\\', E'\\\\\\\\'), 'escape');
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

isnull:

```SQL
CREATE OR REPLACE FUNCTION isnull( anyelement ) RETURNS int as $$
BEGIN
    RETURN CAST(($1 IS NULL) as INT);
END
$$LANGUAGE plpgsql;
```

创建好上面三个 UDF 后，试一下上面的用例，注意，UNSIGNED 要改成 BIGINT。

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

结果，

```text
 bit_xor
---------
 5062371
(1 row)
```

跟 TiDB（MySQL）那边的完全一样。

## 后记

1. 更多的我没有测试，这里只是简单测一下。
1. UDF 确实是一个很好的功能，极大提升了灵活性。
