CREATE SCHEMA IF NOT EXISTS stage;

CREATE SCHEMA IF NOT EXISTS dds;

CREATE SCHEMA IF NOT EXISTS dq;

CREATE SCHEMA IF NOT EXISTS metadata;


-------------------- stage --------------------


-- stage.aircrafts
DROP TABLE IF EXISTS stage.aircrafts CASCADE;

CREATE TABLE stage.aircrafts
(
 aircraft_code bpchar(3) NULL,
 model         text NULL,
 range         int4 NULL
);

-- stage.airports
DROP TABLE IF EXISTS stage.airports CASCADE;

CREATE TABLE stage.airports
(
 airport_code bpchar(3) NULL,
 airport_name text NULL,
 city         text NULL,
 longitude    float8 NULL,
 latitude     float8 NULL,
 timezone     text NULL
);

-- stage.flights
DROP TABLE IF EXISTS stage.flights CASCADE;

CREATE TABLE stage.flights
(
 flight_id           int NULL,
 flight_no           bpchar(6) NULL,
 scheduled_departure timestamptz NULL,
 scheduled_arrival   timestamptz NULL,
 departure_airport   bpchar(3) NULL,
 arrival_airport     bpchar(3) NULL,
 status              varchar(20) NULL,
 aircraft_code       bpchar(3) NULL,
 actual_departure    timestamptz NULL,
 actual_arrival      timestamptz NULL
);

-- stage.tickets
DROP TABLE IF EXISTS stage.tickets CASCADE;

CREATE TABLE stage.tickets
(
 ticket_no      bpchar(13) NULL,
 book_ref       bpchar(6) NULL,
 passenger_id   varchar(20) NULL,
 passenger_name text NULL,
 contact_data   jsonb NULL
);

-- stage.ticket_flights
DROP TABLE IF EXISTS stage.ticket_flights CASCADE;

CREATE TABLE stage.ticket_flights
(
 ticket_no       bpchar(13) NULL,
 flight_id       int4 NULL,
 fare_conditions varchar(10) NULL,
 amount          numeric(10,2) NULL
);


-------------------- dds --------------------


-- dds.dim_aircrafts
DROP TABLE IF EXISTS dds.dim_aircrafts CASCADE;

CREATE TABLE dds.dim_aircrafts
(
 id			   serial,
 aircraft_code bpchar(3) NOT NULL,
 model         text NOT NULL,
 range         int NOT NULL,
 start_ts      date NOT NULL,
 end_ts        date NOT NULL,
 is_current    boolean NOT NULL DEFAULT TRUE,
 version       int2 NOT NULL DEFAULT 1,
 CONSTRAINT PK_22 PRIMARY KEY ( id )
);

-- ?????? ???????????????????? ???????????? ?????????????? ???????????????????? ?? ?????????????? SCD2 "??????????????" ???????????? ?? id = 0
INSERT INTO dds.dim_aircrafts (id, aircraft_code, model, "range", start_ts, end_ts, is_current, version)
VALUES (0, '', '', 1, now()::date, now()::date, TRUE, 1);

-- dds.dim_airports
DROP TABLE IF EXISTS dds.dim_airports CASCADE;

CREATE TABLE dds.dim_airports
(
 id			  serial,
 airport_code bpchar(3) NOT NULL,
 airport_name text NOT NULL,
 city         text NOT NULL,
 longitude    float8 NOT NULL,
 latitude     float8 NOT NULL,
 start_ts     date NOT NULL,
 end_ts       date NOT NULL,
 is_current    boolean NOT NULL DEFAULT TRUE,
 version       int2 NOT NULL DEFAULT 1,
 CONSTRAINT PK_27 PRIMARY KEY ( id )
);

-- ?????? ???????????????????? ???????????? ?????????????? ???????????????????? ?? ?????????????? SCD2 "??????????????" ???????????? ?? id = 0
INSERT INTO dds.dim_airports (id, airport_code, airport_name, city, latitude, longitude, start_ts, end_ts, is_current, version)
VALUES (0, '', '', '', 0.00, 0.00, now()::date, now()::date, TRUE, 1);

-- dds.dim_calendar
DROP TABLE IF EXISTS dds.dim_calendar CASCADE;

CREATE TABLE dds.dim_calendar
(
 id          int NOT NULL,
 date        date NOT NULL,
 day         int NOT NULL,
 week_number int NOT NULL,
 month       int NOT NULL,
 year        int NOT NULL,
 week_day    int NOT NULL,
 holiday     int NOT NULL,
 CONSTRAINT PK_6 PRIMARY KEY ( id )
);

