select
    transaction_sk,
    amount
from {{ ref('stg_transactions') }}
where amount < 0
