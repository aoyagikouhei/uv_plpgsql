-- ORDER BYを生成する
-- 引数
--   p_src_kbn_ary : 元となる区分値の配列
--   p_column_ary : カラムの配列
--   p_dst_kbn_ary : 適用する区分値の配列
--   p_asc_flag_ary : TRUEの時ASCの配列
--   p_offset : オフセット
--   p_limit : リミット
--   p_nulls_ary : 区分値毎にNULL値を先頭または末尾に配置したい場合に使用する（'FIRST' or 'LAST'）
-- 戻り値
--   エスケープされた文字列
DROP FUNCTION IF EXISTS dyn_order_by(text[],text[],text[],BOOLEAN[],BIGINT,BIGINT);
CREATE OR REPLACE FUNCTION dyn_order_by(
  p_src_kbn_ary TEXT[]
  ,p_column_ary TEXT[]
  ,p_dst_kbn_ary TEXT[]
  ,p_asc_flag_ary BOOLEAN[]
  ,p_offset BIGINT DEFAULT 0
  ,p_limit BIGINT DEFAULT NULL
  ,p_nulls_ary TEXT[] DEFAULT '{}'
) RETURNS TEXT AS $$
DECLARE
  w_prefix TEXT;
  w_column TEXT;
  w_postfix TEXT;
  w_src_count BIGINT := array_length(p_src_kbn_ary, 1);
  w_dst_count BIGINT := array_length(p_dst_kbn_ary, 1);
BEGIN
  -- LIMITとOFFSETの構築
  w_postfix := 
    CASE WHEN p_offset IS NOT NULL AND p_offset > 0 
      THEN ' OFFSET ' || p_offset::TEXT ELSE '' END ||
    CASE WHEN p_limit IS NOT NULL 
      THEN ' LIMIT ' || p_limit::TEXT ELSE '' END || ' ';

  IF 
    p_src_kbn_ary IS NULL 
    OR p_dst_kbn_ary IS NULL 
    OR w_src_count IS NULL
    OR w_src_count = 0 
    OR w_dst_count IS NULL
    OR w_dst_count = 0 
  THEN
    RETURN w_postfix;
  END IF;

  -- ORDER BYの構築
  w_prefix := '';
  FOR i IN 1..w_dst_count LOOP
    -- 対象カラムの検索
    w_column := NULL;
    FOR j IN 1..w_src_count LOOP
      IF p_src_kbn_ary[j] = p_dst_kbn_ary[i] THEN
        w_column = p_column_ary[j];
        EXIT;
      END IF;
    END LOOP;
    -- カラムの構築
    IF w_column IS NOT NULL THEN
      IF w_prefix <> '' THEN
        w_prefix := w_prefix || ', ';
      ELSE
        w_prefix := ' ORDER BY ';
      END IF;
      w_prefix := w_prefix || w_column ||
        CASE WHEN p_asc_flag_ary[i] THEN ' ASC ' ELSE ' DESC ' END;
      IF array_length(p_nulls_ary,1) >= i THEN
        w_prefix := w_prefix || ' NULLS ' || p_nulls_ary[i];
      END IF;
    END IF;
  END LOOP;

  RETURN w_prefix || w_postfix;
END;
$$ LANGUAGE plpgsql;

