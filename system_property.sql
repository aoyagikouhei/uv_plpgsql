DROP TABLE IF EXISTS t_system_property CASCADE;
CREATE TABLE t_system_property
(
  system_property_id BIGSERIAL NOT NULL,
  system_property_name TEXT DEFAULT '' NOT NULL,
  system_property_value TEXT DEFAULT '' NOT NULL,
  ins_ts TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  upd_ts TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  bk TEXT,
  PRIMARY KEY(system_property_id),
  UNIQUE(system_property_name)
);

CREATE OR REPLACE FUNCTION uv_get_property(
  p_system_property_name TEXT
) RETURNS TEXT AS $$
DECLARE
  w_result TEXT;
BEGIN
  IF p_system_property_name IS NULL OR '' == p_system_property_name THEN
    RETURN NULL;
  END IF;
   
  SELECT
    system_property_value
  INTO
    w_result
  FROM
    t_system_property
  WHERE
    system_property_name = p_system_property_name;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION uv_set_property(
  p_system_property_name TEXT
  ,p_system_property_value TEXT
) RETURNS VOID AS $$
DECLARE
  w_now TIMESTAMP WITH TIME ZONE := 'now';
BEGIN
  IF p_system_property_name IS NULL OR '' == p_system_property_name THEN
    RETURN;
  END IF;
   
  UPDATE t_system_property SET
    system_property_value = p_system_property_value
    ,upd_ts =  w_now
  WHERE
    system_property_name = p_system_property_name;
  
  IF NOT FOUND THEN
    INSERT INTO t_system_property(
      system_property_name
      ,system_property_value
    ) VALUES (
      p_system_property_name
      ,p_system_property_value
    );
  END IF;
END;
$$ LANGUAGE plpgsql;
