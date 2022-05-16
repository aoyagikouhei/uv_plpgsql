-- パラメーターをチェックする
-- 引数
--   p_integer_value_ary : 数値配列
--   p_text_value_ary : 文字列配列
--   p_invalid_flag : その他エラー判定
-- 戻り値
-- 例外
--   U0002 : 引数エラー
CREATE OR REPLACE FUNCTION uv_check_invalid_parameter(
  p_integer_value_ary BIGINT[] DEFAULT NULL
  ,p_text_value_ary TEXT[] DEFAULT NULL
  ,p_invalid_flag BOOLEAN DEFAULT FALSE
  ,p_message TEXT DEFAULT 'Invalid parameter'
) RETURNS VOID AS $FUNCTION$
DECLARE
  w_result BOOLEAN := FALSE;
BEGIN
  IF p_integer_value_ary IS NOT NULL THEN
    FOR i IN 1..array_length(p_integer_value_ary, 1) LOOP
      IF p_integer_value_ary[i] IS NULL OR p_integer_value_ary[i] < 1 THEN
        w_result := TRUE;
        EXIT;
      END IF;
    END LOOP;
  END IF;

  IF p_text_value_ary IS NOT NULL THEN
    FOR i IN 1..array_length(p_text_value_ary, 1) LOOP
      IF p_text_value_ary[i] IS NULL OR p_text_value_ary[i] = '' THEN
        w_result := TRUE;
        EXIT;
      END IF;
    END LOOP;
  END IF;

  IF w_result = TRUE OR p_invalid_flag = TRUE THEN
    RAISE SQLSTATE 'U0002' USING MESSAGE = p_message;
  END IF;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- 存在をチェックする
-- 引数
--   p_invalid_flag : エラー判定
--   p_key_ary : キー配列
--   p_value_ary : 値配列
--   p_message : メッセージ
-- 戻り値
-- 例外
--   U0003 : 存在しない
CREATE OR REPLACE FUNCTION uv_check_not_found(
  p_invalid_flag BOOLEAN DEFAULT FALSE
  ,p_key_ary TEXT[] DEFAULT NULL
  ,p_value_ary TEXT[] DEFAULT NULL
  ,p_message TEXT DEFAULT 'Not Found '
) RETURNS VOID AS $FUNCTION$
DECLARE
  w_result TEXT := '';
BEGIN
  IF p_invalid_flag = TRUE THEN
    RAISE SQLSTATE 'U0003' USING MESSAGE = p_message ||
      uv_make_error_parameters(p_key_ary, p_value_ary);
  END IF;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- エラーパラメーターを生成する
-- 引数
--   p_key_ary : キー配列
--   p_value_ary : 値配列
-- 戻り値
--   エラーパラメーター
CREATE OR REPLACE FUNCTION uv_make_error_parameters(
  p_key_ary TEXT[] DEFAULT NULL
  ,p_value_ary TEXT[] DEFAULT NULL
) RETURNS TEXT AS $FUNCTION$
DECLARE
  w_result TEXT := '';
BEGIN
  FOR i IN 1..array_length(p_key_ary, 1) LOOP
    w_result :=
      CASE WHEN w_result <> '' THEN w_result || ', '  ELSE '' END
      || p_key_ary[i] || ' = ' || p_value_ary[i];
  END LOOP;
  RETURN w_result;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- 存在をチェックする
-- 引数
--   p_table_nm : テーブル名
--   p_id : ID
--   p_column_nm : カラム名
-- 戻り値
-- 例外
--   U0002 : パラメータが不正
--   U0003 : 存在しない
CREATE OR REPLACE FUNCTION uv_check_exists(
  p_table_nm TEXT
  ,p_id BIGINT
  ,p_column_nm TEXT DEFAULT NULL
) RETURNS RECORD AS $FUNCTION$
DECLARE
  w_column TEXT := right(p_table_nm, -2) || '_id';
  w_row RECORD;
BEGIN
  PERFORM uv_check_invalid_parameter(ARRAY[p_id], ARRAY[p_table_nm]);

  IF p_column_nm IS NOT NULL THEN
    w_column := p_column_nm;
  END IF;

  EXECUTE $$
  SELECT
    t1.id
  FROM
    $$ || p_table_nm || $$ AS t1
  WHERE
    $$ || w_column || $$ = $1
  $$ INTO
    w_row
  USING
    p_id
  ;
  PERFORM uv_check_not_found(
    w_row.id IS NULL
    ,ARRAY[w_column]
    ,ARRAY[p_id]::TEXT[]
    ,'Not Found ' || p_table_nm || ' '
  );
  RETURN w_row;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- 配列が空かどうか判定する
-- 引数
--   p_array : 配列(型はなんでも可)
--   p_null_ok : p_array が NULL なのを許容する場合に TRUE を指定
-- 戻り値
--   TRUE : p_array が空、もしくは NULL (p_null_ok が TRUE でない場合)
--   FALSE : p_array に要素が1つ以上入っている
CREATE OR REPLACE FUNCTION uv_is_empty_array(
  p_array anyarray DEFAULT NULL
  ,p_null_ok BOOLEAN DEFAULT FALSE
) RETURNS BOOLEAN AS $FUNCTION$
BEGIN
  RETURN NOT (p_null_ok AND p_array IS NULL)
        AND array_length(p_array, 1) IS NULL;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- 名前付きパラメーターをチェックする
-- 引数
--   p_ary : 名前とブール値の配列
-- 戻り値
-- 例外
--   U0002 : 引数エラー
DROP TYPE IF EXISTS type_uv_check_parameter CASCADE;
CREATE TYPE type_uv_check_parameter AS (
  name TEXT
  ,value BOOLEAN
);
CREATE OR REPLACE FUNCTION uv_check_parameter(
  p_ary type_uv_check_parameter[] DEFAULT NULL
  ,p_message TEXT DEFAULT 'Invalid parameter '
) RETURNS VOID AS $FUNCTION$
DECLARE
  w_invalid_name_ary TEXT[] := ARRAY[]::TEXT[];
  w_length BIGINT := COALESCE(array_length(p_ary, 1), 0);
BEGIN
  -- 入力パラメーターチェック
  IF w_length = 0 THEN
    RAISE SQLSTATE 'U0002' USING MESSAGE = p_message || "ary is empty";
  END IF;

  FOR i IN 1..w_length LOOP
    IF p_ary[i].value IS TRUE THEN
      NULL;
    ELSE
      w_invalid_name_ary:= w_invalid_name_ary || p_ary[i].name;
    END IF;
  END LOOP;

  IF COALESCE(array_length(w_invalid_name_ary, 1), 0) > 0 THEN
    RAISE SQLSTATE 'U0002' USING MESSAGE = p_message || array_to_string(w_invalid_name_ary, ', ');
  END IF;
END;
$FUNCTION$ LANGUAGE plpgsql;