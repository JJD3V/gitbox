create or replace function adjust_kudos(
  user_addr text,
  author_addr text,
  action_type text
)
returns void
language plpgsql
as $$
declare
  user_kudos_delta int := 0;
  author_kudos_delta int := 0;
begin
  -- Apply rules
  if action_type = 'like' then
    user_kudos_delta := 1;
    author_kudos_delta := 2;
  elsif action_type = 'unlike' then
    user_kudos_delta := -1;
    author_kudos_delta := -2;
  elsif action_type = 'post' then
    user_kudos_delta := 1;
  elsif action_type = 'post_deleted' then
    user_kudos_delta := -1;
  elsif action_type = 'comment' then
    if user_addr = author_addr then
      user_kudos_delta := 1;
      author_kudos_delta := 1;
    else
      user_kudos_delta := 1;
      author_kudos_delta := 2;
    end if;
  elsif action_type = 'comment_deleted' then
    if user_addr = author_addr then
      user_kudos_delta := -1;
      author_kudos_delta := -1;
    else
      user_kudos_delta := -1;
      author_kudos_delta := -2;
    end if;
  elsif action_type = 'tip' then
    if user_addr <> author_addr then
      user_kudos_delta := 3;
      author_kudos_delta := 3;
    end if;
  elsif action_type = 'marked_spam' then
    user_kudos_delta := -5;
    author_kudos_delta := -5;
  end if;

  -- Update user account
  update accounts
  set
    kudos = kudos + user_kudos_delta,
    kudos_all_time = kudos_all_time + user_kudos_delta,
    kudos_weekly = kudos_weekly + user_kudos_delta
  where address = user_addr;

  -- Update author account (if not the same as user)
  if author_addr is not null and author_addr <> user_addr then
    update accounts
    set
      kudos = kudos + author_kudos_delta,
      kudos_all_time = kudos_all_time + author_kudos_delta,
      kudos_weekly = kudos_weekly + author_kudos_delta
    where address = author_addr;
  end if;
end;
$$;
