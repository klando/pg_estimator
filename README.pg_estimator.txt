= pg_estimator

A simple PostgreSQL extension in pure SQL to estimate relation size for X tuples.

== Installation

[src,bash]
----
$ make
$ make install
$ make installcheck
----

[src,sql]
----
CREATE EXTENSION pg_estimator;
----
== Usage 

It is required that the table to estimate does already exists and contains some
data. Distribution of data (including NULL) is important and will be respected.

The estimation is done for fully packed pages and can be wrong up to 10% in some
cases.

* FUNCTION pg_estimate_heap_size(p_relation regclass, p_tuples bigint)
  Returns the estimate size for the HEAP files.
* FUNCTION pg_estimate_toast_size(p_relation regclass, p_tuples bigint)
  Returns the estimate size for the TOAST files.
* FUNCTION pg_estimate_index_size(p_irelation regclass, p_tuples bigint)
  Returns the estimate size for the INDEX files.
* FUNCTION pg_estimate_indexes_size(p_relation regclass, p_tuples bigint)
  Returns the estimate size for all the INDEX files of a table.
* FUNCTION pg_estimate_total_relation_size(p_relation regclass, p_tuples bigint)
  Returns the estimate size for all the files of a table (including all of the above).

Parameters :
* p_relation : the regclass for the table
* p_irelation : the regclass for the index
* p_tuples number of tuples used for estimation

Results : All results are in _bytes_.

== Example

Pretty simple examples :

[src,sql]
----
-- schema qualified if required
SELECT pg_size_pretty(pg_estimate_total_relation_size('test.table_test'));
-- name protected if required
SELECT pg_size_pretty(pg_estimate_total_relation_size('"public.Table Test'));
-- possible to call with OID of the relation (nice to JOIN with pg_class)
SELECT pg_size_pretty(pg_estimate_total_relation_size(oid))
FROM pg_class
WHERE relname = 'Table Test';
----
== Limitation

* Real FILLFACTOR is not used on TOAST tables.

* VM and FSM files are not accounted (very small files)

* Partial or Functionnal Indexes are not accounted !!!


