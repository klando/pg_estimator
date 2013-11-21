-- complain if script is sourced in psql, rather than via CREATE EXTENSION
-- \echo Use "CREATE EXTENSION pg_estimator;" to load this file. \quit

-- TODO use real FILLFACTOR for TOASTed tables
-- TODO account VM ?
-- TODO account FSM ?
-- XXX estimate of index does not really account nullbitmap (pg_columns already rounded its results including null_frac)

--
-- Function to get result aligned
CREATE OR REPLACE
FUNCTION es_get_size_aligned(bigint, bigint)
RETURNS BIGINT
LANGUAGE SQL IMMUTABLE
AS $$
SELECT $1 + $2 - (case when $1 % $2 = 0 THEN $2 ELSE $1 % $2 END);
$$;

--
-- Function to get the sytem/postgresql constants
-- See http://www.postgresql.org/docs/current/static/storage-page-layout.html
CREATE OR REPLACE
FUNCTION es_constants(OUT BlockSize int,
                      OUT HeapTupleHeaderData int,
                      OUT MAXALIGN int,
                      OUT PageHeaderData int,
                      OUT ItemIdData int,
                      OUT ItemPointerData int)
LANGUAGE SQL IMMUTABLE
AS $$
SELECT 
  current_setting('block_size')::int AS BlockSize,
  23 AS HeapTupleHeaderData,
  8 AS MAXALIGN, -- MAXALIGN  -- FIXME

  24 AS PageHeaderData,
  4 AS ItemIdData,
  6 AS ItemPointerData;
$$;

--
-- Function to get the fillfactor of a relation
CREATE OR REPLACE
FUNCTION es_get_fillfactor(p_relation regclass)
RETURNS INT
LANGUAGE SQL STABLE
AS $$
SELECT
  COALESCE(
    regexp_replace(
      reloptions::text, E'.*fillfactor=(\\d+).*', E'\\1'),
    CASE WHEN relkind = 'i' THEN '90' ELSE '100' END)::int
  FROM pg_class
 WHERE oid = p_relation;
$$;

--
-- Function to get the relname of a relation
CREATE OR REPLACE
FUNCTION es_get_relname(p_relation regclass)
RETURNS name
LANGUAGE SQL STABLE
AS $$
SELECT relname
  FROM pg_class
 WHERE oid = p_relation;
$$;

--
-- Function to get the avg data width of a row
CREATE OR REPLACE
FUNCTION es_get_datawidth(p_relation regclass)
RETURNS BIGINT
LANGUAGE PLPGSQL STABLE
AS $$
DECLARE
  v_datawidth bigint;
BEGIN
EXECUTE 'select avg(pg_column_size(' || quote_ident(es_get_relname(p_relation)) || '))::bigint from '
	|| p_relation
INTO STRICT v_datawidth;
RAISE DEBUG 'datawidth for relation % : % bytes', p_relation,v_datawidth;
RETURN v_datawidth;
END;
$$;

--
-- Function to get the avg number of tuples in TOAST for 1 tuple in HEAP
CREATE OR REPLACE
FUNCTION es_get_toastwidth(p_relation regclass)
RETURNS BIGINT
LANGUAGE PLPGSQL STABLE
AS $$
DECLARE
  v_datawidth bigint := 0;
  v_toastrelation regclass;
BEGIN

SELECT CASE WHEN reltoastrelid != 0 THEN reltoastrelid::regclass
       ELSE NULL END
  FROM pg_class
 WHERE oid = p_relation
INTO STRICT v_toastrelation;

IF v_toastrelation IS NOT NULL THEN
  EXECUTE 'SELECT avg(c)::bigint '
    || ' * es_get_datawidth('
    || quote_literal(v_toastrelation)
    || ') FROM (select count(chunk_id) as c from '
      || v_toastrelation
      || ' GROUP BY chunk_id) s'
  INTO v_datawidth;
