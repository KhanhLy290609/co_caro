-- Create rooms table
create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text not null,
  player_x text not null,
  player_o text,
  status text not null default 'waiting', -- 'waiting', 'playing', 'ended'
  board_size integer not null default 20,
  win_condition integer not null default 5,
  timer_duration integer not null default 30,
  is_x_turn boolean not null default true,
  game_over boolean not null default false,
  history jsonb not null default '[]'::jsonb,
  winning_cells jsonb not null default '[]'::jsonb,
  last_move jsonb,
  x_wins integer not null default 0,
  o_wins integer not null default 0,
  draws integer not null default 0,
  last_action text,
  updated_at timestamp with time zone default now()
);

-- Create unique index for room_code on active rooms
create unique index rooms_active_room_code_idx on public.rooms (room_code) 
where (status = 'waiting' or status = 'playing');

-- Enable Realtime for the rooms table
alter publication supabase_realtime add table public.rooms;

-- Enable Row Level Security (RLS)
alter table public.rooms enable row level security;

-- Create policy to allow public access to rooms
create policy "Allow public access to rooms"
on public.rooms
for all
using (true)
with check (true);
