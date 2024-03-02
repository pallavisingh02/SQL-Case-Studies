-- 1. What is the total amount each customer spent at the restaurant?
Select
    customer_id,
    Sum(Price) as total_amount
from
    Sales
    inner join menu on sales.product_id = menu.product_id
group by
    customer_id;

-- 2. How many days has each customer visited the restaurant?
Select
    customer_id,
    Count(distinct order_date) as days_visited
from
    Sales
group by
    customer_id;

-- 3. What was the first item from the menu purchased by each customer?
Select
    customer_id,
    order_date,
    product_name
From
(
        select
            dense_rank() Over(
                partition by customer_id
                order by
                    order_date
            ) as r,
            customer_id,
            order_date,
            product_name
        from
            Sales
            inner join menu on sales.product_id = menu.product_id
    ) A
where
    r = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers? 
select
    product_name as Most_purchased,
    count(Sales.product_id) as Number_Of_times
from
    Sales
    join menu on sales.product_id = menu.product_id
group by
    Sales.product_id
order by
    Number_Of_times desc
Limit
    1;

-- 5. Which item was the most popular for each customer?
Select
    customer_id,
    product_name as most_popular
from
(
        select
            customer_id,
            product_name,
            Dense_Rank() Over(
                partition by customer_id
                order by
                    count(product_name) desc
            ) as r
        from
            sales
            join menu on sales.product_id = menu.product_id
        group by
            customer_id,
            product_name
    ) A
where
    r = 1;

-- 6. Which item was purchased first by the customer after they became a member?
Select
    customer_id,
    order_date,
    product_name
from
(
        select
            sales.customer_id,
            order_date,
            product_name,
            Dense_Rank() Over(
                Partition by sales.customer_id
                order by
                    order_date
            ) as r
        from
            sales
            inner join members on sales.customer_id = members.customer_id
            Left join menu on sales.product_id = menu.product_id
        where
            order_date > members.join_date
    ) A
where
    r = 1;

-- 7. Which item was purchased just before the customer became a member?
Select
    customer_id,
    order_date,
    product_name
from
(
        select
            sales.customer_id,
            order_date,
            product_name,
            Dense_Rank() Over(
                Partition by sales.customer_id
                order by
                    order_date desc
            ) as r
        from
            sales
            inner join members on sales.customer_id = members.customer_id
            Left join menu on sales.product_id = menu.product_id
        where
            order_date < members.join_date
    ) A
where
    r = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select
    sales.customer_id,
    count(product_name) as total_items,
    Sum(price) as amount_spent
from
    sales
    inner join members on sales.customer_id = members.customer_id
    Left join menu on sales.product_id = menu.product_id
where
    order_date < members.join_date
group by
    sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With Points as(
    Select
        *,
        Case
            When product_id = 1 THEN price * 20
            Else price * 10
        End as Points
    From
        Menu
)
Select
    S.customer_id,
    Sum(P.points) as Points
From
    Sales S
    Join Points p On p.product_id = S.product_id
Group by
    S.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with ctes as (
    select
        sales.customer_id,
        order_date,
        join_date,
        price,
        case
            when order_date between members.join_date
            and date_add(members.join_date, interval 6 Day) then price * 20
            else case
                when sales.product_id = 1 then price * 20
                else price * 10
            end
        end as Points
    from
        sales
        inner join members on sales.customer_id = members.customer_id
        Inner Join menu On sales.product_id = menu.product_id
)
select
    customer_id,
    sum(Points)
from
    ctes
where
    order_date < cast('2021-01-31' as date)
group by
    customer_id;