-- dds.dim_passengers
DROP TABLE IF EXISTS dds.dim_passengers CASCADE;

CREATE TABLE dds.dim_passengers
(
 passenger_id	varchar(20) NOT NULL,
 passenger_name text NOT NULL,
 phone          varchar(20) NULL,
 email          varchar(100) NULL,
 CONSTRAINT PK_17 PRIMARY KEY ( passenger_id )
);

-- dds.dim_tariffs
DROP TABLE IF EXISTS dds.dim_tariffs CASCADE;

CREATE TABLE dds.dim_tariffs
(
 id              serial NOT NULL,
 fare_conditions varchar(10) NOT NULL,
 CONSTRAINT PK_34 PRIMARY KEY ( id )
);

-- dds.fact_flights
DROP TABLE IF EXISTS dds.fact_flights CASCADE;

CREATE TABLE dds.fact_flights
(
 id                int NOT NULL,
 passenger_id      varchar(20) NOT NULL,
 ticket_no		   bpchar(13) NOT NULL,
 tariff_id         int NOT NULL,
 departure_airport bpchar(3) NOT NULL,
 arrival_airport   bpchar(3) NOT NULL,
 aircraft_code     bpchar(3) NOT NULL,
 actual_departure  timestamptz NULL,
 a_d_calendar_id   int NULL,
 actual_arrival    timestamptz NULL,
 a_a_calendar_id   int NULL,
 delay_departure   int8 NULL,
 delay_arrival     int8 NULL,
 amount            numeric(10,2) NOT NULL,
 CONSTRAINT PK_38 PRIMARY KEY ( id, passenger_id ),
 CONSTRAINT FK_45 FOREIGN KEY ( passenger_id ) REFERENCES dds.dim_passengers ( passenger_id ),
 CONSTRAINT FK_52 FOREIGN KEY ( a_d_calendar_id ) REFERENCES dds.dim_calendar ( id ),
 CONSTRAINT FK_152 FOREIGN KEY ( a_a_calendar_id ) REFERENCES dds.dim_calendar ( id ),
 CONSTRAINT FK_68 FOREIGN KEY ( tariff_id ) REFERENCES dds.dim_tariffs ( id )
);

CREATE INDEX FK_47 ON dds.fact_flights
(
 passenger_id
);

CREATE INDEX FK_54 ON dds.fact_flights
(
 a_d_calendar_id
);

CREATE INDEX FK_154 ON dds.fact_flights
(
 a_a_calendar_id
);

CREATE INDEX FK_61 ON dds.fact_flights
(
 aircraft_code
);

CREATE INDEX FK_64 ON dds.fact_flights
(
 arrival_airport
);

CREATE INDEX FK_67 ON dds.fact_flights
(
 departure_airport
);

CREATE INDEX FK_70 ON dds.fact_flights
(
 tariff_id
);


-------------------- dq --------------------


-- dq.rejected_aircrafts
DROP TABLE IF EXISTS dq.rejected_aircrafts CASCADE;

CREATE TABLE dq.rejected_aircrafts
(
 aircraft_code text NULL,
 model         text NULL,
 range         int NULL,
 rej_reason    text NULL,
 rej_dt        timestamp NULL
);

-- dq.rejected_airports
DROP TABLE IF EXISTS dq.rejected_airports CASCADE;

CREATE TABLE dq.rejected_airports
(
 airport_code text NULL,
 airport_name text NULL,
 city         text NULL,
 longitude    float8 NULL,
 latitude     float8 NULL,
 rej_reason   text NULL,
 rej_dt       timestamp NULL
);

-- dq.rejected_flights
DROP TABLE IF EXISTS dq.rejected_flights CASCADE;

CREATE TABLE dq.rejected_flights
(
 id                int NULL,
 passenger_id      text NULL,
 ticket_no		   text NOT NULL,
 tariff_id         int NULL,
 departure_airport text NULL,
 arrival_airport   text NULL,
 aircraft_code     text NULL,
 actual_departure  timestamptz NULL,
 a_d_calendar_id   int NULL,
 actual_arrival    timestamptz NULL,
 a_a_calendar_id   int NULL,
 delay_departure   int8 NULL,
 delay_arrival     int8 NULL,
 amount            numeric(10,2) NULL,
 rej_reason        text NULL,
 rej_dt            timestamp NULL
);

-- dq.rejected_tickets
DROP TABLE IF EXISTS dq.rejected_passengers CASCADE;

