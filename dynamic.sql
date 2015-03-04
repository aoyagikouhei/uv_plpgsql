-- ORDER BYを生成する
-- 引数
--   p_src_kbn_ary : 元となる区分値の配列
--   p_column_ary : カラムの配列
--   p_dst_kbn_ary : 適用する区分値の配列
--   p_asc_flag_ary : TRUEの時ASCの配列
--   p_offset : オフセット
--   p_limit : リミット
-- 戻り値
--   エスケープされた文字列
CREATE OR REPLACE FUNCTION dyn_order_by(
  p_src_kbn_ary TEXT[]
  ,p_column_ary TEXT[]
  ,p_dst_kbn_ary TEXT[]
  ,p_asc_flag_ary BOOLEAN[]
  ,p_offset BIGINT DEFAULT 0
  ,p_limit BIGINT DEFAULT NULL
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
-- 戻り値
--   ランダムな文字列
CREATE OR REPLACE FUNCTION dyn_random_string(
  p_table_name TEXT
  ,p_column_name TEXT
  ,p_try_count INT DEFAULT 10
  ,p_length INT DEFAULT 10
  ,p_source TEXT DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
) RETURNS TEXT AS $$
DECLARE
  w_target TEXT;
  w_value TEXT;
BEGIN
  FOR i IN 1..p_try_count LOOP
    w_value := NULL;
    w_target := uv_string_random(p_length, p_source);
    EXECUTE 
      'SELECT ' || p_column_name ||' FROM ' || p_table_name || 
      ' WHERE ' || p_column_name || ' = $1'
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

