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
