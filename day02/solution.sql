DROP SCHEMA IF EXISTS day02 CASCADE;
CREATE SCHEMA day02;

CREATE TYPE day02.direction AS ENUM (
    'up', 'down', 'forward'
);

CREATE TABLE day02.items (
    id SERIAL,
    val INTEGER,
    direction day02.direction
);

\copy day02.items (direction, val) FROM 'day02/input.txt' WITH (DELIMITER ' ');

-- WITH forward AS (
--     SELECT sum(items.val) as sum FROM day02.items where items.direction = 'forward'
-- ),
-- up AS (
--     SELECT sum(items.val) as sum FROM day02.items where items.direction = 'up'
-- ),
-- down AS (
--     SELECT sum(items.val) as sum FROM day02.items where items.direction = 'down'
-- )
-- SELECT 
--     forward.sum as x, 
--     (down.sum - up.sum) as y, 
--     (forward.sum * (down.sum - up.sum)) as prod 
-- from forward
-- cross join up
-- cross join down;
\echo 'part1';
with movement as (
    select 
        sum(val) filter (where direction = 'forward') as x,
        sum(val) filter (where direction = 'up') as up,
        sum(val) filter (where direction = 'down') as down
    from day02.items
) 
select 
x, (down-up) as y, (x * (down-up)) as product
from movement;

\echo 'part2';

WITH accumulated_aim AS (
    select
        coalesce(
            sum(val) filter (where direction = 'up')
                over (order by id rows between unbounded preceding and current row),
            0
        ) as accumulated_up,
        coalesce(
            sum(val) filter (where direction = 'down')
                over (order by id rows between unbounded preceding and current row),
            0
        ) as accumulated_down,
        case when direction = 'forward' then val else 0 end as forward
    from day02.items
), position AS (
    select 
        sum(forward * (accumulated_down - accumulated_up)) as depth,
        sum(forward) as x
    from accumulated_aim where forward != 0
)
select depth, x, depth * x as product from position;
