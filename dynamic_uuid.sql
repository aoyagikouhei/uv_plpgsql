
DROP TYPE IF EXISTS type_dyn_set_save_garbage CASCADE;
CREATE TYPE type_dyn_set_save_garbage AS (
  uuid UUID
);

-- スキーマに移動
-- 引数
--   p_target_uuid : 対象レコードのUUID
--   p_src_table_name : 元テーブル名
--   p_dst_table_name : 先テーブル名
--   p_src_schema_name : 元スキーマ名
--   p_dst_schema_name : 先スキーマ名
--   p_now : 削除時刻
--   p_sp : 起動プログラム名
--   p_caller_uuid : 削除ユーザーUUID
-- 戻り値
--   なし
-- 例外
--   U0002 : パラメータが不正
--   U0003 : データが存在しない
CREATE OR REPLACE FUNCTION dyn_set_save_garbage(
  p_target_uuid UUID DEFAULT NULL
  ,p_src_table_name TEXT DEFAULT NULL
  ,p_dst_table_name TEXT DEFAULT NULL
  ,p_src_schema_name TEXT DEFAULT NULL
  ,p_dst_schema_name TEXT DEFAULT NULL
  ,p_now TIMESTAMPTZ DEFAULT NULL
  ,p_sp TEXT DEFAULT NULL
  ,p_caller_uuid UUID DEFAULT NULL
  ,p_uuid_column_name TEXT DEFAULT NULL
  ,p_delete_column_name TEXT DEFAULT NULL
  ,p_time_postfix TEXT DEFAULT NULL
  ,p_program_name_postfix TEXT DEFAULT NULL
) RETURNS SETOF type_dyn_set_save_garbage AS $FUNCTION$
DECLARE
  -- 処理したUUID
  w_uuid UUID;

  -- 現在時刻
  w_now TIMESTAMPTZ := COALESCE(p_now, now());

  -- UUIDカラム名
  w_uuid_column_name TEXT := COALESCE(p_uuid_column_name, SUBSTR(p_src_table_name, 3) || '_uuid');

  -- 元スキーマー名
  w_src_schema_name TEXT := COALESCE(p_src_schema_name, 'public');

  -- 移動元テーブル名
  w_src_table_name TEXT := w_src_schema_name || '."' || p_src_table_name || '"';

  -- 先スキーマー名
  w_dst_schema_name TEXT := COALESCE(p_dst_schema_name, 'garbage');

  -- 削除カラム名
  w_delete_column_name TEXT := COALESCE(p_delete_column_name, w_dst_schema_name);

  -- 移動先テーブル名
  w_dst_table_name TEXT := w_dst_schema_name || '."' || COALESCE(p_dst_table_name, p_src_table_name) || '"';

  -- 時間カラム末尾
  w_time_postfix TEXT := COALESCE(p_time_postfix, 'at');

  -- プログラム名カラム末尾
  w_program_name_postfix TEXT := COALESCE(p_program_name_postfix, 'pg');

  -- テーブルカラムカンマ区切り配列
  w_table_schema_columns TEXT;
BEGIN
  -- パラメータチェック
  PERFORM
    uv_check_invalid_parameter(
      p_text_value_ary := ARRAY[p_src_table_name]
      ,p_invalid_flag := p_target_uuid IS NULL
    );

  -- カラム名を取得
  SELECT
    array_to_string(array_agg(CAST(t1.column_name AS TEXT)), ',') AS column_name
  INTO
    w_table_schema_columns
  FROM
    information_schema.columns AS t1
  WHERE
    t1.table_name = p_src_table_name
    AND t1.table_schema = 'public'
  GROUP BY
    t1.table_name
  ;

  IF w_table_schema_columns IS NULL THEN
    RAISE SQLSTATE 'U0002';
  END IF;

  -- レコードをスキーマに移動
  EXECUTE $$
  INSERT INTO $$ || w_dst_table_name || $$ (
    $$ || w_table_schema_columns || $$
  )
  SELECT
    $$ || w_table_schema_columns || $$
  FROM
    $$ || w_src_table_name || $$ AS t1
  WHERE
    t1.$$ || w_uuid_column_name || $$ = $1
  RETURNING
    $$ || w_uuid_column_name || $$
  $$ INTO
    w_uuid
  USING
    p_target_uuid
  ;

  -- 存在チェック
  IF w_uuid IS NULL THEN
    RAISE SQLSTATE 'U0003';
  END IF;
  
  -- 時間、対応者、対応プログラム修正
  EXECUTE $$
  UPDATE $$ || w_dst_table_name || $$ SET
    $$ || w_delete_column_name || $$_uuid = $2
    ,$$ || w_delete_column_name || $$_$$ || w_time_postfix || $$ = $3
    ,$$ || w_delete_column_name || $$_$$ || w_program_name_postfix || $$ = $4
  WHERE
    $$ || w_uuid_column_name || $$ = $1
  $$ USING
    w_uuid
    ,p_caller_uuid
    ,w_now
    ,p_sp
  ;

  -- レコードを削除
  EXECUTE $$
  DELETE FROM $$ || w_src_table_name || $$ WHERE
    $$ || w_uuid_column_name || $$ = $1;
  $$ USING
    p_target_uuid
  ;

  RETURN QUERY SELECT p_target_uuid;
END;
$FUNCTION$ LANGUAGE plpgsql;