CREATE TABLE dq.rejected_passengers
(
 passenger_id	text NULL,
 passenger_name text NULL,
 phone          text NULL,
 email          text NULL,
 rej_reason     text NULL,
 rej_dt         timestamp NULL
);

-- dq.rejected_tariffs
DROP TABLE IF EXISTS dq.rejected_tariffs CASCADE;

CREATE TABLE dq.rejected_tariffs
(
 fare_conditions text NULL,
 rej_reason      text NULL,
 rej_dt          timestamp NULL
);


-------------------- metadata --------------------


-- metadata.bookings
CREATE TABLE metadata.bookings
(
	source_connection_name varchar(50) not null,
	source_sql_st text not null,
	target_connection_name varchar(50) not null,
	target_schema varchar(50) not null,
	target_table varchar(50) not null,
	target_table_field varchar(100) not null,
	target_stream_field varchar(100) not null,
	target_truncate_table int2 not null,
	ord int2,
	primary key (source_connection_name, target_connection_name, target_schema, target_table, target_table_field)
);


-------------------- ?????????????????? dds.dim_calendar --------------------

WITH dates AS (
    SELECT dd::date AS dt
    FROM generate_series
            ('2016-01-01'::timestamp
            , '2016-12-31'::timestamp
            , '1 day'::interval) dd
)
INSERT INTO dds.dim_calendar
SELECT
    to_char(dt, 'YYYYMMDD')::int AS id,
    dt AS date,
    date_part('isodow', dt)::int AS day,
    date_part('week', dt)::int AS week_number,
    date_part('month', dt)::int AS month,
    date_part('isoyear', dt)::int AS year,
    (date_part('isodow', dt)::smallint BETWEEN 1 AND 5)::int AS week_day,
    (to_char(dt, 'YYYYMMDD')::int IN (
        20160101,
        20160102,
        20160103,
        20160104,
        20160105,
        20160106,
        20160107,
        20160108,
        20160222,
        20160223,
        20160307,
        20160308,
        20160501,
        20160502,
        20160503,
        20160509,
        20160612,
        20160613,
        20161104,
        20170101
))::int AS holiday
FROM dates
ORDER BY dt;


-------------------- ?????????????????? metadata.bookings --------------------

insert into metadata.bookings (
	source_connection_name
	, source_sql_st
	, target_connection_name
	, target_schema
	, target_table
	, target_table_field
	, target_stream_field
	, target_truncate_table
	, ord)