-- テーブルで一意の値を生成する
-- 引数
--   p_table_name : テーブル名
--   p_column_name : カラム名
--   p_try_count : 試行回数
--   p_length : 長さ
--   p_length : 生成する文字列の長さ
--   p_source : 生成する文字列の要素
--   p_condition : 条件
-- 戻り値
--   ランダムな文字列
CREATE OR REPLACE FUNCTION dyn_random_string(
  p_table_name TEXT DEFAULT NULL
  ,p_column_name TEXT DEFAULT NULL
  ,p_try_count INT DEFAULT 10
  ,p_length INT DEFAULT 20
  ,p_source TEXT DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  ,p_prefix TEXT DEFAULT ''
  ,p_condition TEXT DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
  w_target TEXT;
  w_value TEXT;
  w_sql TEXT;
BEGIN
  FOR i IN 1..p_try_count LOOP
    w_value := NULL;
    w_target := concat(p_prefix, uv_string_random(p_length, p_source));
    w_sql := 
      'SELECT ' || p_column_name ||' FROM ' || p_table_name || 
      ' WHERE ' || p_column_name || ' = $1';
    IF p_condition IS NOT NULL AND p_condition <> '' THEN
      w_sql := w_sql || ' AND ' || p_condition;
    END IF;
    EXECUTE
      w_sql
    INTO
      w_value
    USING
      w_target
    ;
    IF w_value IS NULL THEN
      RETURN w_target;
    END IF;
  END LOOP;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 同じ値があるかチェック
-- 引数
--   p_table_name : テーブル名
--   p_column_name : カラム名
--   p_value : チェックする値
--   p_id_column_name : IDのカラム名
--   p_id : IDの値
--   p_condition : 付加する絞り込み
-- 戻り値
--   同じ値がある場合はtrue
CREATE OR REPLACE FUNCTION dyn_check_same_value(
  p_table_name TEXT
  ,p_column_name TEXT
  ,p_value TEXT
  ,p_id_column_name TEXT DEFAULT NULL
  ,p_id BIGINT DEFAULT NULL
  ,p_condition TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $FUNCTION$
DECLARE
  w_sql TEXT;
  w_value TEXT;
BEGIN
  w_sql := $$
    SELECT
      $$ || p_column_name || $$
    FROM
      $$ || p_table_name || $$
    WHERE
      $$ || p_column_name || $$ = $1
  $$
  ;
  IF p_condition IS NOT NULL THEN
    w_sql := w_sql || ' AND ' || p_condition;
  END IF;

  IF p_id_column_name IS NULL OR p_id IS NULL THEN
    EXECUTE w_sql 
    INTO
      w_value
    USING
      p_value
    ;
  ELSE
    EXECUTE w_sql || $$
      AND $$ || p_id_column_name || $$ <> $2
    $$
    INTO
      w_value
    USING
      p_value
      ,p_id
    ;
  END IF;
  RETURN w_value IS NOT NULL;
END;
$FUNCTION$ LANGUAGE plpgsql;

-- シーケンスをクリアーする
-- 引数
--   p_key : キー
--   p_postfix : ポストフィックス
-- 戻り値
--   無し
-- 例外
CREATE OR REPLACE FUNCTION dyn_set_clear_sequence(
  p_key TEXT
  ,p_postfix TEXT DEFAULT '_'
) RETURNS VOID AS $FUNCTION$
DECLARE
  w_max BIGINT;
BEGIN
  -- 最大のID取得
  EXECUTE $$
    SELECT
      MAX($$ || p_key || $$_id)
      FROM
        t_$$ || p_key || $$
  $$ INTO
    w_max
  ;
  CASE WHEN w_max IS NULL THEN
    -- 最大値が空 (テーブルにデータがない) = シーケンスを初期化（1から開始)
    EXECUTE $$
      SELECT SETVAL($1, 1, false)
    $$ USING
      't_' || p_key || p_postfix || p_key || '_id_seq'
    ;
  ELSE
    -- 最大IDを設定
    EXECUTE $$
      SELECT SETVAL($1 ,$2)
    $$ USING
      't_' || p_key || p_postfix || p_key || '_id_seq'
      ,w_max
    ;
  END CASE;
END;
$FUNCTION$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS type_dyn_set_save_garbage CASCADE;
CREATE TYPE type_dyn_set_save_garbage AS (
  id BIGINT
);

-- スキーマに移動
-- 引数
--   p_target_id : 対象レコードのID
--   p_table_nm : テーブル名
--   p_src_schema_nm : 元スキーマ名
--   p_dst_schema_nm : 先スキーマ名
--   p_now : 削除時刻
--   p_sp : 起動プログラム名
--   p_caller_id : 削除ユーザID
-- 戻り値
--   なし
-- 例外
--   U0002 : パラメータが不正
--   U0003 : データが存在しない
CREATE OR REPLACE FUNCTION dyn_set_save_garbage(
  p_target_id BIGINT DEFAULT NULL
  ,p_table_nm TEXT DEFAULT NULL
  ,p_src_schema_nm TEXT DEFAULT NULL
  ,p_dst_schema_nm TEXT DEFAULT NULL
  ,p_now TIMESTAMPTZ DEFAULT NULL
  ,p_sp TEXT DEFAULT NULL
  ,p_caller_id BIGINT DEFAULT NULL
) RETURNS SETOF type_dyn_set_save_garbage AS $FUNCTION$
DECLARE
  -- 処理したID
  w_id BIGINT;

  -- 現在時刻
  w_now TIMESTAMPTZ := COALESCE(p_now, now());

  -- IDカラム名
  w_id_column_nm TEXT := SUBSTR(p_table_nm, 3) || '_id';

  -- 元スキーマー名
  w_src_schema_nm TEXT := COALESCE(p_src_schema_nm, 'public');

  -- 移動元テーブル名
  w_src_table_nm TEXT := w_src_schema_nm || '.' ||  p_table_nm;

  -- 先スキーマー名
  w_dst_schema_nm TEXT := COALESCE(p_dst_schema_nm, 'garbage');

  -- 移動先テーブル名
  w_dst_table_nm TEXT := w_dst_schema_nm || '.' ||  p_table_nm;

  -- テーブルカラムカンマ区切り配列
  w_table_schema_columns TEXT;
BEGIN
  -- パラメータチェック
  PERFORM
    uv_check_invalid_parameter(
      ARRAY[p_target_id]
      ,ARRAY[p_table_nm]
    );

  -- カラム名を取得
  SELECT
    array_to_string(array_agg(CAST(t1.column_name AS TEXT)), ',') AS column_nm
  INTO
    w_table_schema_columns
  FROM
    information_schema.columns AS t1
  WHERE
    t1.table_name = p_table_nm
    AND t1.table_schema = 'public'
  GROUP BY
    t1.table_name
  ;

  IF w_table_schema_columns IS NULL THEN
    RAISE SQLSTATE 'U0002';
  END IF;

  -- レコードをスキーマに移動
  EXECUTE $$
  INSERT INTO $$ || w_dst_table_nm || $$ (
    $$ || w_table_schema_columns || $$
  )
  SELECT
    $$ || w_table_schema_columns || $$
  FROM
    $$ || w_src_table_nm || $$ AS t1
  WHERE
    t1.$$ || w_id_column_nm || $$ = $1
  RETURNING
    $$ || w_id_column_nm || $$
  $$ INTO
    w_id
  USING
    p_target_id
  ;

  -- 存在チェック
  IF w_id IS NULL THEN
    RAISE SQLSTATE 'U0003';
  END IF;
  
  -- 時間、対応者、対応プログラム修正
  EXECUTE $$
  UPDATE $$ || w_dst_table_nm || $$ SET
    $$ || w_dst_schema_nm || $$_id = $2
    ,$$ || w_dst_schema_nm || $$_ts = $3
    ,$$ || w_dst_schema_nm || $$_sp = $4
  WHERE
    $$ || w_id_column_nm || $$ = $1
  $$ USING
    w_id
    ,p_caller_id
    ,w_now
    ,p_sp
  ;

  -- レコードを削除
  EXECUTE $$
  DELETE FROM $$ || w_src_table_nm || $$ WHERE
    $$ || w_id_column_nm || $$ = $1;
  $$ USING
    p_target_id
  ;

  RETURN QUERY SELECT p_target_id;
END;
$FUNCTION$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS type_dyn_search_delete CASCADE;
CREATE TYPE type_dyn_search_delete AS (
  id BIGINT
);

-- 探して削除
-- 引数
--   p_id : ID
--   p_table_name : テーブル名
--   p_sp : 実行プログラム
--   p_caller_id : 実行者
--   p_now : 現在時刻
--   p_src_schema_name_ary : 探すスキーマー名配列
-- 戻り値 
--   ユーザID
CREATE OR REPLACE FUNCTION dyn_search_delete(
  p_id BIGINT DEFAULT NULL
  ,p_table_name TEXT DEFAULT NULL
  ,p_sp TEXT DEFAULT NULL
  ,p_caller_id BIGINT DEFAULT NULL
  ,p_now TIMESTAMPTZ DEFAULT NULL
  ,p_src_schema_name_ary TEXT[] DEFAULT NULL
  ,p_dst_schema_name TEXT DEFAULT NULL
) RETURNS SETOF type_dyn_search_delete AS $FUNCTION$
DECLARE
  w_now TIMESTAMPTZ := COALESCE(p_now, NOW());
  w_sp TEXT := COALESCE(p_sp, 'dyn_search_delete');
  w_src_schema_name TEXT;
  w_id BIGINT;

  -- IDカラム名
  w_id_column_name TEXT := SUBSTR(p_table_name, 3) || '_id';

  -- スキーマー配列
  p_src_schema_name_ary TEXT[] := COALESCE(p_src_schema_name_ary, ARRAY['public', 'history']);

  -- 移動先スキーマー名
  w_dst_schema_name TEXT := COALESCE(p_dst_schema_name, 'garbage');
BEGIN
  FOR i IN 1..array_length(p_src_schema_name_ary, 1) LOOP
    w_src_schema_name := p_src_schema_name_ary[i];
    EXECUTE $$
    SELECT
      t1.$$ || w_id_column_name || $$
    FROM
      $$ || w_src_schema_name || '.' || p_table_name || $$ AS t1
    WHERE
      t1.$$ || w_id_column_name || $$ = $1
    $$
    INTO
      w_id
    USING
      p_id
    ;
    IF w_id IS NOT NULL THEN
      EXIT;
    END IF;
  END LOOP;
  IF w_id IS NULL THEN
    RAISE SQLSTATE 'U0003' USING MESSAGE = 'table = ' || p_table_name || ',id = ' || p_id; 
  END IF;

  -- 削除実行
  PERFORM * FROM dyn_set_save_garbage(
    p_target_id := p_id
    ,p_table_nm := p_table_name
    ,p_src_schema_nm := w_src_schema_name
    ,p_dst_schema_nm := w_dst_schema_name
    ,p_now := w_now
    ,p_sp := w_sp
    ,p_caller_id := p_caller_id
  );
  
  RETURN QUERY SELECT p_id;
END;
$FUNCTION$ LANGUAGE plpgsql;
