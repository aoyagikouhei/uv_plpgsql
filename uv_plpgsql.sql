-- 
-- The MIT License
-- 
-- Copyright(C)　2009 青柳公右平. All rights reserved. 
--
-- 以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。
--
-- 上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。
--
-- ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。 

-- 文字列が設定されているか判定する
-- 引数
--   p_src : 判定したい文字列
-- 戻り値
--   文字列が設定されている場合はtrue
CREATE OR REPLACE FUNCTION uv_is_set(
  p_src text
) RETURNS boolean AS $$
DECLARE
BEGIN
  RETURN p_src IS NOT NULL AND '' <> p_src;
END;
$$ LANGUAGE plpgsql;

-- 文字列が数値か判定する
-- 引数
--   p_src : 判定したい文字列
--   p_min : 最小値
--   p_max : 最大値
-- 戻り値
--   文字列が数値の場合かつ範囲内の場合はtrue
CREATE OR REPLACE FUNCTION uv_is_number(
  p_src text
  ,p_min bigint DEFAULT -9223372036854775808
  ,p_max bigint DEFAULT 9223372036854775807
) RETURNS boolean AS $$
DECLARE
  w_value bigint;
BEGIN
  IF NOT uv_is_set(p_src) THEN
    RETURN FALSE;
  END IF;
  BEGIN
    w_value := p_src::bigint;
    IF p_min <= w_value AND w_value <= p_max THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RETURN FALSE;
  END;
END;
$$ LANGUAGE plpgsql;

-- 整数の文字埋め
-- 引数
--   p_value : 整数
--   p_keta : 生成する桁数
--   p_padding : 埋める文字
-- 戻り値
--   文字埋めされた文字列
CREATE OR REPLACE FUNCTION uv_padding_integer(
  p_value bigint
  ,p_keta int
  ,p_padding text
) RETURNS text AS $$
DECLARE
  w_result text := '';
BEGIN
  IF p_value IS NULL 
    OR p_value < 0
    OR p_keta IS NULL 
    OR p_keta < 1 
    OR NOT uv_is_set(p_padding) 
    OR 1 < char_length(p_padding) 
  THEN
    RETURN NULL;
  END IF;
  w_result := p_value::text;
  FOR i IN 1..p_keta - char_length(w_result) LOOP
    w_result := p_padding || w_result;
  END LOOP;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 文字列から時間を作る
-- 引数
--   p_year : 年
--   p_month : 月
--   p_day : 日
--   p_hour : 時
--   p_minute : 分
--   p_second : 秒
--   p_micro : マイクロ秒
-- 戻り値
--   作成された時間
CREATE OR REPLACE FUNCTION uv_make_time(
  p_year text DEFAULT '0001'
  ,p_month text DEFAULT '01'
  ,p_day text DEFAULT '01'
  ,p_hour text DEFAULT '00'
  ,p_minute text DEFAULT '00'
  ,p_second text DEFAULT '00'
  ,p_micro text DEFAULT '000000'
) RETURNS timestamp with time zone AS $$
DECLARE
  w_micro text;
BEGIN
  IF uv_is_number(p_year, -4713, 294276)
    AND uv_is_number(p_month, 1, 12)
    AND uv_is_number(p_day, 1, 31)
    AND uv_is_number(p_hour, 0, 23)
    AND uv_is_number(p_minute, 0, 59)
    AND uv_is_number(p_second, 0, 59)
    AND uv_is_number(p_micro, 0, 999999)
  THEN
    w_micro := uv_padding_integer(p_micro::bigint, 6, '0');
    RETURN p_year || '-' || p_month || '-' || p_day || ' ' || p_hour || ':' || p_minute || ':' || p_second || '.' || w_micro;
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ランダムな文字列を作る
-- 引数
--   p_length : 生成する文字列の長さ
--   p_source : 生成する文字列の要素
-- 戻り値
--   ランダムな文字列
CREATE OR REPLACE FUNCTION uv_string_random(
  p_length int DEFAULT 10
  ,p_source text DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
) RETURNS text AS $$
DECLARE
  w_result text := '';
  w_index int := 0;
