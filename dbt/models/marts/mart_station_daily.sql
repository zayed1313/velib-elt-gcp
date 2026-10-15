-- Indicateurs journaliers par station (stations en service uniquement)
select
    f.station_id,
    d.station_name,
    d.commune,
    f.snapshot_date,
    count(*)                                    as n_snapshots,
    avg(f.bikes_available)                      as avg_bikes_available,
    min(f.bikes_available)                      as min_bikes_available,
    max(f.bikes_available)                      as max_bikes_available,
    avg(cast(f.is_empty as int64))              as pct_time_empty,
    avg(cast(f.is_full as int64))               as pct_time_full,
    avg(f.occupancy_rate)                       as avg_occupancy_rate
from {{ ref('fct_station_availability') }} as f
inner join {{ ref('dim_stations') }} as d using (station_id)
where f.is_installed and f.is_renting
group by 1, 2, 3, 4
