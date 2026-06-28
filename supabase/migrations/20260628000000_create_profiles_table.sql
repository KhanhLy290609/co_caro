-- Create profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  diamonds integer not null default 0,
  unlocked_icons text[] not null default array['X', 'O'],
  selected_icon text not null default 'X',
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Create policies
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Add public access policy for other players in multiplayer
create policy "Users can view others profiles"
  on public.profiles for select
  using (true);
