-- Dernier état connu des attributs de chaque station
select
    station_id,
    station_name,
    latitude,
    longitude,
    commune,
    insee_code,
    capacity
from (
    select
        *,
        row_number() over (partition by station_id order by snapshot_hour desc) as rn
    from {{ ref('stg_velib__stations_status') }}
)
where rn = 1
