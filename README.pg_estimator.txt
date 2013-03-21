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

* FUNCTION pg_estimate_heap_size(p_schemaname text, p_relname text, p_tuples bigint)
  Returns the estimate size for the HEAP files.
* FUNCTION pg_estimate_toast_size(p_schemaname text, p_relname text, p_tuples bigint)
  Returns the estimate size for the TOAST files.
* FUNCTION pg_estimate_index_size(p_schemaname text, p_relname text, p_irelname text, p_tuples bigint)
  Returns the estimate size for the INDEX files.
* FUNCTION pg_estimate_indexes_size(p_schemaname text, p_relname text, p_tuples bigint)
  Returns the estimate size for all the INDEX files of a table.
* FUNCTION pg_estimate_total_relation_size(p_schemaname text, p_relname text, p_tuples bigint)
  Returns the estimate size for all the files of a table (including all of the above).

Parameters :
* p_schemaname : schema name
* p_relname table name
* p_irelname index name
* p_tuples number of tuples used for estimation

Results : All results are in _bytes_.

== Example

A pretty simple example :

[src,sql]
----
SELECT pg_size_pretty(pg_estimate_total_relation_size('public', 'table_test'));
----
== Limitation

* Real FILLFACTOR is not used on TOAST tables.

* VM and FSM files are not accounted (very small files)

* Partial or Functionnal Indexes are not accounted !!!


