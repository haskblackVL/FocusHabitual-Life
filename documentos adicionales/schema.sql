-- ============================================================================
-- FocusHabitual Life — Esquema completo Supabase (PostgreSQL)
-- Incluye: perfiles, hábitos, pomodoro, no fap, ciclo menstrual, religión,
-- finanzas, gratitud, gamificación unificada, notificaciones, analítica,
-- widgets nativos, RLS completo.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. EXTENSIONES
-- ----------------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";      -- para cifrado de campos sensibles
create extension if not exists "pg_cron";       -- para jobs programados (reset checklist AM/PM, etc.)

-- ----------------------------------------------------------------------------
-- 1. PERFILES Y AUTH
-- ----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  gender text check (gender in ('male','female','other','prefer_not_to_say')),
  is_religious boolean not null default false,
  locale text not null default 'es-MX',
  timezone text not null default 'America/Mexico_City',
  avatar_url text,
  onboarding_completed boolean not null default false,
  premium_tier text not null default 'free' check (premium_tier in ('free','premium')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger: crea el perfil automáticamente al registrarse
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  insert into public.user_xp (user_id) values (new.id);
  insert into public.notification_prefs (user_id) values (new.id);
  insert into public.app_settings (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 2. AJUSTES DE APP / PRIVACIDAD Y SEGURIDAD
-- ----------------------------------------------------------------------------
create table public.app_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  theme text not null default 'corporate_elegant',
  biometric_lock_enabled boolean not null default false,
  discreet_mode_enabled boolean not null default false,   -- oculta nombre/ícono real y notif. sin contenido explícito
  discreet_app_alias text default 'Focus',                -- nombre mostrado en modo discreto
  auto_lock_minutes int not null default 5,
  data_export_requested_at timestamptz,
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 3. MOTOR DE HÁBITOS (usado por tracker general, reto 21 días, checklist AM/PM)
-- ----------------------------------------------------------------------------
create table public.habits (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'general'
    check (category in ('general','challenge_21','checklist_am','checklist_pm','finance','gratitude')),
  icon text,
  color text,
  frequency text not null default 'daily' check (frequency in ('daily','weekly','custom')),
  target_count int not null default 1,
  is_active boolean not null default true,
  start_date date not null default current_date,
  end_date date,                                   -- usado por reto 21 días (start_date + 21)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,                           -- soft delete
  client_updated_at timestamptz not null default now()  -- resolución de conflictos offline
);

create table public.habit_logs (
  id uuid primary key default uuid_generate_v4(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  completed_at timestamptz not null default now(),
  note text,
  xp_earned int not null default 10,
  client_id uuid not null default uuid_generate_v4()  -- idempotencia al sincronizar offline
);

create unique index habit_logs_client_id_idx on public.habit_logs(client_id);

-- ----------------------------------------------------------------------------
-- 4. POMODORO
-- ----------------------------------------------------------------------------
create table public.pomodoro_sessions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  duration_minutes int not null,
  task_tag text,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  was_completed boolean not null default false,
  client_updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 5. RELIGIÓN (contenido global + registro opcional del usuario)
-- ----------------------------------------------------------------------------
create table public.religion_content (
  id uuid primary key default uuid_generate_v4(),
  verse_ref text not null,
  verse_text text not null,
  reflection text,
  date_assigned date not null unique,
  language text not null default 'es'
);

create table public.religion_user_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content_id uuid not null references public.religion_content(id),
  read_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 6. NO FAP (hombre) — datos sensibles, notas cifradas con pgcrypto
-- ----------------------------------------------------------------------------
create table public.nofap_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null check (event_type in ('checkin','relapse','reason_added')),
  occurred_at timestamptz not null default now(),
  relapse_reason text check (relapse_reason in ('masturbation','porn','both') or relapse_reason is null),
  note_encrypted bytea,          -- cifrado con pgp_sym_encrypt() desde el cliente/edge function
  client_id uuid not null default uuid_generate_v4()
);

create unique index nofap_log_client_id_idx on public.nofap_log(client_id);

create table public.nofap_reasons (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason_text text not null,
  created_at timestamptz not null default now(),
  is_active boolean not null default true
);

-- Vista: racha actual calculada dinámicamente (último 'checkin' inicial tras el último relapse)
create or replace view public.nofap_current_streak as
select
  user_id,
  max(occurred_at) filter (where event_type = 'relapse') as last_relapse_at,
  now() - coalesce(
    max(occurred_at) filter (where event_type = 'relapse'),
    min(occurred_at)
  ) as current_streak_interval
from public.nofap_log
group by user_id;

-- ----------------------------------------------------------------------------
-- 7. CICLO MENSTRUAL (mujer)
-- ----------------------------------------------------------------------------
create table public.cycle_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  period_start date not null,
  period_length int not null default 5,
  cycle_length int not null default 28,
  symptoms jsonb default '{}'::jsonb,   -- {"cramps":true,"energy":"low","mood":"irritable"}
  notes_encrypted bytea,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 8. FINANZAS PERSONALES
-- ----------------------------------------------------------------------------
create table public.finance_accounts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  type text not null default 'cash' check (type in ('cash','bank','credit_card','savings','investment')),
  currency text not null default 'MXN',
  initial_balance numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);

create table public.finance_transactions (
  id uuid primary key default uuid_generate_v4(),
  account_id uuid not null references public.finance_accounts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric(14,2) not null,
  type text not null check (type in ('income','expense','transfer')),
  category text not null default 'general',
  occurred_at timestamptz not null default now(),
  note text,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 9. DIARIO DE GRATITUD
-- ----------------------------------------------------------------------------
create table public.gratitude_entries (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  entry_date date not null default current_date,
  content text not null,
  prompt_used text,
  created_at timestamptz not null default now(),
  unique (user_id, entry_date)
);

-- ----------------------------------------------------------------------------
-- 10. CONTENIDO GLOBAL (guías, lista de 50 hábitos) — administrado por rol service_role
-- ----------------------------------------------------------------------------
create table public.guides (
  id uuid primary key default uuid_generate_v4(),
  slug text unique not null,
  title text not null,
  category text not null check (category in ('habit_order','habits_50','challenge_21','general')),
  content jsonb not null,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 11. GAMIFICACIÓN UNIFICADA
-- ----------------------------------------------------------------------------
create table public.user_xp (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  total_xp int not null default 0,
  level int not null default 1,
  updated_at timestamptz not null default now()
);

create table public.xp_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_module text not null check (source_module in
    ('habit','pomodoro','nofap','cycle','finance','gratitude','religion','challenge_21')),
  xp_amount int not null,
  occurred_at timestamptz not null default now()
);

create table public.achievements (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  achievement_key text not null,    -- ej: 'nofap_7d', 'habit_streak_30', 'pomodoro_100_sessions'
  module text not null,
  unlocked_at timestamptz not null default now(),
  unique (user_id, achievement_key)
);

-- Trigger: al insertar xp_event, actualiza user_xp y recalcula nivel
create or replace function public.apply_xp_event()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  update public.user_xp
  set total_xp = total_xp + new.xp_amount,
      level = floor(sqrt((total_xp + new.xp_amount) / 100.0)) + 1,
      updated_at = now()
  where user_id = new.user_id;
  return new;
end;
$$;

create trigger on_xp_event_insert
  after insert on public.xp_events
  for each row execute procedure public.apply_xp_event();

-- ----------------------------------------------------------------------------
-- 12. NOTIFICACIONES INTELIGENTES
-- ----------------------------------------------------------------------------
create table public.notification_prefs (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  habit_reminders boolean not null default true,
  verse_reminder boolean not null default true,
  streak_risk_alerts boolean not null default true,
  checklist_am_time time not null default '07:00',
  checklist_pm_time time not null default '21:00',
  weekly_summary_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

-- Cola de notificaciones generadas server-side (pg_cron + Edge Function las procesa y envía push)
create table public.notification_queue (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,          -- 'habit_reminder','verse','streak_risk','weekly_summary'
  payload jsonb not null default '{}'::jsonb,
  scheduled_for timestamptz not null,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 13. WIDGETS NATIVOS (caché denormalizado para lectura rápida desde home_widget)
-- ----------------------------------------------------------------------------
create table public.widget_cache (
  user_id uuid not null references public.profiles(id) on delete cascade,
  widget_type text not null check (widget_type in ('nofap_counter','habit_today','streak_summary')),
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, widget_type)
);

-- ----------------------------------------------------------------------------
-- 14. ANALÍTICA — VISTAS SEMANAL / MENSUAL / ANUAL
-- ----------------------------------------------------------------------------
create or replace view public.analytics_weekly as
select
  user_id,
  date_trunc('week', completed_at) as period_start,
  count(*) as habits_completed,
  sum(xp_earned) as xp_from_habits
from public.habit_logs
group by user_id, date_trunc('week', completed_at);

create or replace view public.analytics_monthly as
select
  user_id,
  date_trunc('month', completed_at) as period_start,
  count(*) as habits_completed,
  sum(xp_earned) as xp_from_habits
from public.habit_logs
group by user_id, date_trunc('month', completed_at);

create or replace view public.analytics_annual as
select
  user_id,
  date_trunc('year', completed_at) as period_start,
  count(*) as habits_completed,
  sum(xp_earned) as xp_from_habits
from public.habit_logs
group by user_id, date_trunc('year', completed_at);

create or replace view public.analytics_pomodoro_weekly as
select
  user_id,
  date_trunc('week', started_at) as period_start,
  count(*) filter (where was_completed) as sessions_completed,
  sum(duration_minutes) filter (where was_completed) as focus_minutes
from public.pomodoro_sessions
group by user_id, date_trunc('week', started_at);

-- ============================================================================
-- 15. ROW LEVEL SECURITY (RLS) — TODAS LAS TABLAS DE USUARIO
-- ============================================================================

-- Habilitar RLS
alter table public.profiles enable row level security;
alter table public.app_settings enable row level security;
alter table public.habits enable row level security;
alter table public.habit_logs enable row level security;
alter table public.pomodoro_sessions enable row level security;
alter table public.religion_user_log enable row level security;
alter table public.nofap_log enable row level security;
alter table public.nofap_reasons enable row level security;
alter table public.cycle_log enable row level security;
alter table public.finance_accounts enable row level security;
alter table public.finance_transactions enable row level security;
alter table public.gratitude_entries enable row level security;
alter table public.user_xp enable row level security;
alter table public.xp_events enable row level security;
alter table public.achievements enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.notification_queue enable row level security;
alter table public.widget_cache enable row level security;

-- Contenido global: RLS habilitado pero lectura abierta a autenticados
alter table public.religion_content enable row level security;
alter table public.guides enable row level security;

-- ---- Política genérica reutilizable: dueño del registro (user_id = auth.uid()) ----

-- PROFILES (la PK es el propio id)
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
-- No hay insert/delete manual: lo maneja el trigger handle_new_user() y el borrado de cuenta cascada

-- APP_SETTINGS
create policy "app_settings_all_own" on public.app_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- HABITS
create policy "habits_all_own" on public.habits
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- HABIT_LOGS
create policy "habit_logs_all_own" on public.habit_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- POMODORO
create policy "pomodoro_all_own" on public.pomodoro_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- RELIGION_USER_LOG
create policy "religion_log_all_own" on public.religion_user_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- RELIGION_CONTENT (lectura pública a autenticados; escritura solo service_role)
create policy "religion_content_read_all" on public.religion_content
  for select using (auth.role() = 'authenticated');

-- NOFAP
create policy "nofap_log_all_own" on public.nofap_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "nofap_reasons_all_own" on public.nofap_reasons
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- CYCLE_LOG
create policy "cycle_log_all_own" on public.cycle_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- FINANZAS
create policy "finance_accounts_all_own" on public.finance_accounts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "finance_transactions_all_own" on public.finance_transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- GRATITUD
create policy "gratitude_all_own" on public.gratitude_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- GAMIFICACIÓN
create policy "user_xp_select_own" on public.user_xp for select using (auth.uid() = user_id);
create policy "xp_events_select_own" on public.xp_events for select using (auth.uid() = user_id);
create policy "xp_events_insert_own" on public.xp_events for insert with check (auth.uid() = user_id);
create policy "achievements_select_own" on public.achievements for select using (auth.uid() = user_id);

-- GUIDES (contenido global, lectura abierta)
create policy "guides_read_all" on public.guides
  for select using (auth.role() = 'authenticated');

-- NOTIFICACIONES
create policy "notification_prefs_all_own" on public.notification_prefs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "notification_queue_select_own" on public.notification_queue
  for select using (auth.uid() = user_id);

-- WIDGETS
create policy "widget_cache_all_own" on public.widget_cache
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- 16. NOTA SOBRE CIFRADO DE CAMPOS SENSIBLES (NoFap notes, Cycle notes)
-- ============================================================================
-- Los campos note_encrypted / notes_encrypted se guardan como bytea usando
-- pgp_sym_encrypt(texto, clave) desde una Edge Function (la clave NUNCA vive
-- en el cliente Flutter). Para leer: pgp_sym_decrypt(campo, clave), también
-- solo desde Edge Function con service_role. Esto evita que un dump de la
-- base o un admin sin la clave lea el contenido en texto plano.
--
-- Ejemplo de inserción (desde Edge Function, no desde el cliente):
--   insert into nofap_log (user_id, event_type, note_encrypted)
--   values (:user_id, 'checkin', pgp_sym_encrypt(:note_text, :encryption_key));