BEGIN
  IF p_length IS NULL or p_length < 1 or p_source IS NULL or p_source = '' THEN
    RETURN NULL;
  END IF;
 
  FOR i IN 1..p_length LOOP
    w_index := floor(random() * length(p_source))::integer + 1;
    w_result := w_result || substring(p_source, w_index, 1);
  END LOOP;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 時間の加減を行う
-- 引数
--   p_ts : 基準となる時間
--   p_count : 加減する数
--   p_unit : 時間の単位（'microsecond', 'second', 'minute', 'hour', 'day', 'month', 'year'）
-- 戻り値
--   ランダムな文字列
CREATE OR REPLACE FUNCTION uv_add_time(
  p_ts timestamp with time zone
  ,p_count int
  ,p_unit text)
RETURNS timestamp with time zone AS $$
DECLARE
  w_interval interval;
  w_result timestamp with time zone;
BEGIN
  IF p_ts IS NULL 
    OR p_count IS NULL
    OR p_unit IS NULL
    OR p_unit NOT IN ('year', 'month', 'day', 'hour', 'minute', 'second', 'microsecond')
  THEN
    RETURN NULL;
  END IF;
  w_interval := p_count::text || ' ' || p_unit;
  SELECT
    p_ts + w_interval
  INTO
    w_result;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 16進数文字列を数字に変換する
-- 引数
--   p_hex : 16進数文字列
-- 戻り値
--   引数で表現される数
CREATE OR REPLACE FUNCTION uv_to_int_from_hex(
  p_hex text
)RETURNS bigint AS $$
DECLARE
  w_hex text;
  w_result bigint := 0;
  w_base text := '0123456789ABCDEF';
  w_index int;
BEGIN
  IF NOT uv_is_set(p_hex) THEN
    RETURN NULL;
  END IF;
  
  w_hex := upper(p_hex);
  FOR i IN 1..char_length(p_hex) LOOP
    w_index := position(substring(w_hex, i, 1) IN w_base);
    IF 0 = w_index THEN
      RETURN NULL;
    END IF;
    w_result := w_result * 16 + w_index - 1;
  END LOOP;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 月初日を求める
-- 引数
--   p_ts : 基準の時間
-- 戻り値
--   月初日
CREATE OR REPLACE FUNCTION uv_get_first_day_of_month(
  p_ts timestamp with time zone
) RETURNS timestamp with time zone AS $$
DECLARE
BEGIN
  IF p_ts IS NULL THEN
      RETURN NULL;
  END IF;
  RETURN date_trunc('month', p_ts);
END;
$$ LANGUAGE plpgsql;

-- 月末日を求める
-- 引数
--   p_ts : 基準の時間
-- 戻り値
--   月末日
CREATE OR REPLACE FUNCTION uv_get_last_day_of_month(
  p_ts timestamp with time zone
) RETURNS timestamp with time zone AS $$
DECLARE
BEGIN
  IF p_ts IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN uv_add_time(
    uv_add_time(uv_get_first_day_of_month(p_ts), 1, 'month'),
    -1, 'day');
END;
$$ LANGUAGE plpgsql;

-- 数値を3桁区切り
-- 引数
--   p_src : 3桁区切りしたい数値
-- 戻り値
--   3桁区切りされた文字列
CREATE OR REPLACE FUNCTION uv_to_three_split(
  p_src text
) RETURNS text AS $$
DECLARE
  w_work text;
  w_length int;
  w_result text := '';
  w_sign text := '';
BEGIN
  IF NOT uv_is_set(p_src) THEN
    RETURN NULL;
  END IF;
  IF '-' = substring(p_src from 1 for 1) THEN
    w_sign := '-';
    w_work := substring(p_src from 2 for char_length(p_src) - 1);
  ELSE
    w_work := p_src;
  END IF;
  w_length := char_length(w_work);
  FOR i IN 0..w_length-1 LOOP
    IF 0 = i % 3 AND 0 <> i THEN
      w_result := ',' || w_result;
    END IF;
    w_result := substring(w_work from w_length - i for 1) || w_result;
  END LOOP;
  RETURN w_sign || w_result;
END;
$$ LANGUAGE plpgsql;

-- カレンダーを作る
-- 引数
--   p_year : 年
--   p_month : 月
-- 戻り値
--   カレンダー
CREATE OR REPLACE FUNCTION uv_make_calendar (
  p_year text
  ,p_month text DEFAULT '00'
) RETURNS TABLE(r_date timestamp with time zone)
AS $$
DECLARE
  w_start_ts timestamp with time zone;
  w_end_ts timestamp with time zone;
