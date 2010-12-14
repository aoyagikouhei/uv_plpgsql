DROP TABLE IF EXISTS t_access_log CASCADE;
CREATE TABLE t_access_log
(
	insert_ts TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
	user_id BIGINT,
	url TEXT,
	user_agent TEXT,
	ip_address TEXT,
	params TEXT,
	bk TEXT
);

DROP TABLE IF EXISTS t_access_log_e01 CASCADE;
CREATE TABLE t_access_log_e01 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 1 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e02 CASCADE;
CREATE TABLE t_access_log_e02 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 2 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e03 CASCADE;
CREATE TABLE t_access_log_e03 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 3 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e04 CASCADE;
CREATE TABLE t_access_log_e04 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 4 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e05 CASCADE;
CREATE TABLE t_access_log_e05 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 5 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e06 CASCADE;
CREATE TABLE t_access_log_e06 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 6 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e07 CASCADE;
CREATE TABLE t_access_log_e07 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 7 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e08 CASCADE;
CREATE TABLE t_access_log_e08 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 8 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e09 CASCADE;
CREATE TABLE t_access_log_e09 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 9 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e10 CASCADE;
CREATE TABLE t_access_log_e10 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 10 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e11 CASCADE;
CREATE TABLE t_access_log_e11 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 11 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_e12 CASCADE;
CREATE TABLE t_access_log_e12 (
    CHECK (0 = date_part('year', insert_ts)::int % 2 AND 12 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o01 CASCADE;
CREATE TABLE t_access_log_o01 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 1 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o02 CASCADE;
CREATE TABLE t_access_log_o02 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 2 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o03 CASCADE;
CREATE TABLE t_access_log_o03 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 3 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o04 CASCADE;
CREATE TABLE t_access_log_o04 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 4 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o05 CASCADE;
CREATE TABLE t_access_log_o05 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 5 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o06 CASCADE;
CREATE TABLE t_access_log_o06 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 6 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o07 CASCADE;
CREATE TABLE t_access_log_o07 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 7 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o08 CASCADE;
CREATE TABLE t_access_log_o08 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 8 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o09 CASCADE;
CREATE TABLE t_access_log_o09 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 9 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o10 CASCADE;
CREATE TABLE t_access_log_o10 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 10 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o11 CASCADE;
CREATE TABLE t_access_log_o11 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 11 = date_part('month', insert_ts))
) INHERITS (t_access_log);

DROP TABLE IF EXISTS t_access_log_o12 CASCADE;
CREATE TABLE t_access_log_o12 (
    CHECK (1 = date_part('year', insert_ts)::int % 2 AND 12 = date_part('month', insert_ts))
) INHERITS (t_access_log);

CREATE OR REPLACE FUNCTION t_access_log_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF FALSE THEN
    NULL;
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 1 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e01 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 2 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e02 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 3 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e03 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 4 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e04 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 5 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e05 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 6 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e06 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 7 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e07 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 8 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e08 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 9 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e09 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 10 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e10 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 11 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e11 VALUES (NEW.*);
  ELSIF 0 = date_part('year', NEW.insert_ts)::int % 2 AND 12 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_e12 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 1 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o01 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 2 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o02 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 3 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o03 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 4 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o04 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 5 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o05 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 6 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o06 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 7 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o07 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 8 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o08 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 9 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o09 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 10 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o10 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 11 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o11 VALUES (NEW.*);
  ELSIF 1 = date_part('year', NEW.insert_ts)::int % 2 AND 12 = date_part('month', NEW.insert_ts) THEN
    INSERT INTO t_access_log_o12 VALUES (NEW.*);
  ELSE
    RAISE EXCEPTION 'Date out of range.  Fix the t_access_log_insert_trigger() function!';
  END IF;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_t_access_log_trigger ON t_access_log CASCADE;
CREATE TRIGGER insert_t_access_log_trigger
  BEFORE INSERT ON t_access_log
  FOR EACH ROW EXECUTE PROCEDURE t_access_log_insert_trigger();

CREATE OR REPLACE FUNCTION uv_insert_access_log(
	p_user_id BIGINT
	,p_url TEXT
	,p_user_agent TEXT
	,p_ip_address TEXT
	,p_params TEXT
) RETURNS BIGINT AS $$
DECLARE
	w_result BIGINT;
BEGIN
	INSERT INTO t_access_log (
		user_id
		,url
		,user_agent
		,ip_address
		,params
	) VALUES (
		p_user_id
		,p_url
		,p_user_agent
		,p_ip_address
		,p_params
	);
	GET DIAGNOSTICS w_result = ROW_COUNT;
	RETURN w_result;
END;
$$ LANGUAGE plpgsql;
