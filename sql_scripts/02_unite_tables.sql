/*
These commands transform the data to only contain the needed values and prepare it for being treated like timeseries data.
1. Create new table energy_units.
2. Copy necessary columns from solar_extended, wind_extended, biomass_extended and hydro_extended.
3. Delete rows that have not been approved (grid_operator_status)
4. Prepare data for easier time-series-analysis by duplicating rows that are no longer active and set the value to negative and the new timestamp
5. Set min date to 2000-01-01 as this project is only interested in the development from 2000 on.
*/

DROP TABLE IF EXISTS energy_units;

CREATE TABLE energy_units
(
    unit_nr                      VARCHAR(50),
    grid_operator_status         VARCHAR(3),
    municipality_key             VARCHAR(8),
    municipality                 VARCHAR(200),
    county                       VARCHAR(200),
    state                        VARCHAR(200),
    start_up_date                DATE,
    close_down_date              DATE,
    date                         DATE,
    pv_net_nominal_capacity      NUMERIC(20, 2),
    wind_net_nominal_capacity    NUMERIC(20, 2),
    biomass_net_nominal_capacity NUMERIC(20, 2),
    hydro_net_nominal_capacity   NUMERIC(20, 2)
);

INSERT INTO energy_units (unit_nr, grid_operator_status, municipality_key, municipality, county,
                          state, start_up_date,
                          close_down_date, date, hydro_net_nominal_capacity)
SELECT einheitmastrnummer,
       netzbetreiberpruefungstatus,
       gemeindeschluessel,
       gemeinde,
       landkreis,
       bundesland,
       inbetriebnahmedatum,
       datumendgueltigestilllegung,
       inbetriebnahmedatum,
       nettonennleistung
FROM hydro_extended;

INSERT INTO energy_units (unit_nr, grid_operator_status, municipality_key, municipality, county,
                          state, start_up_date,
                          close_down_date, date, wind_net_nominal_capacity)
SELECT einheitmastrnummer,
       netzbetreiberpruefungstatus,
       gemeindeschluessel,
       gemeinde,
       landkreis,
       bundesland,
       inbetriebnahmedatum,
       datumendgueltigestilllegung,
       inbetriebnahmedatum,
       nettonennleistung
FROM wind_extended;

INSERT INTO energy_units (unit_nr, grid_operator_status, municipality_key, municipality, county,
                          state, start_up_date,
                          close_down_date, date, biomass_net_nominal_capacity)
SELECT einheitmastrnummer,
       netzbetreiberpruefungstatus,
       gemeindeschluessel,
       gemeinde,
       landkreis,
       bundesland,
       inbetriebnahmedatum,
       datumendgueltigestilllegung,
       inbetriebnahmedatum,
       nettonennleistung
FROM biomass_extended;

INSERT INTO energy_units (unit_nr, grid_operator_status, municipality_key, municipality, county,
                          state, start_up_date,
                          close_down_date, date, pv_net_nominal_capacity)
SELECT einheitmastrnummer,
       netzbetreiberpruefungstatus,
       gemeindeschluessel,
       gemeinde,
       landkreis,
       bundesland,
       inbetriebnahmedatum,
       datumendgueltigestilllegung,
       inbetriebnahmedatum,
       nettonennleistung
FROM solar_extended;

-- Drop units that are not approved or disapproved
DELETE
FROM energy_units
WHERE grid_operator_status = '0';

ALTER TABLE energy_units
    DROP COLUMN grid_operator_status;


-- Duplicate rows with units not longer being active and make their values negative
INSERT INTO energy_units (unit_nr, municipality_key, municipality, county,
                          state, start_up_date,
                          close_down_date, date, pv_net_nominal_capacity, wind_net_nominal_capacity,
                          biomass_net_nominal_capacity, hydro_net_nominal_capacity)
SELECT unit_nr,
       municipality_key,
       municipality,
       county,
       state,
       start_up_date,
       close_down_date,
       date,
       -pv_net_nominal_capacity,
       -wind_net_nominal_capacity,
       -biomass_net_nominal_capacity,
       -hydro_net_nominal_capacity
FROM energy_units
WHERE close_down_date is not null;

-- set time to the minimum of 2000-01-01 as this is where we start displaying data (and timescaledb has problems otherwise)
UPDATE energy_units
SET date = '2000-01-01'
WHERE date < '2000-01-01';