BEGIN
  IF '00' = p_month THEN
    w_start_ts := uv_make_time(p_year);
    w_end_ts := uv_add_time(w_start_ts, 1, 'year');
  ELSE
    w_start_ts := uv_make_time(p_year, p_month);
    w_end_ts := uv_add_time(w_start_ts, 1, 'month');
  END IF;
  IF w_start_ts IS NULL THEN
    RETURN;
  END IF;
  WHILE w_start_ts < w_end_ts LOOP
    RETURN QUERY SELECT w_start_ts;
    w_start_ts := uv_add_time(w_start_ts, 1, 'day');
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 文字列を指定した方法で変換する
-- 引数
--   p_src : 入力文字列
--   p_from_ary : 変換前文字配列
--   p_to_ary : 変換後文字配列
--   p_from : 変換前文字列
--   p_to : 変換後文字列
-- 戻り値
--   変換した文字列
CREATE OR REPLACE FUNCTION uv_to_moji_henkan(
  p_src text,
  p_from_ary text[],
  p_to_ary text[],
  p_from text,
  p_to text
) RETURNS text AS $$
DECLARE
  w_result text := p_src;
BEGIN
  IF NOT uv_is_set(p_src) THEN
    RETURN p_src;
  END IF;
  IF p_from_ary IS NOT NULL THEN
    FOR i in 1..array_length(p_from_ary, 1) LOOP
      w_result := replace(w_result, p_from_ary[i], p_to_ary[i]);
    END LOOP;
  END IF;
  IF p_from IS NOT NULL THEN
    w_result := translate(w_result, p_from, p_to);
  END IF;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 半角カナを全角カナに変換する
-- 引数
--   p_src : 入力文字列
-- 戻り値
--   変換した文字列
CREATE OR REPLACE FUNCTION uv_to_zenkaku_kana(
  p_src text
) RETURNS text AS $$
DECLARE
  w_from_ary text[] := '{"ｳﾞ", "ｶﾞ", "ｷﾞ", "ｸﾞ", "ｹﾞ", "ｺﾞ", "ｻﾞ", "ｼﾞ", "ｽﾞ", "ｾﾞ", "ｿﾞ", "ﾀﾞ", "ﾁﾞ", "ﾂﾞ", "ﾃﾞ", "ﾄﾞ", "ﾊﾞ", "ﾋﾞ", "ﾌﾞ", "ﾍﾞ", "ﾎﾞ", "ﾊﾟ", "ﾋﾟ", "ﾌﾟ", "ﾍﾟ", "ﾎﾟ"}';
  w_to_ary text[] := '{"ヴ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", "ジ", "ズ", "ゼ", "ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ"}';
  w_from text := 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝｧｨｩｪｫｯｬｭｮﾞﾟ｡｢｣､･ｰ';
  w_to text := 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンァィゥェォッャュョ゛゜。「」、・ー';
BEGIN
  RETURN uv_to_moji_henkan(p_src, w_from_ary, w_to_ary, w_from, w_to);
END;
$$ LANGUAGE plpgsql;

-- 全角カナを半角カナに変換する
-- 引数
--   p_src : 入力文字列
-- 戻り値
--   変換した文字列
CREATE OR REPLACE FUNCTION uv_to_hankaku_kana(
  p_src text
) RETURNS text AS $$
DECLARE
  w_from_ary text[] := '{"ヴ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", "ジ", "ズ", "ゼ", "ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ"}';
  w_to_ary text[] := '{"ｳﾞ", "ｶﾞ", "ｷﾞ", "ｸﾞ", "ｹﾞ", "ｺﾞ", "ｻﾞ", "ｼﾞ", "ｽﾞ", "ｾﾞ", "ｿﾞ", "ﾀﾞ", "ﾁﾞ", "ﾂﾞ", "ﾃﾞ", "ﾄﾞ", "ﾊﾞ", "ﾋﾞ", "ﾌﾞ", "ﾍﾞ", "ﾎﾞ", "ﾊﾟ", "ﾋﾟ", "ﾌﾟ", "ﾍﾟ", "ﾎﾟ"}';
  w_from text := 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンァィゥェォッャュョ゛゜。「」、・ー';
  w_to text := 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝｧｨｩｪｫｯｬｭｮﾞﾟ｡｢｣､･ｰ';
