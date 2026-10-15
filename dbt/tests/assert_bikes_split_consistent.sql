-- Les vélos mécaniques + électriques doivent égaler le total (alerte seulement, pas bloquant)
{{ config(severity='warn') }}

select *
from {{ ref('stg_velib__stations_status') }}
where mechanical_bikes + electric_bikes != bikes_available
