DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;


create table day03.items (
    id SERIAL,
    value TEXT
);

\copy day03.items (value) from 'day03/input.txt';

-- WITH split_items_paritioned AS (
--     select
--         items.id,
--         u.bit,
--         u.pos
--     from day03.items,
--     lateral string_to_table(items.value, NULL)
--     with ordinality as u(bit, pos)
--     order by u.pos, items.id
-- )
--
-- select 
--     mode() WITHIN GROUP (ORDER BY bit) as mcb
-- from split_items_paritioned

\echo 'part1';

WITH split_items AS (
    select
        id,
        regexp_split_to_table(value, '') as bit
    from day03.items
), split_items_partitioned AS (
    select
        id,
        bit,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS pos
    from split_items
    order by pos, id
), count_states AS (
    SELECT
        pos,
        COUNT(*) FILTER (WHERE bit = '0') AS low_state,
        COUNT(*) FILTER (WHERE bit = '1') AS high_state
    FROM split_items_partitioned
    GROUP BY pos
    ORDER BY pos
), calc_gamma_bits AS (
    select
        string_agg(
            case when low_state > high_state then '0' else '1' end,
            ''
            order by pos
        ) as gamma_bits
    from count_states
), solution AS (
    select
        lpad(gamma_bits, 32, '0')::bit(32)::int as gamma,
        (~ lpad(gamma_bits, 32, '1')::bit(32))::int as elipson
    from calc_gamma_bits
)
SELECT gamma, elipson, gamma*elipson as power_consumption FROM solution;

\echo 'part2';

DROP TABLE IF EXISTS split_items_partitioned;
CREATE TEMP TABLE split_items_partitioned AS
SELECT id, bit, ordinality AS pos
FROM day03.items,
     regexp_split_to_table(value, '') WITH ORDINALITY AS t(bit, ordinality);

-- Index for the join/filter pattern used every loop iteration, and give the
-- planner real stats instead of guessing on an empty-looking new temp table
CREATE INDEX ON split_items_partitioned (pos, bit, id);
CREATE INDEX ON split_items_partitioned (id);
ANALYZE split_items_partitioned;

CREATE OR REPLACE FUNCTION day03.find_rating(criteria TEXT)
RETURNS INT AS $$
DECLARE
  cur_pos INT := 1;
  winner_bit TEXT;
  remaining_count INT;
  result_id INT;
BEGIN
  DROP TABLE IF EXISTS remaining;
  CREATE TEMP TABLE remaining AS SELECT DISTINCT id FROM split_items_partitioned;
  CREATE INDEX ON remaining (id);
  ANALYZE remaining;

  LOOP
    SELECT COUNT(*) INTO remaining_count FROM remaining;
    EXIT WHEN remaining_count <= 1;

    IF criteria = 'O2' THEN
      SELECT bit INTO winner_bit
      FROM split_items_partitioned r
      JOIN remaining rm ON rm.id = r.id
      WHERE r.pos = cur_pos
      GROUP BY bit
      ORDER BY COUNT(*) DESC, bit DESC
      LIMIT 1;
    ELSE
      SELECT bit INTO winner_bit
      FROM split_items_partitioned r
      JOIN remaining rm ON rm.id = r.id
      WHERE r.pos = cur_pos
      GROUP BY bit
      ORDER BY COUNT(*) ASC, bit ASC
      LIMIT 1;
    END IF;

    -- NOT EXISTS instead of NOT IN: scales better, avoids NULL edge cases
    DELETE FROM remaining rm
    WHERE NOT EXISTS (
      SELECT 1 FROM split_items_partitioned r
      WHERE r.id = rm.id AND r.pos = cur_pos AND r.bit = winner_bit
    );

    -- keep stats fresh as the table shrinks; drop this line if it adds
    -- more overhead than it saves on your data size
    ANALYZE remaining;

    cur_pos := cur_pos + 1;
  END LOOP;

  SELECT id INTO result_id FROM remaining LIMIT 1;
  RETURN result_id;
END;
$$ LANGUAGE plpgsql;

WITH ratings AS (
    SELECT
        (SELECT lpad(value, 32, '0')::bit(32)::int FROM day03.items WHERE id = day03.find_rating('O2'))  AS o2_value,
        (SELECT lpad(value, 32, '0')::bit(32)::int FROM day03.items WHERE id = day03.find_rating('CO2')) AS co2_value
)
SELECT o2_value, co2_value, o2_value * co2_value as result from ratings;