BEGIN
  RETURN uv_to_moji_henkan(p_src, w_from_ary, w_to_ary, w_from, w_to);
END;
$$ LANGUAGE plpgsql;

-- 引数の合計を求める
-- 引数
--   p_params : 任意個の値
-- 戻り値
--   引数の合計
CREATE OR REPLACE FUNCTION uv_sum(
  p_params VARIADIC numeric[]
) RETURNS numeric AS $$
DECLARE
  w_result numeric := 0;
BEGIN
  FOR i IN 1..array_length(p_params, 1) LOOP
    IF p_params[i] IS NOT NULL THEN
      w_result := w_result + p_params[i];
    END IF;
  END LOOP;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 引数の平均を求める
-- 引数
--   p_params : 任意個の値
-- 戻り値
--   引数の平均
CREATE OR REPLACE FUNCTION uv_avg(
  p_params VARIADIC numeric[]
) RETURNS numeric AS $$
DECLARE
BEGIN
  RETURN uv_sum(VARIADIC p_params) / array_length(p_params, 1);
END;
$$ LANGUAGE plpgsql;

-- 行番号を入れ替える
-- 引数
--   p_table_name : テーブル名
--   p_line_column : 行番号カラム名
--   p_from : 移動元行番号
--   p_to : 移動先行番号
--   p_where : 絞込み条件
CREATE OR REPLACE FUNCTION uv_lineno_update (
  p_table_name text
  ,p_line_column text
  ,p_from int
  ,p_to int
  ,p_where text DEFAULT ''
) RETURNS void AS $$
DECLARE
  w_command text;
BEGIN
  if NOT uv_is_set(p_table_name)
    OR NOT uv_is_set(p_line_column)
    OR p_from IS NULL
    OR p_from < 1
    OR p_to IS NULL
    OR p_from < 1
    OR p_from = p_to
  THEN
    RETURN;
  END IF;
 
  w_command := 'UPDATE ' || quote_ident(p_table_name) || ' SET ' ||
    quote_ident(p_line_column) || ' = CASE WHEN ' || quote_ident(p_line_column) || ' = ' || p_from::text || ' THEN ' || p_to::text;
 
  IF p_from < p_to THEN
    w_command := w_command || ' WHEN ' || quote_ident(p_line_column) || ' > ' || p_from::text ||
      ' AND ' ||  quote_ident(p_line_column) || ' <= ' || p_to::text || ' THEN ' || quote_ident(p_line_column) || ' - 1';
  ELSE
    w_command := w_command || ' WHEN ' || quote_ident(p_line_column) || ' >= ' || p_to::text ||
      ' AND ' ||  quote_ident(p_line_column) || ' < ' || p_from::text || ' THEN ' || quote_ident(p_line_column) || ' + 1';
  END IF;
 
  w_command := w_command || ' ELSE ' || quote_ident(p_line_column) || ' END';
 
  IF uv_is_set(p_where) THEN
    w_command := w_command || ' WHERE ' || p_where;
  END IF;
  
  EXECUTE w_command;
END;
$$ LANGUAGE plpgsql;

-- 行番号を削除する
-- 引数
--   p_table_name : テーブル名
--   p_line_column : 行番号カラム名
--   p_delete_column : 削除カラム名
--   p_lineno : 行番号
--   p_where : 絞込み条件
CREATE OR REPLACE FUNCTION uv_lineno_delete (
  p_table_name text
  ,p_line_column text
  ,p_delete_column text
  ,p_lineno int
  ,p_where text DEFAULT ''
) RETURNS void AS $$
DECLARE
  w_command text;
