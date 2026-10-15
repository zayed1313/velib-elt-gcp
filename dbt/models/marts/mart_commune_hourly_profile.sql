-- Profil moyen par commune et par heure de la journée (heure de Paris) : base du heatmap Looker Studio
select
    d.commune,
    extract(hour from datetime(f.snapshot_hour, 'Europe/Paris'))    as hour_of_day,
    count(distinct f.station_id)                                    as n_stations,
    avg(f.bikes_available)                                          as avg_bikes_available,
    avg(f.occupancy_rate)                                           as avg_occupancy_rate,
    avg(cast(f.is_empty as int64))                                  as pct_stations_empty,
    avg(cast(f.is_full as int64))                                   as pct_stations_full
from {{ ref('fct_station_availability') }} as f
inner join {{ ref('dim_stations') }} as d using (station_id)
where f.is_installed and f.is_renting
group by 1, 2
