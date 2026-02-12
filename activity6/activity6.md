# Scenario 1: The Slow Author Profile Page
EXPLAIN ANALYZE SELECT id, title FROM posts WHERE author_id = 100 ORDER BY date DESC; 

BEFORE
```txt

                                                 QUERY PLAN
-------------------------------------------------------------------------------------------------------------
 Sort  (cost=625.38..625.42 rows=18 width=52) (actual time=1.045..1.046 rows=16.00 loops=1)
   Sort Key: date DESC
   Sort Method: quicksort  Memory: 26kB
   Buffers: shared hit=503
   ->  Seq Scan on posts  (cost=0.00..625.00 rows=18 width=52) (actual time=0.175..1.014 rows=16.00 loops=1)
         Filter: (author_id = 100)
         Rows Removed by Filter: 9984
         Buffers: shared hit=500
 Planning:
   Buffers: shared hit=67 dirtied=2
 Planning Time: 0.275 ms
 Execution Time: 1.068 ms
(12 rows)


Time: 2.248 ms
```

AFTER
```txt
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=66.78..66.82 rows=18 width=52) (actual time=0.056..0.057 rows=16.00 loops=1)
   Sort Key: date DESC
   Sort Method: quicksort  Memory: 26kB
   Buffers: shared hit=16 read=2
   ->  Bitmap Heap Scan on posts  (cost=4.42..66.40 rows=18 width=52) (actual time=0.035..0.048 rows=16.00 loops=1)
         Recheck Cond: (author_id = 100)
         Heap Blocks: exact=16
         Buffers: shared hit=16 read=2
         ->  Bitmap Index Scan on idx_author_id  (cost=0.00..4.42 rows=18 width=0) (actual time=0.023..0.023 rows=16.00 loops=1)
               Index Cond: (author_id = 100)
               Index Searches: 1
               Buffers: shared read=2
 Planning:
   Buffers: shared hit=30 read=2
 Planning Time: 0.252 ms
 Execution Time: 0.084 ms
(16 rows)


Time: 0.706 ms
```

ii Analysis Questions:

1.  What is the primary node causing the slowness in the initial execution plan?

* The primary node causing slowness is the sequential scan, which scans all 10,000 rows in the posts table to filter out only 16 rows for author_id = 100 based on the result. Most rows are discarded, based on cmd the rows removed by filter: 9984, making this step inefficient. 

2. How can you optimize both the WHERE clause filtering and the ORDER BY operation with a single change?

* I realized that the main bottleneck was the sequential scan on all 10,000 rows, so to optimize the query, I created a single-column index on author_id. By doing this, PostgreSQL can quickly locate only the rows that match the specific author instead of scanning the entire table. Although the query still sorts by date DESC, the sort is now performed on just the small number of filtered rows, which is much faster than sorting the entire table.

3. Implement your fix and record the new plan. How much faster is the query now?

* After i reran the query, and PostgreSQL used a Bitmap Heap Scan with an Index Scan on author_id, retrieving only the 16 rows for author_id = 100. The execution time dropped from 1.068 ms to 0.084 ms, which is a significant improvement. By filtering first with the index and sorting only the relevant rows, I made the query over 10 times faster and much more efficient.

# Scenario 2: The Unsearchable Blog

ii Analysis Questions:

BEFORE
```txt
activity6=# EXPLAIN ANALYZE SELECT title FROM posts WHERE title LIKE '%database%';
                                             QUERY PLAN
-----------------------------------------------------------------------------------------------------
 Seq Scan on posts  (cost=0.00..625.00 rows=1 width=44) (actual time=3.986..3.987 rows=0.00 loops=1)
   Filter: ((title)::text ~~ '%database%'::text)
   Rows Removed by Filter: 10000
   Buffers: shared hit=500
 Planning:
   Buffers: shared hit=6
 Planning Time: 0.402 ms
 Execution Time: 4.004 ms
(8 rows)


Time: 5.142 ms
```

AFTER
```txt
activity6=# EXPLAIN ANALYZE SELECT title FROM posts WHERE title LIKE '%database%';
                                                         QUERY PLAN                                                     
----------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using idx_title on posts  (cost=0.29..515.28 rows=1 width=44) (actual time=2.972..2.972 rows=0.00 loops=1)
   Filter: ((title)::text ~~ '%database%'::text)
   Rows Removed by Filter: 10000
   Heap Fetches: 0
   Index Searches: 1
   Buffers: shared hit=1 read=84
 Planning:
   Buffers: shared hit=16 read=1
 Planning Time: 0.392 ms
 Execution Time: 2.988 ms
(10 rows)


Time: 3.950 ms
```

