-- JSONの中身を取得する
-- p_src : JSONの値
-- p_key : キー
-- p_def : デフォルト値。型を特定する
CREATE OR REPLACE FUNCTION uv8_get_value(
  p_src JSON
  ,p_key TEXT
  ,p_def ANYELEMENT DEFAULT NULL::TEXT
) RETURNS ANYELEMENT AS $FUNCTION$
  if (null === p_src) {
    return p_def;
  }
  var result = p_src[p_key];
  if (undefined === result) {
    return p_def;
  } else {
    return result;
  }
$FUNCTION$ LANGUAGE plv8;
