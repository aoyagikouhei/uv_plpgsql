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
 
