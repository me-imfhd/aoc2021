DROP SCHEMA IF EXISTS day01 CASCADE;
CREATE SCHEMA day01;

CREATE TABLE day01.items (
    id SERIAL,
    val INTEGER
);

\copy day01.items (val) FROM 'day01/input.txt' WITH (FORMAT 'text');

WITH sequence AS (
    SELECT id, val FROM day01.items
    ORDER BY id
)

SELECT COUNT(*) FROM sequence curr
JOIN sequence next ON next.id = curr.id + 1
WHERE next.val > curr.val;
