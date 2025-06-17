create or replace function fetch_finbyte_general_stats()
returns table (
  forum_posts int,
  forum_comments int,
  community_posts int,
  total_posts int,
  likes_given int,
  unique_users int,
  interactions int
)
language plpgsql
as $$
declare
  forum_posts_count int := 0;
  forum_post_likes int := 0;

  forum_comments_count int := 0;
  forum_comment_likes int := 0;

  community_posts_count int := 0;
  community_likes int := 0;

  interactions_count int := 0;

  total_likes int := 0;

  all_users text[];
begin
  -- Forum Posts
  with post_authors as (
    select author from "Forum Posts"
    union
    select unnest(post_likers) from "Forum Posts"
  ),
  post_stats as (
    select 
      count(*) as cnt,
      coalesce(sum(array_length(post_likers, 1)), 0) as likes
    from "Forum Posts"
  )
  select ps.cnt, ps.likes
  into forum_posts_count, forum_post_likes
  from post_stats ps;

  -- Forum Comments
  with comment_authors as (
    select author from "Forum Comments"
    union
    select unnest(post_likers) from "Forum Comments"
  ),
  comment_stats as (
    select 
      count(*) as cnt,
      coalesce(sum(array_length(post_likers, 1)), 0) as likes
    from "Forum Comments"
  )
  select cs.cnt, cs.likes
  into forum_comments_count, forum_comment_likes
  from comment_stats cs;

  -- Community Posts
  with cp_authors as (
    select author from "Community Posts"
    union
    select unnest(post_likers) from "Community Posts"
  ),
  cp_stats as (
    select 
      count(*) as cnt,
      coalesce(sum(array_length(post_likers, 1)), 0) as likes
    from "Community Posts"
  )
  select cps.cnt, cps.likes
  into community_posts_count, community_likes
  from cp_stats cps;

  -- Notifications (interactions)
  select count(*) into interactions_count from "Finbyte Interactions";

  -- Combine all likers and authors to count unique users
  select array_agg(distinct user_id) into all_users from (
    select author as user_id from "Forum Posts"
    union
    select unnest(post_likers) from "Forum Posts"
    union
    select author from "Forum Comments"
    union
    select unnest(post_likers) from "Forum Comments"
    union
    select author from "Community Posts"
    union
    select unnest(post_likers) from "Community Posts"
    union
    select address from "Finbyte Interactions"
  ) as users;

  total_likes := forum_post_likes + forum_comment_likes + community_likes;

  return query
  select 
    forum_posts_count,
    forum_comments_count,
    community_posts_count,
    forum_posts_count + forum_comments_count + community_posts_count,
    total_likes,
    cardinality(all_users),
    interactions_count;
end;
$$;
