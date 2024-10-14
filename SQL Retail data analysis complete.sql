--create database retail_analysis
--use retail_analysis
--Q1count nuber of rows in each table
select 'tran_tbl'as table_name,count(*) as cnt_transactions from transactions
union all 
select 'cust_tbl'as table_name,count(*) as cnt_customer from Customer
union all
select 'prod_cat_info'as table_name,count(*)  as cnt_prod_cat from prod_cat_info
------------------------------------------------------------------------------------
--Q2 What is the total number of transactions that have a return?
select count(*) as transactions_return from transactions as A
where A.qty <0
----------------------------------------------------------------------------------
/*Q3 As you would have noticed, the dates provided across the 
	datasets are not in a correct format. As first steps, pls 
	convert the date variables into valid date formats before
	proceeding ahead.*/
select 'Tran_date changed' as tbl_ref,convert(date,a.tran_date,103) as date_ from Transactions as A
union all
select 'customer_date_changed' as tbl_ref,convert(date,b.DOB,103) as date_1 from Customer as B
-----------------------------------------------------------------------------------------------------------
/*Q4 What is the time range of the transaction data available for analysis? 
	Show the output in number of days, months and years simultaneously
	in different columns.*/

select DATEDIFF(day, MIN(a.tran_date),MAX(a.tran_date)) as time_range_days,
DATEDIFF(month, MIN(a.tran_date),MAX(a.tran_date)) as time_range_months,
DATEDIFF(year, MIN(a.tran_date),MAX(a.tran_date)) as time_range_years
from Transactions as A
---------------------------------------------------------------------------------------
--Q5 Which product category does the sub-category “DIY” belong to?
select a.prod_cat as DIY_Category from prod_cat_info as A
where a.prod_subcat= 'DIY'
-------------------------------------------------------------------------------------------
--DATA ANALYSIS
--Q1 Which channel is most frequently used for transactions?
--ANS. e-Shop
select top 1 Store_type as most_frequently_used, count(a.Store_type) as channel_cnt from Transactions as A
group by a.Store_type
order by count(a.Store_type) desc
-----------------------------------------------------------------------------------------
--Q2 What is the count of Male and Female customers in the database?
--ANS. FEMLES = 2753, MALES = 2892
select a.Gender, count(a.Gender) as Gender_cnt from Customer as A
group by a.Gender
order by Gender_cnt 
offset 1 row
------------------------------------------------------------------------------------------------
--Q3 From which city do we have the maximum number of customers and how many?
--ANS. 595 CUSTOMER FROM CITY CODE 3
select top 1 a.city_code, count(a.city_code) as cnt_consumers from customer as a 
group by a.city_code
order by cnt_consumers desc
-------------------------------------------------------------------------------------------------------
--Q4 How many sub-categories are there under the Books category?
--ANS. 6
select a.prod_cat, count(a.prod_subcat) as cnt_subcat from prod_cat_info as a
where a.prod_cat= 'books'
group by a.prod_cat
-------------------------------------------------------------------------------------------------
--Q5 What is the maximum quantity of products ever ordered?
--ANS.BOOKS
select max(a.qty) as max_ever_ordered_qty from transactions as a
-----------------------------------------------------------------------------------------------
--Q6 What is the net total revenue generated in categories Electronics and Books?
--ANS.23545157.675
select b.prod_cat, SUM(a.total_amt) as revenue_generated from Transactions as A
inner join prod_cat_info as B on
a.prod_cat_code=b.prod_cat_code
where b.prod_cat='books' or b.prod_cat='electronics'
group by b.prod_cat
-----------------------------------------------------------------------------
--Q7 How many customers have >10 transactions with us, excluding returns?
--ANS. 6 
select cust_id, COUNT(cust_id) as no_of_trsn from Transactions as A
group by cust_id
having COUNT(cust_id)>10
order by no_of_trsn desc
------------------------------------------------------------------------------
/*Q8 What is the combined revenue earned from the “Electronics” & “Clothing”
	categories, from “Flagship stores”?
	ANS. 29946443.68
	*/
select ROUND(SUM(t.revenue_combined),2) as revenue_combined from (

                select b.prod_cat, SUM(a.total_amt) as revenue_combined from Transactions as A
                inner join prod_cat_info as B on
                a.prod_cat_code=b.prod_cat_code
                where (b.prod_cat='clothing' or b.prod_cat='electronics') and a.Store_type like 'flagship%'
                group by b.prod_cat) as T
