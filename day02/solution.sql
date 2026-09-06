DROP SCHEMA IF EXISTS day02 CASCADE;
CREATE SCHEMA day02;

CREATE TABLE day02.items (
    id SERIAL,
    val INTEGER
);

\copy day02.items (val) FROM 'day02/input.txt' WITH (FORMAT 'text');


WITH measurements AS (
    WITH sequence AS (
        SELECT id, val FROM day02.items
        ORDER BY id
    )
    SELECT
        curr1.val + curr2.val + curr3.val AS first_measurement,
        curr2.val + curr3.val + next.val AS second_measurement
    FROM sequence curr1
    JOIN sequence curr2 ON curr2.id = curr1.id + 1
    JOIN sequence curr3 ON curr3.id = curr2.id + 1
    JOIN sequence next ON next.id = curr3.id + 1
)

SELECT COUNT(*) FROM measurements where second_measurement > first_measurement;
