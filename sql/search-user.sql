CREATE OR REPLACE FUNCTION search_author(author_query TEXT)
RETURNS TABLE(
  db TEXT,
  post_id int8,
  post TEXT,
  post_timestamp int8,
  updated_post TEXT,
  post_updated_timestamp int8,
  post_likers TEXT[],
  author TEXT
) AS $$
BEGIN
  RETURN QUERY

  -- Community Posts
  SELECT
    'Community Posts' AS db,
    cp.id AS post_id,
    cp.post,
    cp.post_timestamp AS post_timestamp,
    cp.updated_post,
    cp.updated_timestamp AS post_updated_timestamp,
    ARRAY[]::TEXT[] AS post_likers,
    cp.author
  FROM "Community Posts" cp
  WHERE cp.author ILIKE '%' || author_query || '%'

  UNION ALL

  -- Forum Posts
  SELECT
    'Forum Posts' AS db,
    fp.id AS post_id,
    fp.post,
    fp.post_timestamp AS post_timestamp,
    fp.updated_post,
    fp.updated_timestamp AS post_updated_timestamp,
    COALESCE(fp.post_likers, ARRAY[]::TEXT[]),
    fp.author
  FROM "Forum Posts" fp
  WHERE fp.author ILIKE '%' || author_query || '%'

  UNION ALL

  -- Forum Comments
  SELECT
    'Forum Comments' AS db,
    fc.post_id AS post_id,
    fc.post,
    fc.comment_timestamp AS post_timestamp,
    fc.updated_post,
    fc.updated_timestamp AS post_updated_timestamp,
    ARRAY[]::TEXT[] AS post_likers,
    fc.author
  FROM "Forum Comments" fc
  WHERE fc.author ILIKE '%' || author_query || '%';

END;
$$ LANGUAGE plpgsql;
