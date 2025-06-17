create or replace function fetch_paginated_active_posts(limit_count int, offset_count int)
returns table (
  id int,
  author text,
  topic text,
  post_timestamp int8,
  post text,
  updated_timestamp int8,
  updated_post text,
  post_likers text[],
  comment_id int,
  comment_post_id int,
  comment_author text,
  comment_text text,
  comment_timestamp int8,
  comment_updated_timestamp int8
)
language sql
as $$
  with post_activity as (
    select
      fp.*,
      greatest(
        coalesce(fp.updated_timestamp, fp.post_timestamp),
        coalesce(fc.max_comment_time, 0)
      ) as activity_timestamp
    from "Forum Posts" fp
    left join (
      select
        post_id,
        greatest(
          coalesce(max(updated_timestamp), 0),
          coalesce(max(comment_timestamp), 0)
        ) as max_comment_time
      from "Forum Comments"
      group by post_id
    ) fc on fc.post_id = fp.id
    order by activity_timestamp desc
    limit limit_count offset offset_count
  )
  select
    p.id,
    p.author,
    p.topic,
    p.post_timestamp,
    p.post,
    p.updated_timestamp,
    p.updated_post,
    p.post_likers,
    c.id as comment_id,
    c.post_id as comment_post_id,
    c.author as comment_author,
    c.post as comment_text,
    c.comment_timestamp as comment_timestamp,
    c.updated_timestamp as comment_updated_timestamp
  from post_activity p
  left join "Forum Comments" c on c.post_id = p.id
  order by greatest(
    coalesce(p.updated_timestamp, p.post_timestamp),
    coalesce(c.updated_timestamp, 0),
    coalesce(c.comment_timestamp, 0)
  ) desc;
$$;
