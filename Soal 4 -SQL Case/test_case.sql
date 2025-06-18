
-- Test Case 1
-- total revenue for each channel group
select country, channelgrouping, sum(coalesce(totaltransactionrevenue,0)) as sum_trx	
from data_ecommerce
where country in ( -- select top 5 countries producing the highest revenue
	select country
	from data_ecommerce
	group by country
	order by SUM(coalesce(totaltransactionRevenue,0)) desc
	limit 5
	)
group by country, channelgrouping
order by country, sum_trx desc
-- Insigths:    Top 5 countries are Canada, Curacao, Taiwan, United States, and Venezuela
--              channel grouping has the most revenue is Refferal



-- Test Case 2
-- create cte to calculate average for field (timeonsite, pageviews, and sessionqualitydim) for each fullvisitorid
with cte as (
select fullvisitorid, round(avg(timeonsite),2) as avg_timeonsite, round(avg(pageviews),2) as avg_pageviews, round(avg(sessionqualitydim),2) as avg_sessionqualitydim
from data_ecommerce
group by fullvisitorid)

select fullvisitorid, avg_timeonsite, avg_pageviews
from ( -- create a new field for the average for time_onsite and pageviews
select *, 
	round(avg(avg_timeonsite) over(),2) as allavg_time, 
	round(avg(avg_pageviews) over(),2) as allavg_page
from cte ) sub
where avg_timeonsite > allavg_time and avg_pageviews < allavg_page -- select id with avg_timeonsite > all timeonsite average and avg_pageviews < all avg_page
ORDER BY avg_timeonsite, avg_pageviews DESC;
-- Insights:    From this query, we know that 562 of visitors spend more time on our site but view fewer pages than the average users
--              We can conclude that these visitors may interested but hesistant because (spend more time in a page)
--              We can assume that the visitor may carefully making decision or have a slow internet




-- Test Case 3
--a
select distinct v2productname, sum(coalesce(totaltransactionrevenue,0)) as total_revenue
from data_ecommerce
group by v2productname
order by total_revenue desc
-- Insights: Top 3 products based on total_revenue are Google Tote Bag, Collapsible Shopping Bag, Sport Bag

--b
select v2productname, sum(coalesce(productquantity,0)) as total_quantity
from data_ecommerce
group by v2productname
order by total_quantity desc
-- Insights: Top 3 products based on total_quantity are Sport Bag, Google Leather Perforated Journal, Reusable Shopping Bag

--c
select v2productname, sum(coalesce(productrefundamount,0)) as total_refund
from data_ecommerce
group by v2productname
-- Insights : There are no refunds

--rank
select v2productname as productname, 
	sum(coalesce(totaltransactionrevenue,0)) as total_revenue,
	sum(coalesce(productquantity,0)) as total_quantity,
	sum(coalesce(productrefundamount,0)) as total_refund,
	rank() over(
	ORDER BY 
            SUM(COALESCE(totaltransactionrevenue, 0)) - SUM(COALESCE(productRefundAmount, 0)) DESC --net revenue descending order
	) revenue_rank,
    -- if refundamount > 10% of totaltransactionrevenue. Then it will be flagged
	CASE 
        WHEN SUM(COALESCE(productRefundAmount, 0)) > 0.1 * SUM(COALESCE(totaltransactionrevenue, 0)) THEN 'Flagged'
        ELSE ''
    END AS refund_flag
from data_ecommerce
group by productname
-- Insights :   Based on the rank. Google Tote Bag produce the highest revenue.
--              Net value has the same amount with total transaction revenue because there is no refund
--              No Flagged products
