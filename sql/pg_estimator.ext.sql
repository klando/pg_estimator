CREATE EXTENSION pg_estimator;

SELECT es_get_size_aligned(23, 4);
SELECT * from es_constants();

-- LARGE NUMBER OF COLS
CREATE TABLE foo(i0 int, i1 int, i2 int, i3 int, i4 int, i5 int, i6 int, i7 int,
                 i8 int, i9 int, i10 int, i11 int, i12 int, i13 int, i14 int,
		 i15 int, i16 int, i17 int, i18 int, i19 int, i20 int, i21 int,
		 i22 int, i23 int, i24 int, i25 int, i26 int, i27 int, i28 int,
		 i29 int, i30 int, i31 int, i32 int, i33 int, i34 int, i35 int,
		 i36 int, i37 int, i38 int, i39 int, i40 int, i41 int, i42 int,
		 i43 int, i44 int, i45 int, i46 int, i47 int, i48 int, i49 int,
		 i50 int, i51 int, i52 int, i53 int, i54 int, i55 int, i56 int,
		 i57 int, i58 int, i59 int, i60 int, i61 int, i62 int, i63 int,
		 i64 int);
INSERT INTO foo select n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,
n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n,n 
from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

-- INT + NULLs
CREATE TABLE foo(id1 int);
INSERT INTO foo select n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int);
INSERT INTO foo select n,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int, id3 int, id4 int);
INSERT INTO foo select n,n,n,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int, id3 int, id4 int);
INSERT INTO foo select null,n,n,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int, id3 int, id4 int);
INSERT INTO foo select n,null,n,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int, id3 int, id4 int);
INSERT INTO foo select n,n,null,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int, id3 int, id4 int);
INSERT INTO foo select n,n,n,null from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(id1 int,id2 int, id3 int, id4 int);
INSERT INTO foo select null,n,null,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

-- TEXT + INT + NULLs
CREATE TABLE foo(t1 text, i1 int, t2 text, i2 int);
INSERT INTO foo select n,n,n,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(t1 text, i1 int, t2 text, i2 int);
INSERT INTO foo select n,n,null,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

-- COMPRESSED DATA
CREATE TABLE foo(t1 text, i1 int, t2 text, i2 int);
INSERT INTO foo select repeat('1234567890',(2^9)::integer),n,n,n from generate_series(1,1000000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

-- TOAST DATA
CREATE TABLE foo(t1 text, i1 int, t2 text, i2 int);
INSERT INTO foo select repeat('1234567890',(2^16)::integer),n,n,n from generate_series(1,10000) as g(n);
SELECT es_get_datawidth('public', 'foo');
SELECT es_get_toastwidth('public', 'foo');
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 10000));
SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 10000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 10000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

-- INDEXES TODO
CREATE TABLE foo(t1 text UNIQUE, i1 int, t2 text, i2 int, t3 text, i3 int);
INSERT INTO foo select n,n,n,n from generate_series(1,1000000) as g(n);
REINDEX TABLE foo;

SELECT pg_size_pretty( pg_indexes_size('foo'));
SELECT pg_size_pretty( pg_estimate_indexes_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_table_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000)
        	       + pg_estimate_toast_size('public', 'foo', 1000000) );
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));

SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(t1 text, i1 int UNIQUE, t2 text, i2 int, t3 text, i3 int);
INSERT INTO foo select n,n,n,n from generate_series(1,1000000) as g(n);
REINDEX TABLE foo;

SELECT pg_size_pretty( pg_indexes_size('foo'));
SELECT pg_size_pretty( pg_estimate_indexes_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_table_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000)
        	       + pg_estimate_toast_size('public', 'foo', 1000000) );
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));

SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;

CREATE TABLE foo(t1 text, i1 int, t2 text, i2 int, t3 text, i3 int, UNIQUE (t1,i3));
INSERT INTO foo select n,n,n,n from generate_series(1,1000000) as g(n);
REINDEX TABLE foo;

SELECT pg_size_pretty( pg_indexes_size('foo'));
SELECT pg_size_pretty( pg_estimate_indexes_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_table_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000)
        	       + pg_estimate_toast_size('public', 'foo', 1000000) );
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));

SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;


CREATE TABLE foo(t1 text UNIQUE, i1 int, t2 text, i2 int, t3 text, i3 int, UNIQUE (i1,i3));
INSERT INTO foo select n,n,n,n from generate_series(1,1000000) as g(n);
REINDEX TABLE foo;

SELECT pg_size_pretty( pg_indexes_size('foo'));
SELECT pg_size_pretty( pg_estimate_indexes_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000));
SELECT pg_size_pretty( pg_table_size('foo'));
SELECT pg_size_pretty( pg_estimate_heap_size('public', 'foo', 1000000)
        	       + pg_estimate_toast_size('public', 'foo', 1000000) );
SELECT pg_size_pretty( pg_total_relation_size('foo'));
SELECT pg_size_pretty( pg_estimate_total_relation_size('public', 'foo', 1000000));

SELECT pg_size_pretty( pg_total_relation_size('foo') - pg_estimate_total_relation_size('public', 'foo', 1000000));
SELECT ((pg_estimate_total_relation_size('public', 'foo', 1000000) * 100)
       / pg_total_relation_size('foo') - 100) || ' %';
DROP TABLE foo;


-- HELPER
-- 
CREATE TABLE t AS SELECT repeat('1234567890',(2^n)::integer) FROM generate_series(0,20) n;
SELECT length(repeat), octet_length(repeat), pg_column_size(repeat) FROM t;
DROP TABLE t;

DROP EXTENSION pg_estimator;
