
-- RFM Monthly
drop table if exists #rfm_monthly
select
    dt.YearMonth
    , rfm.CustomerID
    , rc.RFM_Category_Title
into #rfm_monthly
from
    DWSNDigiKala.customer.RFM as rfm
    join DWSNDigiKala.customer.RFM_Categories as rc on rfm.RFM_Category_Id = rc.RFM_Category_Id
    join DWSNDigiKala.dbo.vwDateAll dt on dt.DateId = rfm.DateId
group by
    dt.YearMonth
    , rfm.CustomerID
    , rc.RFM_Category_Title

drop table if exists #corrected_RFM_monthly
select
    coalesce(ma.duplicated_user_id , rm.CustomerID) customer_user_id
    , rm.YearMonth
    , rm.RFM_Category_Title
into #corrected_RFM_monthly
from
    #rfm_monthly rm
    left join ODSDigikala.digikala.merged_accounts ma on rm.CustomerID = ma.main_user_id


drop table if exists #monthly_buying_customers
select
    cts.CustomerID
    , dt.YearMonth
into #monthly_buying_customers
from
    DWSNDigiKala.Sales.CartToShipTable cts
    join DWSNDigiKala.dbo.vwDateAll dt on dt.DateId = cts.CartFinalizeDateId
where
    dt.YearMonth >= (select min(r.YearMonth) from #rfm_monthly r)
    and cts.DigiStatus = 70
    and cts.site_id = 1
group by
      cts.CustomerID
    , dt.YearMonth

select
    rfm.YearMonth
    , rfm.RFM_Category_Title
    , case when mbc.CustomerID is not null then 1 else 0 end as buying_customer
    , count(rfm.customer_user_id) customer_count
from
    #corrected_RFM_monthly rfm
    left join #monthly_buying_customers mbc on rfm.YearMonth = mbc.YearMonth and rfm.customer_user_id = mbc.CustomerID
group by
    rfm.YearMonth
    , rfm.RFM_Category_Title
    , case when mbc.CustomerID is not null then 1 else 0 end

select
    mbc.YearMonth
    , count(mbc.CustomerID)
from #monthly_buying_customers mbc
group by
        mbc.YearMonth
order by mbc.YearMonth