BEGIN
  if NOT uv_is_set(p_table_name)
    OR NOT uv_is_set(p_line_column)
    OR NOT uv_is_set(p_delete_column)
    OR p_lineno IS NULL
    OR p_lineno < 1
  THEN
    RETURN;
  END IF;
 
  w_command := 'UPDATE ' || quote_ident(p_table_name) || ' SET ' ||
    quote_ident(p_delete_column) || ' = CASE WHEN ' || quote_ident(p_line_column) ||
    ' = ' || p_lineno::text || ' THEN 1 ELSE ' || quote_ident(p_delete_column) || ' END, ' ||
    quote_ident(p_line_column) || ' = CASE WHEN ' || quote_ident(p_line_column) ||
    ' > ' || p_lineno::text || ' THEN ' ||  quote_ident(p_line_column) || ' -1 ELSE ' || quote_ident(p_line_column) || ' END';
 
  IF uv_is_set(p_where) THEN
    w_command := w_command || ' WHERE ' || p_where;
  END IF;
  
  EXECUTE w_command;
END;
$$ LANGUAGE plpgsql;

-- 文字列を反転する
-- 引数
--   p_src : 元の文字列
-- 戻り値
--   反転した文字列
CREATE OR REPLACE FUNCTION uv_str_reverse(
  p_src text
) RETURNS text AS $$
DECLARE
  p_length int;
  w_result text = '';
BEGIN
  IF p_src IS NULL THEN
    RETURN p_src;
  END IF;
  
  p_length := length(p_src);
  IF 2 > p_length THEN
    RETURN p_src;
  END IF;
  
  FOR i IN REVERSE p_length..1 LOOP
    w_result := w_result || substr(p_src, i, 1);
  END LOOP;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 文字列に含まれる文字列の位置を調べる
-- 引数
--   p_src : 元の文字列
--   p_target : 含まれているか判定する文字列
--   p_index : 開始位置(1から始まるインデックス)
--   p_reverse : 逆から調べる
-- 戻り値
--   発見した位置。見つからない場合0
CREATE OR REPLACE FUNCTION uv_strpos(
  p_src text
  ,p_target text
  ,p_index int DEFAULT 1
  ,p_reverse boolean DEFAULT false
) RETURNS int AS $$
DECLARE
  w_tmp text;
  w_result int;
  w_length int;
BEGIN
  IF p_src IS NULL or 
    '' = p_src or
    p_target IS NULL or
    '' = p_target or
    p_reverse IS NULL or
    p_index IS NULL or
    p_index < 1 or
    length(p_src) < p_index
  THEN
    RETURN 0;
  END IF;
  
  IF p_reverse THEN
    w_tmp := uv_str_reverse(p_src);
  ELSE
    w_tmp := p_src;
  END IF;
  
  w_length := length(w_tmp);
  w_tmp := substr(w_tmp, p_index, w_length - p_index + 1);
  w_result := strpos(w_tmp, p_target);
  
  IF w_result <> 0 THEN
    IF p_reverse THEN
      -- 逆転補正、開始位置分補正、検索文字列補正
      RETURN w_length - w_result - p_index - length(p_target) + 3;
    ELSE
      -- 開始位置分補正
      RETURN w_result + p_index - 1;
    END IF;
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 引数が1以上の数かどうか判定する
-- 引数
--   p_params : 任意個の値
-- 戻り値
--   全て1以上の数の場合true
CREATE OR REPLACE FUNCTION uv_is_integers(
  p_params VARIADIC numeric[]
) RETURNS boolean AS $$
DECLARE
BEGIN
  FOR i IN 1..array_length(p_params, 1) LOOP
    IF p_params[i] IS NULL OR 1 > p_params[i] THEN
      RETURN false;
    END IF;
  END LOOP;
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 引数がすべて設定されているか判定する
-- 引数
--   p_params : 任意個の文字列
-- 戻り値
--   全て設定している場合true
CREATE OR REPLACE FUNCTION uv_is_all_set(
  p_params VARIADIC text[]
) RETURNS boolean AS $$
DECLARE
BEGIN
  FOR i IN 1..array_length(p_params, 1) LOOP
    IF NOT uv_is_set(p_params[i]) THEN
      RETURN false;
    END IF;
  END LOOP;
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 月の第何回、何曜日の日を求める
-- 引数
--  p_ts : 基準の時間(何年何月のみ利用)
--  p_order : 月の第何回か。1の時が第一回
--    5以上の場合次月になる可能性がある。
--    0の時は月の最終を意味する
--  p_week : 0が日曜日で6が土曜日となる数値
-- 戻り値
--  指定の日付
CREATE OR REPLACE FUNCTION uv_get_order_week(
  p_ts timestamp with time zone
  ,p_order int
  ,p_week int
) RETURNS timestamp with time zone AS $$
DECLARE
  w_ts timestamp with time zone;
  w_dow int;
  w_day int;
