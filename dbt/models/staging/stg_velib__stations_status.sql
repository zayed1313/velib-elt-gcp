with source as (

    select * from {{ source('raw', 'velib_stations_status') }}

),

renamed as (

    select
        stationcode                             as station_id,
        name                                    as station_name,
        upper(is_installed) = 'OUI'             as is_installed,
        upper(is_renting) = 'OUI'               as is_renting,
        upper(is_returning) = 'OUI'             as is_returning,
        capacity,
        numbikesavailable                       as bikes_available,
        mechanical                              as mechanical_bikes,
        ebike                                   as electric_bikes,
        numdocksavailable                       as docks_available,
        coordonnees_geo.lat                     as latitude,
        coordonnees_geo.lon                     as longitude,
        nom_arrondissement_communes             as commune,
        code_insee_commune                      as insee_code,
        duedate                                 as station_updated_at,
        snapshot_hour,
        ingested_at
    from source

),

ranked as (

    select
        *,
        row_number() over (
            partition by station_id, snapshot_hour
            order by ingested_at desc
        ) as rn
    from renamed

)

select * except (rn)
from ranked
where rn = 1
