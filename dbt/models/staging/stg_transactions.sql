{{
    config(
        materialized='table',
        engine='MergeTree()',
        order_by='(us_state, transaction_time, merch)'
    )
}}

with source_rows as (
    select
        transaction_time,
        merch,
        cat_id,
        amount,
        name_1,
        name_2,
        gender,
        us_state,
        lat,
        lon,
        merchant_lat,
        merchant_lon,
        target
    from {{ source('transactions_db', 'transactions') }}
)

select
    {{ dbt_utils.generate_surrogate_key([
        'transaction_time',
        'merch',
        'cat_id',
        'amount',
        'name_1',
        'name_2',
        'us_state',
        'lat',
        'lon',
        'merchant_lat',
        'merchant_lon',
        'target'
    ]) }} as transaction_sk,
    cast(transaction_time as DateTime) as transaction_time,
    toDate(transaction_time) as transaction_date,
    toHour(transaction_time) as transaction_hour,
    cast({{ dbt_date.day_of_week('toDate(transaction_time)') }} as UInt8) as day_of_week,
    cast({{ dbt_date.day_name('toDate(transaction_time)', short=false) }} as String) as day_name,
    {{ dbt_date.week_start('toDate(transaction_time)') }} as week_start_date,
    merch,
    cat_id,
    cast(amount as Float64) as amount,
    cast({{ amount_bucket('amount') }} as String) as amount_bucket,
    {{ is_large_amount('amount') }} as is_large_transaction,
    name_1,
    name_2,
    gender,
    us_state,
    cast(lat as Float64) as lat,
    cast(lon as Float64) as lon,
    cast(merchant_lat as Float64) as merchant_lat,
    cast(merchant_lon as Float64) as merchant_lon,
    round(geoDistance(lon, lat, merchant_lon, merchant_lat) / 1000, 3) as distance_km,
    {{ dbt_utils.generate_surrogate_key([
        'name_1',
        'name_2',
        'us_state',
        'lat',
        'lon'
    ]) }} as customer_id,
    cast(target as UInt8) as target,
    cast(target as UInt8) as is_fraud
from source_rows
