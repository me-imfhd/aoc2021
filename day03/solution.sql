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
    select distinct
        pos,
        COUNT(*) FILTER (WHERE bit = '0') OVER (PARTITION BY pos) AS low_state,
        COUNT(*) FILTER (WHERE bit = '1') OVER (PARTITION BY pos) AS high_state
    from split_items_partitioned
    order by pos
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