BEGIN
  IF 0 = p_order THEN
    w_ts := uv_get_last_day_of_month(p_ts);
    w_dow := date_part('dow', w_ts);
    w_day := p_week - w_dow;
    IF w_dow < p_week THEN
      w_day := w_day -7;
    END IF;
  ELSE
    w_ts := uv_get_first_day_of_month(p_ts);
    w_dow := date_part('dow', w_ts);
    w_day := 7 * (p_order - 1) + p_week - w_dow;
    IF w_dow > p_week THEN
      w_day := w_day + 7;
    END IF;
  END IF;
  RETURN uv_add_time(w_ts, w_day, 'day');
END;
$$ LANGUAGE plpgsql;

-- 日付の重なりを調べる
-- 引数
--   p_start_ts1: 開始日付1
--   p_end_ts1 : 終了日付1
--   p_start_ts2: 開始日付2
--   p_end_ts2 : 終了日付2
--   p_close_check : 1の終点と2の開始点が一致した時にtrueとする
--   p_check_reverse : 反転しているかチェック
-- 戻り値
--   重なっていたらtrue
CREATE OR REPLACE FUNCTION uv_is_overlap(
  p_start_ts1 timestamp with time zone
  ,p_end_ts1 timestamp with time zone
  ,p_start_ts2 timestamp with time zone
  ,p_end_ts2 timestamp with time zone
  ,p_close_check boolean DEFAULT true
  ,p_check_reverse boolean DEFAULT true
) RETURNS boolean AS $$
DECLARE
  w_start_ts1 timestamp with time zone := COALESCE(p_start_ts1, '-infinity');
  w_end_ts1 timestamp with time zone := COALESCE(p_end_ts1, 'infinity');
  w_start_ts2 timestamp with time zone := COALESCE(p_start_ts2, '-infinity');
  w_end_ts2 timestamp with time zone := COALESCE(p_end_ts2, 'infinity');
BEGIN
  IF p_check_reverse AND (w_start_ts1 > w_end_ts1 OR w_start_ts2 > w_end_ts2) THEN
    RETURN false;
  ELSIF (w_start_ts1, w_end_ts1) OVERLAPS (w_start_ts2, w_end_ts2) THEN
    RETURN true;
  ELSIF p_close_check AND (p_end_ts1 = p_start_ts2 OR p_end_ts2 = p_start_ts1)  THEN
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 指定された曜日の日付を取得する
-- 引数
--  p_ts : 基準の日付(この日付以降が返る)
--  p_week_ary : 0が日曜日で6が土曜日となる数値の配列
-- 戻り値
--  指定の曜日の日付
CREATE OR REPLACE FUNCTION uv_get_date_by_week(
  p_ts timestamp with time zone
  ,p_week_ary VARIADIC int[] DEFAULT null
) RETURNS timestamp with time zone AS $$
DECLARE
  w_dow int := date_part('dow', p_ts);
  w_next int;
  w_min int;
  w_count int;
  w_week int;
BEGIN
  IF p_ts IS NULL OR p_week_ary IS NULL THEN
    RETURN null;
  END IF;
  IF w_dow = ANY(p_week_ary) THEN
    -- 曜日が一致したら返す
    RETURN p_ts;
  ELSE
    w_count := array_length(p_week_ary, 1);
    w_next := 7;
    w_min := p_week_ary[1];
    FOR i IN 1..w_count LOOP
      w_week := p_week_ary[i];
      IF w_dow + 1 = w_week THEN
        -- 一つずれを発見したら翌日を返す
        RETURN uv_add_time(p_ts, 1, 'day');
      END IF;
      -- 現在の曜日よりも大きい最小のものを検索
      IF w_next > w_week AND w_dow < w_week THEN
        w_next := w_week;
      END IF;
      -- 最小の曜日を検索
      IF w_min > w_week THEN
        w_min := m_min;
      END IF;
    END LOOP;
    IF 7 <> w_next THEN
      -- 現在の曜日よりも大きい場合
      RETURN uv_add_time(p_ts, w_next - w_dow, 'day');
    ELSE
      -- 現在の曜日よりも小さい場合
      RETURN uv_add_time(p_ts, 7 + w_min - w_dow, 'day');
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 配列の最大値、最小値を取得する
-- 引数
--  p_params : 配列
--  p_max_flag : 最大値の時はtrue
-- 戻り値
--  最大値、最小の値
CREATE OR REPLACE FUNCTION uv_max_min_array(
  p_params anyarray
  ,p_max_flag boolean DEFAULT true
) RETURNS anyelement AS $$
DECLARE
  w_count int;
  w_result ALIAS FOR $0;