END IF;
RAISE DEBUG 'avg toast datawidth for 1 tuple in heap: % bytes', coalesce(v_datawidth,0);
RETURN coalesce(v_datawidth,0);
END;
$$;

--
-- Function to get the avg data width of a column, removing NULLs from the data width
CREATE OR REPLACE
FUNCTION es_get_coldatawidth(p_relation regclass, p_attnum smallint)
RETURNS BIGINT
LANGUAGE PLPGSQL STABLE
AS $$
DECLARE
  v_datawidth bigint;
BEGIN
EXECUTE 'select avg(pg_column_size((' || p_attnum || ')))::bigint from '
	|| p_relation
INTO v_datawidth;
RAISE DEBUG 'datawidth for relation %, column % : % bytes', p_relation, p_attnum, v_datawidth;
RETURN v_datawidth;
END;
$$;

--
-- Function to get the avg width of an index tuple
CREATE OR REPLACE
FUNCTION es_get_indexwidth(p_irelation regclass)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
-- Sum datawidth of each column of the index
WITH atts AS (
  SELECT unnest(indkey) as indkey, indrelid::regclass as v_relation
  FROM pg_index
 WHERE indisvalid AND indexprs IS NULL AND indpred IS NULL
   AND indexrelid = p_irelation
),
summarize AS (
  SELECT sum(es_get_coldatawidth(v_relation, indkey)) as s
  FROM atts
)
SELECT (s + ItemPointerData)::bigint
FROM summarize, es_constants();    
$$;

--                                    --
-- Function to estimate relation size --
--                                    --

--
-- HEAP
CREATE OR REPLACE
FUNCTION pg_estimate_heap_size(p_relation regclass, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT (
  ceil(
    p_tuples
    / (
      es_get_fillfactor(p_relation)/100::real * (BlockSize - PageHeaderData)
      / (ItemIdData
         + es_get_size_aligned(es_get_datawidth(p_relation), MAXALIGN))
      )
  ) * BlockSize
)::bigint
FROM es_constants();
$$;

--
-- TOAST
-- How many tuples in TOAST for 1 tuple in HEAP ?
CREATE OR REPLACE
FUNCTION pg_estimate_toast_size(p_relation regclass, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT (
  ceil(
    p_tuples
    /(
      1.0 * (BlockSize - PageHeaderData) -- TODO take the fillfactor of the toast table
      / (ItemIdData
         + es_get_size_aligned(es_get_toastwidth(p_relation), MAXALIGN))
      )
  ) * BlockSize
)::bigint
FROM es_constants();
$$;

--
-- INDEX
CREATE OR REPLACE
FUNCTION pg_estimate_index_size(p_irelation regclass, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT (
  ceil(
    p_tuples
    / (
      (es_get_fillfactor(p_irelation)/100::real) * (BlockSize - PageHeaderData)
      / (ItemIdData
         + es_get_size_aligned(es_get_indexwidth(p_irelation), MAXALIGN))
      )
  ) * BlockSize
)::bigint
FROM es_constants();
$$;

--
-- INDEXES (sum of all indexes)
CREATE OR REPLACE
FUNCTION pg_estimate_indexes_size(p_relation regclass, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT SUM(COALESCE(pg_estimate_index_size(indexrelid::regclass, p_tuples), 0))::bigint
  FROM pg_index
 WHERE indrelid = p_relation
   AND indisvalid AND indexprs IS NULL AND indpred IS NULL;
$$;

--
-- TOTAL RELATION SIZE
-- 
CREATE OR REPLACE
FUNCTION pg_estimate_total_relation_size(p_relation regclass, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT
  -- HEAP (MAIN)
  COALESCE(pg_estimate_heap_size(p_relation, p_tuples), 0)
  +
  -- HEAP (VM)
  0
  +
  -- TOAST
  COALESCE(pg_estimate_toast_size(p_relation, p_tuples), 0)
  +
  -- INDEX
  COALESCE(pg_estimate_indexes_size(p_relation, p_tuples), 0)
  +
  -- FSM: depends on FILLFACTOR too
  0
;
$$;
