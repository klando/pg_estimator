DROP FUNCTION es_get_size_aligned(bigint, bigint);
DROP FUNCTION es_constants();
DROP FUNCTION es_get_fillfactor(p_relation regclass);
DROP FUNCTION es_get_relname(p_relation regclass);
DROP FUNCTION es_get_datawidth(p_relation regclass);
DROP FUNCTION es_get_toastwidth(p_relation regclass);
DROP FUNCTION es_get_coldatawidth(p_relation regclass, p_attname text);
DROP FUNCTION es_get_indexwidth(p_relation regclass, p_irelname text);
DROP FUNCTION pg_estimate_heap_size(p_relation regclass, p_tuples bigint);
DROP FUNCTION pg_estimate_toast_size(p_relation regclass, p_tuples bigint);
DROP FUNCTION pg_estimate_index_size(p_irelation regclass, p_tuples bigint);
DROP FUNCTION pg_estimate_indexes_size(p_relation regclass, p_tuples bigint);
DROP FUNCTION pg_estimate_total_relation_size(p_relation regclass, p_tuples bigint);
