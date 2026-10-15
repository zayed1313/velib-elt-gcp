{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={'field': 'snapshot_date', 'data_type': 'date'}
    )
}}

select
    station_id,
    snapshot_hour,
    date(snapshot_hour)                         as snapshot_date,
    capacity,
    bikes_available,
    mechanical_bikes,
    electric_bikes,
    docks_available,
    is_installed,
    is_renting,
    is_returning,
    safe_divide(bikes_available, capacity)      as occupancy_rate,
    bikes_available = 0                         as is_empty,
    docks_available = 0                         as is_full
from {{ ref('stg_velib__stations_status') }}

{% if is_incremental() %}
where date(snapshot_hour) >= date_sub(current_date(), interval 2 day)
{% endif %}