BEGIN
  IF p_params IS NULL THEN
    RETURN NULL;
  END IF;
  w_count := array_length(p_params, 1);
  IF w_count IS NULL OR 0 = w_count THEN
    RETURN NULL;
  END IF;
  FOR i IN 1..w_count LOOP 
    IF (w_result IS NULL) OR
      (p_max_flag AND w_result < p_params[i]) OR 
      (NOT p_max_flag AND w_result > p_params[i])
    THEN
      w_result := p_params[i];
    END IF;
  END LOOP;
  RETURN w_result;
END;
$$ LANGUAGE plpgsql;

-- 日本語の曜日に対応したTO_CHAR
-- 引数
--   p_ts : 変換したい日時
--   p_format : 変換方法
--   p_dow : 日曜日から土曜日まで表示したい並び
-- 戻り値
--   変換された日時
CREATE OR REPLACE FUNCTION uv_to_char (
  p_ts TIMESTAMP WITH TIME ZONE
  ,p_format TEXT
  ,p_dow TEXT DEFAULT '日,月,火,水,木,金,土'
) RETURNS TEXT AS $$
DECLARE
  w_result TEXT := TO_CHAR(p_ts, p_format);
  w_dow_ary1 TEXT[] := string_to_array(p_dow, ',');
  w_dow_ary2 TEXT[] := ARRAY['Sun|Sunday   ','Mon|Monday   ','Tue|Tuesday  ','Wed|Wednesday','Thu|Thursday ','Fri|Friday   ','Sat|Saturday '];
  w_count int := array_length(w_dow_ary1, 1);
BEGIN
  FOR i IN 1..w_count LOOP
    w_result := regexp_replace(w_result, w_dow_ary2[i], w_dow_ary1[i], 'ig');
  END LOOP;
  return w_result;
END;
$$ LANGUAGE plpgsql;

-- 引数が負か調べる
-- 引数
--   p_params : 引数配列
-- 戻り値
--   正の時true
CREATE OR REPLACE FUNCTION uv_is_negatives(
	p_params VARIADIC numeric[]
) RETURNS BOOLEAN AS $$
DECLARE
BEGIN
	FOR i IN 1..array_length(p_params, 1) LOOP
		IF p_params[i] IS NULL OR p_params[i] < 1 THEN
			RETURN true;
		END IF;
	END LOOP;
	RETURN false;
END;
$$ LANGUAGE plpgsql;

-- 引数が空か調べる
-- 引数
--   p_params : 引数配列
-- 戻り値
--   空の時true
CREATE OR REPLACE FUNCTION uv_is_empties(
	p_params VARIADIC text[]
) RETURNS BOOLEAN AS $$
DECLARE
BEGIN
	FOR i IN 1..array_length(p_params, 1) LOOP
		IF p_params[i] IS NULL OR '' = p_params[i] THEN
			RETURN true;
		END IF;
	END LOOP;
	RETURN false;
END;
$$ LANGUAGE plpgsql;

-- 文字列をLIKE用にエスケープする
-- 引数
--   p_src : 元の文字列
--   p_left : 左に%を入れるか
--   p_right : 右に%を入れるか
-- 戻り値
--   エスケープされた文字列
CREATE OR REPLACE FUNCTION uv_like_escape(
	p_src TEXT
  ,p_left BOOLEAN DEFAULT TRUE
  ,p_right BOOLEAN DEFAULT TRUE
) RETURNS TEXT AS $$
DECLARE
BEGIN
	RETURN
    CASE WHEN p_left THEN '%' ELSE '' END ||
    replace(replace(p_src, '_', '\_'), '%', '\%') ||
    CASE WHEN p_right THEN '%' ELSE '' END;
END;
$$ LANGUAGE plpgsql;