values
	(
		'booking_source'
		, 'select aircraft_code, model, range from bookings.aircrafts order by aircraft_code'
		, 'dwh'
		, 'stage'
		, 'aircrafts'
		, 'aircraft_code'
		, 'aircraft_code'
		, 1
		, 1
	),
	(
		'booking_source'
		, 'select aircraft_code, model, range from bookings.aircrafts order by aircraft_code'
		, 'dwh'
		, 'stage'
		, 'aircrafts'
		, 'model'
		, 'model'
		, 1
		, 2
	),
	(
		'booking_source'
		, 'select aircraft_code, model, range from bookings.aircrafts order by aircraft_code'
		, 'dwh'
		, 'stage'
		, 'aircrafts'
		, 'range'
		, 'range'
		, 1
		, 3
	),
	(
		'booking_source'
		, 'select airport_code, airport_name, city, longitude, latitude, timezone from bookings.airports order by airport_code'
		, 'dwh'
		, 'stage'
		, 'airports'
		, 'airport_code'
		, 'airport_code'
		, 1
		, 1
	),
	(
		'booking_source'
		, 'select airport_code, airport_name, city, longitude, latitude, timezone from bookings.airports order by airport_code'
		, 'dwh'
		, 'stage'
		, 'airports'
		, 'airport_name'
		, 'airport_name'
		, 1
		, 2
	),
	(
		'booking_source'
		, 'select airport_code, airport_name, city, longitude, latitude, timezone from bookings.airports order by airport_code'
		, 'dwh'
		, 'stage'
		, 'airports'
		, 'city'
		, 'city'
		, 1
		, 3
	),
	(
		'booking_source'
		, 'select airport_code, airport_name, city, longitude, latitude, timezone from bookings.airports order by airport_code'
		, 'dwh'
		, 'stage'
		, 'airports'
		, 'longitude'
		, 'longitude'
		, 1
		, 4
	),
	(
		'booking_source'
		, 'select airport_code, airport_name, city, longitude, latitude, timezone from bookings.airports order by airport_code'
		, 'dwh'
		, 'stage'
		, 'airports'
		, 'latitude'
		, 'latitude'
		, 1
		, 5
	),
	(
		'booking_source'
		, 'select airport_code, airport_name, city, longitude, latitude, timezone from bookings.airports order by airport_code'
		, 'dwh'
		, 'stage'
		, 'airports'
		, 'timezone'
		, 'timezone'
		, 1
		, 6
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'flight_id'
		, 'flight_id'
		, 1
		, 1
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'flight_no'
		, 'flight_no'
		, 1
		, 2
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'scheduled_departure'
		, 'scheduled_departure'
		, 1
		, 3
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'scheduled_arrival'
		, 'scheduled_arrival'
		, 1
		, 4
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'departure_airport'
		, 'departure_airport'
		, 1
		, 5
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'arrival_airport'
		, 'arrival_airport'
		, 1
		, 6
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'status'
		, 'status'
		, 1
		, 7
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'aircraft_code'
		, 'aircraft_code'
		, 1
		, 8
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'actual_departure'
		, 'actual_departure'
		, 1
		, 9
	),
	(
		'booking_source'
		, 'select flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival from bookings.flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id'
		, 'dwh'
		, 'stage'
		, 'flights'
		, 'actual_arrival'
		, 'actual_arrival'
		, 1
		, 10
	),
	(
		'booking_source'
		, 'select ticket_no, flight_id, fare_conditions, amount from bookings.ticket_flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id, ticket_no'
		, 'dwh'
		, 'stage'
		, 'ticket_flights'
		, 'ticket_no'
		, 'ticket_no'
		, 1
		, 1
	),
	(
		'booking_source'
		, 'select ticket_no, flight_id, fare_conditions, amount from bookings.ticket_flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id, ticket_no'
		, 'dwh'
		, 'stage'
		, 'ticket_flights'
		, 'flight_id'
		, 'flight_id'
		, 1
		, 2
	),
	(
		'booking_source'
		, 'select ticket_no, flight_id, fare_conditions, amount from bookings.ticket_flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id, ticket_no'
		, 'dwh'
		, 'stage'
		, 'ticket_flights'
		, 'fare_conditions'
		, 'fare_conditions'
		, 1
		, 3
	),
	(
		'booking_source'
		, 'select ticket_no, flight_id, fare_conditions, amount from bookings.ticket_flights where flight_id > ${MAX_FLIGHT_ID} order by flight_id, ticket_no'
		, 'dwh'
		, 'stage'
		, 'ticket_flights'
		, 'amount'
		, 'amount'
		, 1
		, 4
	),
	(
		'booking_source'
		, 'select ticket_no, book_ref, passenger_id, passenger_name, contact_data from bookings.tickets where ticket_no::bigint > ${MAX_TICKET_NO} order by ticket_no::bigint'
		, 'dwh'
		, 'stage'
		, 'tickets'
		, 'ticket_no'
		, 'ticket_no'
		, 1
		, 1
	),
	(
		'booking_source'
		, 'select ticket_no, book_ref, passenger_id, passenger_name, contact_data from bookings.tickets where ticket_no::bigint > ${MAX_TICKET_NO} order by ticket_no::bigint'
		, 'dwh'
		, 'stage'
		, 'tickets'
		, 'book_ref'
		, 'book_ref'
		, 1
		, 2
	),
	(
		'booking_source'
		, 'select ticket_no, book_ref, passenger_id, passenger_name, contact_data from bookings.tickets where ticket_no::bigint > ${MAX_TICKET_NO} order by ticket_no::bigint'
		, 'dwh'
		, 'stage'
		, 'tickets'
		, 'passenger_id'
		, 'passenger_id'
		, 1
		, 3
	),
	(
		'booking_source'
		, 'select ticket_no, book_ref, passenger_id, passenger_name, contact_data from bookings.tickets where ticket_no::bigint > ${MAX_TICKET_NO} order by ticket_no::bigint'
		, 'dwh'
		, 'stage'
		, 'tickets'
		, 'passenger_name'
		, 'passenger_name'
		, 1
		, 4
	),
	(
		'booking_source'
		, 'select ticket_no, book_ref, passenger_id, passenger_name, contact_data from bookings.tickets where ticket_no::bigint > ${MAX_TICKET_NO} order by ticket_no::bigint'
		, 'dwh'
		, 'stage'
		, 'tickets'
		, 'contact_data'
		, 'contact_data'
		, 1
		, 5
	)
;

