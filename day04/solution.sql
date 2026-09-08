DROP SCHEMA IF EXISTS day04 CASCADE;
CREATE SCHEMA day04;


create table day04.items (
    id SERIAL,
    value TEXT NOT NULL
);
create table day04.raw_bingo (line text);
create table day04.staging_grid (value text);

\copy day04.staging_grid (value) from 'day04/input_grid.txt'
\copy day04.raw_bingo FROM 'day04/input_bingo.txt'

insert into day04.items (value)
    select
        value
    from day04.staging_grid
    where value is not null
        and btrim(value) <> '';

create table day04.bingo_input (
    id SERIAL, 
    value INT NOT NULL
);

insert into day04.bingo_input (value)
   select unnest(string_to_array(line, ',')::int[]) from day04.raw_bingo;

create table day04.grid_values (
    grid INT,
    id INT,
    num INT,
    pos INT,
    marked_by INT
);

insert into day04.grid_values (grid, id, num, pos)
    select 
        FLOOR((id - 1) / 5) + 1 as grid,
        id, 
        num::int as num,
        pos
    from day04.items,
    regexp_split_to_table(btrim(value), '\s+') with ordinality as t(num, pos);

UPDATE day04.grid_values gv
SET marked_by = b.id
FROM day04.bingo_input b
WHERE gv.num = b.value;

WITH bingos_marked_by AS (
    SELECT
        grid,
        id,
        pos,
        MAX(marked_by) OVER (PARTITION BY id) AS first_row_marked_by,
        MAX(marked_by) OVER (PARTITION BY pos, grid) AS first_column_marked_by
    FROM day04.grid_values
    order by grid, id, pos
), bingos_by AS (
    select
        grid,
        MIN(first_row_marked_by) as row_bingo_by, 
        MIN(first_column_marked_by) as column_bingo_by, 
        LEAST(MIN(first_row_marked_by), MIN(first_column_marked_by)) as bingo_by 
    from bingos_marked_by
    group by grid
    -- order by bingo_by asc
    -- LIMIT 1
), result_first_bingo AS (
    select
        SUM(gv.num) * (select value::int from day04.bingo_input where id = bingo.bingo_by) as result
    from day04.grid_values gv 
    INNER JOIN bingos_by bingo
    on gv.grid = bingo.grid
    and gv.marked_by > bingo.bingo_by
    group by bingo.bingo_by 
    order by bingo_by asc
    limit 1
), result_last_bingo AS (
    select
        SUM(gv.num) * (select value::int from day04.bingo_input where id = bingo.bingo_by) as result
    from day04.grid_values gv 
    INNER JOIN bingos_by bingo
    on gv.grid = bingo.grid
    and gv.marked_by > bingo.bingo_by
    group by bingo.bingo_by 
    order by bingo_by desc
    limit 1
)
SELECT
       (SELECT result FROM result_first_bingo) AS first_bingo,
       (SELECT result FROM result_last_bingo) AS last_bingo;
