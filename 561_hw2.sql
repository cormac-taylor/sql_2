-- Cormac Taylor | 20014003
-- I pledge my honor that I have abided by the Stevens Honor system.

-- Query 1:
with cur as 
(select prod, month, avg(quant) as cur_avg
  from sales
  group by prod, month),
prev as
(select avg1.prod, avg1.month, avg2.cur_avg as prev_avg
  from cur avg1 left join cur avg2
  	on avg1.month - 1 = avg2.month
	and avg1.prod = avg2.prod),
next as
(select avg1.prod, avg1.month, avg2.cur_avg as next_avg
  from cur avg1 left join cur avg2
  	on avg1.month + 1 = avg2.month
	and avg1.prod = avg2.prod),
reference as
(select prev.prod, prev.month, prev_avg, next_avg
  from prev, cur, next
  where prev.prod = cur.prod and prev.month = cur.month
   and cur.prod = next.prod and cur.month = next.month)
select s.prod as product, s.month, count(s.quant) as sales_count_between_avgs
 from sales as s natural join reference as r
 where (s.quant between r.prev_avg and r.next_avg)
  or (s.quant between r.next_avg and r.prev_avg)
 group by s.prod, s.month

-- Query 2:
with ext_sales as 
(select cust, prod, (((month - 1) / 3) + 1) as qrtr, quant
  from sales),
base as
(select cust, prod, qrtr, avg(quant) cur_avg
  from ext_sales
  group by cust, prod, qrtr),
prev as
(select avg1.cust, avg1.prod, avg1.qrtr, avg2.cur_avg as prev_avg
  from base avg1 left join base avg2
  	on avg1.qrtr - 1 = avg2.qrtr
	and avg1.cust = avg2.cust
	and avg1.prod = avg2.prod),
next as
(select avg1.cust, avg1.prod, avg1.qrtr, avg2.cur_avg as next_avg
  from base avg1 left join base avg2
  	on avg1.qrtr + 1 = avg2.qrtr
	and avg1.cust = avg2.cust
	and avg1.prod = avg2.prod)
select base.cust as customer, base.prod as product, base.qrtr, prev_avg as before_avg, cur_avg as during_avg, next_avg as after_avg
  from prev, base, next
  where prev.cust = base.cust and prev.prod = base.prod and prev.qrtr = base.qrtr
   and base.cust = next.cust and base.prod = next.prod and base.qrtr = next.qrtr

-- Query 3:
with base as 
(select cust, prod, state, quant
  from sales),
simple_avg as 
(select cust, prod, state, avg(quant) as prod_avg
  from base
  group by cust, prod, state),
cust_avg as 
(select c as cust, prod, state, avg(quant) as other_cust_avg
  from base, (select distinct cust as c
		  	   from base) as custs
  where c <> cust
  group by c, prod, state), 
prod_avg as 
(select cust, p as prod, state, avg(quant) as other_prod_avg
  from base, (select distinct prod as p
		  	   from base) as prods
  where p <> prod
  group by cust, p, state)
select cust as customer, prod as product, state, prod_avg, other_cust_avg, other_prod_avg
 from simple_avg natural join cust_avg natural join prod_avg
 
 -- Query 4:
with q1 as 
(select distinct prod, quant
  from sales),
q2 as
(select b.prod, b.quant, count(a.quant) as rank
  from q1 as a, q1 as b
  where a.prod = b.prod
   and a.quant <= b.quant
  group by b.prod, b.quant),
q3 as
(select s.prod, count(q1.quant) as pos
  from sales as s, q1
  where s.prod = q1.prod
   and s.quant <= q1.quant
  group by s.prod, q1.quant),
q4 as
(select b.prod, b.pos, count(a.pos) as rank
  from q3 as a, q3 as b
  where a.prod = b.prod
   and a.pos <= b.pos
  group by b.prod, b.pos),
q5 as
(select prod, (ceiling(count(prod) / 2.0)) as middle
  from sales
  group by prod),
q6 as 
(select prod, quant, pos
  from q2 natural join q4 natural join q5
  where pos >= middle), 
q7 as
(select prod, min(pos) as median
  from q6
  group by prod)
select distinct prod as product, quant
 from q6 natural join q7
 where pos = median
 