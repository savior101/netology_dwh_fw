CREATE SCHEMA stage;

CREATE SCHEMA dds;

CREATE SCHEMA dq;


-------------------- stage --------------------


-- stage.aircrafts
DROP TABLE IF EXISTS stage.aircraft;

CREATE TABLE stage.aircrafts
(
 aircraft_code bpchar(3) NULL,
 model         text NULL,
 range         int4 NULL
);

-- stage.airports
DROP TABLE IF EXISTS stage.airports;

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
DROP TABLE IF EXISTS stage.flights;

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
DROP TABLE IF EXISTS stage.tickets;

CREATE TABLE stage.tickets
(
 ticket_no      bpchar(13) NULL,
 book_ref       bpchar(6) NULL,
 passenger_id   varchar(20) NULL,
 passenger_name text NULL,
 contact_data   jsonb NULL
);

-- stage.ticket_flights
DROP TABLE IF EXISTS stage.ticket_flights;

CREATE TABLE stage.ticket_flights
(
 ticket_no       bpchar(13) NULL,
 flight_id       int4 NULL,
 fare_conditions varchar(10) NULL,
 amount          numeric(10,2) NOT NULL
);


-------------------- dds --------------------


-- dds.dim_aircrafts
DROP TABLE IF EXISTS dds.dim_aircrafts;

CREATE TABLE dds.dim_aircrafts
(
 aircraft_code bpchar(3) NOT NULL,
 model         text NOT NULL,
 range         int NOT NULL,
 start_ts      date NOT NULL,
 end_ts        date NOT NULL,
 is_current    boolean NOT NULL,
 CONSTRAINT PK_22 PRIMARY KEY ( aircraft_code )
);

-- dds.dim_airports
DROP TABLE IF EXISTS dds.dim_airports;

CREATE TABLE dds.dim_airports
(
 airport_code bpchar(3) NOT NULL,
 airport_name text NOT NULL,
 city         text NOT NULL,
 longitude    float8 NOT NULL,
 latitude     float8 NOT NULL,
 start_ts     date NOT NULL,
 end_ts       date NOT NULL,
 is_current   boolean NOT NULL,
 CONSTRAINT PK_27 PRIMARY KEY ( airport_code )
);

-- dds.dim_calendar
DROP TABLE IF EXISTS dds.dim_calendar;

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
DROP TABLE IF EXISTS dds.dim_passengers;

CREATE TABLE dds.dim_passengers
(
 id             varchar(20) NOT NULL,
 passenger_name text NOT NULL,
 phone          varchar(20) NULL,
 email          varchar(100) NULL,
 start_ts       date NOT NULL,
 end_ts         date NOT NULL,
 is_current     boolean NOT NULL,
 CONSTRAINT PK_17 PRIMARY KEY ( id )
);

-- dds.dim_tariffs
DROP TABLE IF EXISTS dds.dim_tariffs;

CREATE TABLE dds.dim_tariffs
(
 id              serial NOT NULL,
 fare_conditions varchar(10) NOT NULL,
 CONSTRAINT PK_34 PRIMARY KEY ( id )
);

-- dds.fact_flights
DROP TABLE IF EXISTS dds.fact_flights;

CREATE TABLE dds.fact_flights
(
 id                int NOT NULL,
 passenger_id      varchar(20) NOT NULL,
 tariff_id         int NOT NULL,
 departure_airport bpchar(3) NOT NULL,
 arrival_airport   bpchar(3) NOT NULL,
 aircraft_code     bpchar(3) NOT NULL,
 calendar_id       int NOT NULL,
 actual_departure  timestamptz NULL,
 actual_arrival    timestamptz NULL,
 delay_departure   interval second NULL,
 delay_arrival     interval second NULL,
 amount            numeric(10,2) NOT NULL,
 CONSTRAINT PK_38 PRIMARY KEY ( id ),
 CONSTRAINT FK_45 FOREIGN KEY ( passenger_id ) REFERENCES dds.dim_passengers ( id ),
 CONSTRAINT FK_52 FOREIGN KEY ( calendar_id ) REFERENCES dds.dim_calendar ( id ),
 CONSTRAINT FK_59 FOREIGN KEY ( aircraft_code ) REFERENCES dds.dim_aircrafts ( aircraft_code ),
 CONSTRAINT FK_62 FOREIGN KEY ( arrival_airport ) REFERENCES dds.dim_airports ( airport_code ),
 CONSTRAINT FK_65 FOREIGN KEY ( departure_airport ) REFERENCES dds.dim_airports ( airport_code ),
 CONSTRAINT FK_68 FOREIGN KEY ( tariff_id ) REFERENCES dds.dim_tariffs ( id )
);

CREATE INDEX FK_47 ON dds.fact_flights
(
 passenger_id
);

CREATE INDEX FK_54 ON dds.fact_flights
(
 calendar_id
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


-- dq.rejected_aicrafts
DROP TABLE IF EXISTS dq.rejected_aicrafts;

CREATE TABLE dq.rejected_aicrafts
(
 aicraft_code bpchar(3) NULL,
 model        text NULL,
 range        int4 NULL,
 rej_reason   text NULL,
 rej_dt       timestamp NULL
);

-- dq.rejected_airports
DROP TABLE IF EXISTS dq.rejected_airports;

CREATE TABLE dq.rejected_airports
(
 airport_code bpchar(3) NULL,
 airport_name text NULL,
 city         text NULL,
 longitude    float8 NULL,
 latitude     float8 NULL,
 timezone     text NULL,
 rej_reason   text NULL,
 rej_dt       timestamp NULL
);

-- dq.rejected_flights
DROP TABLE IF EXISTS dq.rejected_flights;

CREATE TABLE dq.rejected_flights
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
 actual_arrival      timestamptz NULL,
 rej_reason          text NULL,
 rej_dt              timestamp NULL
);

-- dq.rejected_tickets
DROP TABLE IF EXISTS dq.rejected_tickets;

CREATE TABLE dq.rejected_tickets
(
 ticket_no      varchar(13) NULL,
 book_ref       bpchar(6) NULL,
 passenger_id   varchar(20) NULL,
 passenger_name text NULL,
 contact_data   jsonb NULL,
 rej_reason     text NULL,
 rej_dt         timestamp NULL
);

-- dq.rejected_ticket_flights
DROP TABLE IF EXISTS dq.rejected_ticket_flights;

CREATE TABLE dq.rejected_ticket_flights
(
 ticket_no       varchar(13) NULL,
 ticket_id       int4 NULL,
 fare_conditions varchar(10) NULL,
 amount          numeric(10,2) NULL,
 rej_reason      text NULL,
 rej_dt          timestamp NULL
);




