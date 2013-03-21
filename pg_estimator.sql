-- complain if script is sourced in psql, rather than via CREATE EXTENSION
-- \echo Use "CREATE EXTENSION pg_estimator;" to load this file. \quit

-- TODO use real FILLFACTOR for TOASTed tables
-- TODO account VM ?
-- TODO account FSM ?
-- TODO use oid ?
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
FUNCTION es_get_fillfactor(p_schemaname text, p_relname text)
RETURNS INT
LANGUAGE SQL STABLE
AS $$
SELECT
  COALESCE(
    regexp_replace(
      reloptions::text, E'.*fillfactor=(\\d+).*', E'\\1'),
    CASE WHEN relkind = 'i' THEN '90' ELSE '100' END)::int
  FROM pg_class cr
  JOIN pg_namespace nr ON (nr.oid = cr.relnamespace)
 WHERE cr.relname = p_relname AND nr.nspname = p_schemaname;
$$;

--
-- Function to get the avg data width of a row
CREATE OR REPLACE
FUNCTION es_get_datawidth(p_schemaname text, p_relname text)
RETURNS BIGINT
LANGUAGE PLPGSQL STABLE
AS $$
DECLARE
  v_datawidth bigint;
BEGIN
EXECUTE 'select avg(pg_column_size(' || quote_ident(p_relname) || '))::bigint from '
	|| quote_ident(p_schemaname) || '.' || quote_ident(p_relname)
INTO STRICT v_datawidth;
RETURN v_datawidth;
END;
$$;

--
-- Function to get the avg number of tuples in TOAST for 1 tuple in HEAP
CREATE OR REPLACE
FUNCTION es_get_toastwidth(p_schemaname text, p_relname text)
RETURNS BIGINT
LANGUAGE PLPGSQL STABLE
AS $$
DECLARE
  v_datawidth bigint := 0;
  v_toastschemaname text;
  v_toastrelname text;
BEGIN

SELECT nt.nspname, ct.relname
  FROM pg_class ct
  JOIN pg_class cr ON (ct.oid = cr.reltoastrelid)
  JOIN pg_namespace nt ON (nt.oid = ct.relnamespace)
  JOIN pg_namespace nr ON (nr.oid = cr.relnamespace)
 WHERE cr.relname = p_relname AND nr.nspname = p_schemaname
INTO v_toastschemaname, v_toastrelname;

IF FOUND THEN
  EXECUTE 'SELECT avg(c)::bigint '
    || ' * es_get_datawidth('
    || quote_literal(v_toastschemaname) || ', ' || quote_literal(v_toastrelname)
    || ') FROM (select count(chunk_id) as c from '
      || quote_ident(v_toastschemaname) || '.' || quote_ident(v_toastrelname)
      || ' GROUP BY chunk_id) s'
  INTO v_datawidth;
END IF;
RETURN coalesce(v_datawidth,0);
END;
$$;

--
-- Function to get the avg data width of a column, removing NULLs from the data width
CREATE OR REPLACE
FUNCTION es_get_coldatawidth(p_schemaname text, p_relname text, p_attnum int)
RETURNS BIGINT
LANGUAGE PLPGSQL STABLE
AS $$
DECLARE
  v_datawidth bigint;
BEGIN
EXECUTE 'select avg(pg_column_size((' || p_attnum || ')))::bigint from '
	|| quote_ident(p_schemaname)||'.'||quote_ident(p_relname)
INTO v_datawidth;
RETURN v_datawidth;
END;
$$;

--
-- Function to get the avg width of an index tuple
CREATE OR REPLACE
FUNCTION es_get_indexwidth(p_schemaname text, p_relname text, p_irelname text)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
-- Sum datawidth of each column of the index
WITH atts AS (
  SELECT unnest(indkey) as indkey
  FROM pg_index
 WHERE indisvalid AND indexprs IS NULL AND indpred IS NULL
   AND indexrelid = p_irelname::regclass
),
summarize AS (
  SELECT sum(es_get_coldatawidth(p_schemaname, p_relname, indkey)) as s
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
FUNCTION pg_estimate_heap_size(p_schemaname text, p_relname text, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT (
  ceil(
    p_tuples
    / floor(
      (es_get_fillfactor(p_schemaname, p_relname)/100::real) * (BlockSize - PageHeaderData)
      / (ItemIdData
         + es_get_size_aligned(es_get_datawidth(p_schemaname, p_relname), MAXALIGN))
      )
  ) * BlockSize
)::bigint
FROM es_constants();
$$;

--
-- TOAST
-- How many tuples in TOAST for 1 tuple in HEAP ?
CREATE OR REPLACE
FUNCTION pg_estimate_toast_size(p_schemaname text, p_relname text, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT (
  ceil(
    p_tuples
    / floor(
      1.0 * (BlockSize - PageHeaderData)
      / (ItemIdData
         + es_get_size_aligned(es_get_toastwidth(p_schemaname, p_relname), MAXALIGN))
      )
  ) * BlockSize
)::bigint
FROM es_constants();
$$;

--
-- INDEX
CREATE OR REPLACE
FUNCTION pg_estimate_index_size(p_schemaname text, p_relname text, p_irelname text, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT (
  ceil(
    p_tuples
    / floor(
      (es_get_fillfactor(p_schemaname, p_irelname)/100::real) * (BlockSize - PageHeaderData)
      / (ItemIdData
         + es_get_size_aligned(es_get_indexwidth(p_schemaname, p_relname, p_irelname), MAXALIGN))
      )
  ) * BlockSize
)::bigint
FROM es_constants();
$$;

--
-- INDEXES (sum of all indexes)
CREATE OR REPLACE
FUNCTION pg_estimate_indexes_size(p_schemaname text, p_relname text, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT SUM(COALESCE(pg_estimate_index_size(p_schemaname, p_relname, ci.relname, p_tuples), 0))::bigint
  FROM pg_index i
  JOIN pg_class cr ON (cr.oid = i.indrelid)
  JOIN pg_class ci ON (ci.oid = i.indexrelid)
  JOIN pg_namespace nr ON (nr.oid = cr.relnamespace)
 WHERE nr.nspname = p_schemaname AND cr.relname = p_relname
   AND indisvalid AND indexprs IS NULL AND indpred IS NULL;
$$;

--
-- TOTAL RELATION SIZE
-- 
CREATE OR REPLACE
FUNCTION pg_estimate_total_relation_size(p_schemaname text, p_relname text, p_tuples bigint)
RETURNS BIGINT
LANGUAGE SQL STABLE
AS $$
SELECT
  -- HEAP (MAIN)
  COALESCE(pg_estimate_heap_size(p_schemaname, p_relname, p_tuples), 0)
  +
  -- HEAP (VM)
  0
  +
  -- TOAST
  COALESCE(pg_estimate_toast_size(p_schemaname, p_relname, p_tuples), 0)
  +
  -- INDEX
  COALESCE(pg_estimate_indexes_size(p_schemaname, p_relname, p_tuples), 0)
  +
  -- FSM: depends on FILLFACTOR too
  0
;
$$;
