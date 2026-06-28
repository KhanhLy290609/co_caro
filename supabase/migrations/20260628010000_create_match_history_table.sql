create table public.match_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade,
  opponent text not null,
  mode text not null,
  result text not null,
  played_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.match_history enable row level security;

-- Policies
create policy "Users can view their own match history"
  on public.match_history for select
  using (auth.uid() = user_id);

create policy "Users can insert their own match history"
  on public.match_history for insert
  with check (auth.uid() = user_id);