Rewrite Query
```txt
activity6=# EXPLAIN ANALYZE SELECT title FROM posts WHERE title LIKE 'database%';
                                                         QUERY PLAN                                                     
----------------------------------------------------------------------------------------------------------------------------
 Index Only Scan using idx_title on posts  (cost=0.29..515.28 rows=1 width=44) (actual time=1.146..1.146 rows=0.00 loops=1)
   Filter: ((title)::text ~~ 'database%'::text)
   Rows Removed by Filter: 10000
   Heap Fetches: 0
   Index Searches: 1
   Buffers: shared hit=85
 Planning Time: 0.173 ms
 Execution Time: 1.182 ms
(8 rows)


Time: 2.194 ms
```

1. First, try adding a standard B-Tree index on the title column. Run EXPLAIN ANALYZE again. Did the planner use your index? Why or why not?

* No, After adding standard B-Tree index on the title column and rerun the EXPLAIN ANALYZE it shows seq scan showing that the planner did not use the index. Why? Because as i can see the query FILTER explain it starts with % which cause the string unknown and prevent the index from being efficiently used. With this it shows result of non-sargable and full scan not by index.

2. The business team agrees that searching by a prefix is acceptable for the first version. Rewrite the query to use a prefix search (e.g., database%).

```txt
EXPLAIN ANALYZE
SELECT title
FROM posts
WHERE title LIKE 'database%';

```

3. Does the index work for the prefix-style query? Explain the difference in the execution plan.
* Yes, the index work for the prefix-style query. Why? Because when the search pattern start with string not % the execution plan now shows an Index Only Scan, which means the database can efficiently locate matching rows without scanning the entire table.


# Scenario 3: The Monthly Performance Report

ii Analysis Questions:

Non-Sargable
```txt
EXPLAIN ANALYZE SELECT * FROM posts WHERE EXTRACT(YEAR FROM "date") = 2000 AND EXTRACT (MONTH FROM "date") = 1;
```

1. This query is not S-ARGable. What does that mean in the context of this query? Why can't the query planner use a simple index on the date column effectively?

* As i do the query it is already seen the non-sargable part which is the EXTRACT function. Because of this the index on date column could not be use effectively resulting the database scan the whole table. When I ran EXPLAIN ANALYZE, it showed a sequential scan on the posts table, removing 9,986 rows by the filter and returning only 14 rows. The planning time was 0.531 milliseconds, and the execution time was 2.497 milliseconds. From this, I observed that all rows were scanned, and the query was slower than Sargable because the index was ignored.

2. Rewrite the query to use a direct date range comparison, making it S-ARGable.

```txt
EXPLAIN ANALYZE SELECT * FROM posts WHERE "date" >= DATE '2000-01-01' AND "date" < DATE '2000-02-01';
```

3. Create an appropriate index to support your rewritten query.

```txt
CREATE INDEX idx_date ON posts(date);
```
4. Compare the performance of the original query and your optimized version.

BEFORE(NON-SARGABLE)
```txt
activity6=# EXPLAIN ANALYZE SELECT * FROM posts WHERE EXTRACT(YEAR FROM "date") = 2000 AND EXTRACT (MONTH FROM "date") = 1;
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Seq Scan on posts  (cost=0.00..700.00 rows=1 width=366) (actual time=0.335..2.479 rows=14.00 loops=1)
   Filter: ((EXTRACT(year FROM date) = '2000'::numeric) AND (EXTRACT(month FROM date) = '1'::numeric))
   Rows Removed by Filter: 9986
   Buffers: shared hit=500
 Planning:
   Buffers: shared hit=16 read=1 dirtied=2
 Planning Time: 0.531 ms
 Execution Time: 2.497 ms
(8 rows)


Time: 3.525 ms
```

AFTER(SARGABLE)
```txt
activity6=# EXPLAIN ANALYZE SELECT * FROM posts WHERE "date" >= DATE '2000-01-01' AND "date" < DATE '2000-02-01';
                                                      QUERY PLAN
----------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on posts  (cost=4.45..60.10 rows=16 width=366) (actual time=0.116..0.126 rows=14.00 loops=1)
   Recheck Cond: ((date >= '2000-01-01'::date) AND (date < '2000-02-01'::date))
   Heap Blocks: exact=14
   Buffers: shared hit=14 read=2
   ->  Bitmap Index Scan on idx_date  (cost=0.00..4.45 rows=16 width=0) (actual time=0.105..0.105 rows=14.00 loops=1)
         Index Cond: ((date >= '2000-01-01'::date) AND (date < '2000-02-01'::date))
         Index Searches: 1
         Buffers: shared read=2
 Planning Time: 0.086 ms
 Execution Time: 0.139 ms
(10 rows)


Time: 0.695 ms
```

* Based on the query, the non-SARGable query scanned all rows using a sequential scan and took about 2.497 milliseconds. The SARGable query, on the other hand, used the idx_date index, scanned only 14 rows, and executed in about 0.139 milliseconds. This clearly showed me that making a query SARGable and using an appropriate index improves efficiency and scalability.