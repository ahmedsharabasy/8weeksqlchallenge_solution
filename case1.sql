
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



--What is the  each customer spent at the restaurant? 

select s.customer_id  ,  sum(m.price) as totalamount
from menu m join sales s
on s.product_id = m.product_id
group by s.customer_id;


--How many days has each customer visited the restaurant?

select count(distinct(order_date )) from sales
group by customer_id;


--What was the first item from the menu purchased by each customer?



select s.customer_id, product_name, order_date,
ROW_NUMBER() over (partition by customer_id order by order_date) as ran
from sales s join menu m
on s.product_id = m.product_id

order by ran


WITH ranked_sales AS (
  SELECT
    "customer_id",
    "product_id",
    "order_date",
    ROW_NUMBER() OVER (PARTITION BY "customer_id" ORDER BY "order_date") AS purchase_rank
  FROM
    sales
)
  
SELECT
  r."customer_id",
  m."product_name" AS "first_purchase"
FROM
  ranked_sales r
JOIN
  menu m ON r."product_id" = m."product_id"
WHERE
  r.purchase_rank = 1
ORDER BY
  r."customer_id";



------------------------------------------------------------------------------------------------
-- 1. What is the total amount each customer spent at the restaurant?
select 
s.[customer_id], sum(m.[price]) as total_amount_spent
from [dbo].[menu] m
inner join [dbo].[sales] s
on m.[product_id] = s.[product_id]
group by [customer_id];


-- 2. How many days has each customer visited the restaurant?
select [customer_id], COUNT(distinct day([order_date]))
from [dbo].[sales]
group by [customer_id]


-- 3. What was the first item from the menu purchased by each customer?
select * from(
select 
	m.product_name, 
    ROW_NUMBER() over(partition by s.[customer_id] order by s.[order_date]) as rn
from 
	[dbo].[sales] s
inner join
	[dbo].[menu] m
on 
	s.product_id = m.product_id
) as first_item
where rn=1;

    --with cte
with cte as(
select 
	m.product_name, 
    ROW_NUMBER() over(partition by s.[customer_id] order by s.[order_date]) as rn
from 
	[dbo].[sales] s
inner join
	[dbo].[menu] m
on 
	s.product_id = m.product_id
) 

select * from cte where rn =1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top(1) [product_id], count([product_id]) as #purchased
from [dbo].[sales]
group by [product_id]
order by count(*) desc


-- 5. Which item was the most popular for each customer?

with cte1 as(
select [customer_id], [product_id],
       row_number() over(partition by [customer_id] order by count(*) desc) as dr
from [dbo].[sales]
group by [customer_id], [product_id]
) 

select * from cte1
where dr=1;


-- 6. Which item was purchased first by the customer after they became a member?
with cte1 as(
select s.[customer_id], s.[order_date], m.[join_date],
       row_number() over(partition by s.[customer_id] order by s.[order_date]) as dr
from [dbo].[sales] s
inner join [dbo].[members] m
on m.[customer_id] = s.[customer_id]
where m.[join_date] <= s.order_date
) 

select [customer_id], [order_date] from cte1
where dr=1;


-- 7. Which item was purchased just before the customer became a member?
select * from(
select s.customer_id, s.product_id, 
		ROW_NUMBER() over(partition by s.customer_id order by s.order_date desc) as rn
from sales s
inner join members m
on s.customer_id = m.customer_id
where s.order_date < m.join_date) as before_cus_mem
where rn =1
;


-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) as total_items , sum(m.price) as amount_spent
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mb on s.customer_id = mb.customer_id
where s.order_date < mb.join_date
group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--     - how many points would each customer have?
select s.customer_id, sum(#points) as #points from(
select 
  m.product_id, 
  case
  when m.product_id =1 then m.price * 20
  else m.price * 10
  end as #points
from menu m) as new_T
inner join sales s on s.product_id = new_T.product_id
group by s.customer_id;

----
-- another better solution:  using cte

with cte as(
select 
  m.product_id, 
  case
  when m.product_id =1 then m.price * 20
  else m.price * 10
  end as #points
from menu m
)

select customer_id, sum(cte.#points) as #points 
from sales s
inner join cte 
on cte.product_id = s.product_id
group by customer_id;

---
--another solution:   using variables
declare @p int
set @p=10;

with cte as(
select 
  m.product_id, 
  case
  when m.product_id =1 then m.price * @p *2
  else m.price * @p
  end as #points
from menu m
)

select customer_id, sum(cte.#points) as #points 
from sales s
inner join cte 
on cte.product_id = s.product_id
group by customer_id;


-- 10. In the first week after a customer joins the program (including their join date) 
--     they earn 2x points on all items, not just sushi 
--     - how many points do customer A and B have at the end of January?

with customerpoints as (
  select
    s.customer_id,
	case when s.order_date <= dateadd(day, 6, mb.join_date) then m.price * 20
	else
	case when m.product_id = 1 then m.price * 20
	else m.price * 10 end
    end as points
  from
    sales s
    inner join menu m on s.product_id = m.product_id
    inner join members mb on s.customer_id = mb.customer_id
  where
    s.order_date >= mb.join_date
    and s.order_date <= '2021-01-31'
)

select
  customer_id,
  sum(points) as total_points
from
  customerpoints
group by
  customer_id;