-------------------------------------------------------------------------------------------------------
/*Q9 What is the total revenue generated from “Male” customers 
	in “Electronics” category? Output should display total revenue by 
	prod sub-cat.*/
select c.prod_subcat,SUM(b.total_amt) as total_revenue from Customer as a 
inner join Transactions as b
on a.customer_Id= b.cust_id 
inner join prod_cat_info as c 
on b.prod_cat_code = c.prod_cat_code and b.prod_subcat_code=c.prod_sub_cat_code
where a.Gender='m' and c.prod_cat='electronics'
group by c.prod_subcat
-----------------------------------------------------------------------------------------
--Q10 What is percentage of sales and returns by product sub category; 
--    display only top 5 sub categories in terms of sales?
select top 5
b.prod_subcat, (SUM(a.total_amt)/(select SUM(total_amt) from Transactions))*100 as percentage_sales, 
(SUM(CASE WHEN QTY <0 THEN abs(QTY) ELSE 0 END)/cast(abs(SUM(a.Qty)) as float))*100 AS PERCENTAGE_OF_RETURN
from Transactions as A
inner join prod_cat_info as B
on a.prod_cat_code=b.prod_cat_code and a.prod_subcat_code=b.prod_sub_cat_code
group by b.prod_subcat
order by SUM(total_amt) desc
---------------------------------------------------------------------------------------------------------
/*Q11 For all customers aged between 25 to 35 years find what is the 
	net total revenue generated by these consumers in last 30 days of transactions
	from max transaction date available in the data?*/
select c.cust_id, SUM(C.total_amt) AS REVENUE from Transactions as c
where c.cust_id in 
               (select customer_Id from Customer as A
               --inner join Transactions as B
               --on a.customer_Id=b.cust_id
               where DATEDIFF(Year,a.DOB, GETDATE()) between 25 and 35
               and c.tran_date BETWEEN DATEADD(DAY,-30,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
               	 AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions))
group by c.cust_id
------------------------------------------------------------------------------------------------------
--Q12 Which product category has seen the max value of returns in the last 3 
	--months of transactions?
	-- ANS. BAGS
select top 1
prod_cat, SUM(a.total_amt) as net_amount from Transactions as A
inner join prod_cat_info as B
on a.prod_cat_code=b.prod_cat_code and a.prod_subcat_code=b.prod_sub_cat_code
where a.total_amt<0 and
a.tran_date between DATEADD(month,-3,(select MAX(tran_date) from Transactions))
and (select MAX(tran_date) from Transactions)
group by prod_cat
order by net_amount desc
-------------------------------------------------------------------------------------------------------------
--Q13 Which store-type sells the maximum products; by value of sales amount and
	--by quantity sold?
-- ANS. ESHOP
select Store_type, SUM(total_amt) as total_sales, SUM(Qty) as total_qty from Transactions
group by Store_type
having SUM(total_amt)>= all (select SUM(total_amt) from Transactions group by Store_type)
and SUM(Qty)>= all (select SUM(Qty) from Transactions group by Store_type)
-------------------------------------------------------------------------------------------------------------
--Q14 What are the categories for which average revenue is above the overall average.
--ANS. BOOKS, CLOTHING AND ELECTRONICS
select prod_cat, AVG(total_amt) as avg_sales_amt from Transactions as A
inner join prod_cat_info as B
on  a.prod_cat_code =b.prod_cat_code and a.prod_subcat_code= b.prod_sub_cat_code
group by prod_cat
having AVG(total_amt)> (select AVG(total_amt) from Transactions)
----------------------------------------------------------------------------------------------------------------
--Q15 Find the average and total revenue by each subcategory for the categories 
--	which are among top 5 categories in terms of quantity sold.
select PROD_CAT, PROD_SUBCAT, AVG(TOTAL_AMT) AS AVERAGE_REV, SUM(TOTAL_AMT) AS REVENUE from Transactions as A
inner join prod_cat_info as B
on  a.prod_cat_code =b.prod_cat_code and a.prod_subcat_code= b.prod_sub_cat_code
where prod_cat in(
                  select top 5 prod_cat from Transactions as A
                  inner join prod_cat_info as B
                  on  a.prod_cat_code =b.prod_cat_code and a.prod_subcat_code= b.prod_sub_cat_code
                  group by prod_cat
                  order by SUM(Qty) desc)
group by prod_cat, prod_subcat

