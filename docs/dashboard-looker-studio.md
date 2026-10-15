# Dashboard Looker Studio

Looker Studio est gratuit. Le dashboard se construit dans l'interface (pas de code) à partir des marts dbt.

## Connexion
1. https://lookerstudio.google.com → **Créer → Source de données → BigQuery**.
2. Projet → dataset `velib_marts` → ajoute les tables `mart_station_daily`, `mart_commune_hourly_profile` et `dim_stations`.

## Pages suggérées
**1. Vue d'ensemble**
- Scorecards : nombre de stations, `avg_occupancy_rate`, `pct_time_empty` moyen.
- Courbe temporelle : `avg_bikes_available` par `snapshot_date`.

**2. Profil horaire (heatmap)**
- Source : `mart_commune_hourly_profile`.
- Tableau croisé : lignes = `commune`, colonnes = `hour_of_day`, métrique = `avg_occupancy_rate`, mise en forme conditionnelle.

**3. Stations en tension**
- Source : `mart_station_daily`, jointe à `dim_stations` (latitude/longitude).
- Tableau trié par `pct_time_empty` décroissant, filtre sur la date et la commune.
- Carte à bulles : champ géographique construit avec `CONCAT(latitude, ",", longitude)` (type Latitude, Longitude).

## Pour le README
Ajoute une capture d'écran dans `docs/img/dashboard.png` et référence-la depuis le README, plus le lien public du rapport.
