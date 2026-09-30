# PROMPT_MAESTRO — FocusHabitual Life

Documento de contexto maestro del proyecto. Úsalo como referencia en cada sesión de desarrollo.

---

## 1. Visión del producto

**FocusHabitual Life** es una app móvil Flutter para personas polímatas: usuarios con múltiples
intereses y habilidades que necesitan una sola herramienta elegante y corporativa para gestionar
enfoque (Pomodoro), hábitos, finanzas, gratitud, y módulos personales condicionales (religión,
NoFap, ciclo menstrual) según su perfil.

**Principios de diseño:** elegante, profesional, corporativo. Sin infantilismos visuales pese a
la gamificación — pensar en Notion / Things 3 / banca digital, no en apps de "juego".

---

## 2. Stack técnico

| Capa                   | Tecnología                                                         |
| ---------------------- | ------------------------------------------------------------------ |
| Framework              | Flutter 3.x                                                        |
| Estado                 | Riverpod (StateNotifier / AsyncNotifier)                           |
| Navegación             | go_router con ShellRoute                                           |
| Backend                | Supabase (Auth, Postgres + RLS, Realtime, Storage, Edge Functions) |
| Local/offline          | Drift (SQLite) — espejo local de las tablas críticas               |
| Notificaciones locales | flutter_local_notifications                                        |
| Notificaciones push    | Supabase Edge Function + FCM/APNs                                  |
| Widgets nativos        | home_widget (Android App Widget / iOS WidgetKit)                   |
| Biometría              | local_auth                                                         |
| Cifrado sensible       | pgcrypto (server-side, vía Edge Function)                          |

---

## 3. Estructura de carpetas (feature-first)

```
lib/
├── main.dart
├── app/
│   ├── router.dart                # go_router: rutas + guards condicionales
│   ├── theme.dart                 # tema elegante/corporativo (light/dark)
│   └── di.dart                    # providers globales Riverpod
├── core/
│   ├── supabase_client.dart
│   ├── local_db/                  # Drift: tablas espejo + sync engine
│   │   ├── database.dart
│   │   ├── sync_queue.dart
│   │   └── conflict_resolver.dart
│   ├── security/
│   │   ├── biometric_gate.dart
│   │   └── discreet_mode.dart
│   ├── notifications/
│   │   ├── local_notification_service.dart
│   │   └── push_notification_service.dart
│   └── gamification/
│       ├── xp_engine.dart
│       └── achievement_engine.dart
├── features/
│   ├── auth/
│   │   ├── onboarding/            # incluye selector género + religioso
│   │   ├── login/
│   │   └── profile/
│   ├── launcher/                  # dashboard/home
│   ├── habits/                    # motor central: tracker, 21 días, checklist AM/PM, guía, lista 50
│   ├── pomodoro/
│   ├── religion/                  # renderizado condicional total
│   ├── nofap/                     # condicional: gender == male
│   ├── cycle/                     # condicional: gender == female
│   ├── finance/
│   ├── gratitude/
│   ├── analytics/                 # dashboard semanal/mensual/anual
│   └── settings/
└── widgets_native/
    └── android_ios_widget_bridge.dart
```

---

## 4. Auth y perfil

- Registro/login: email+password, Google, Apple (Supabase Auth providers).
- Trigger `handle_new_user()` en Postgres crea automáticamente `profiles`, `user_xp`,
  `notification_prefs`, `app_settings` al registrarse — la app nunca debe crear estas filas
  manualmente.
- Onboarding obligatorio una sola vez: nombre → género (activa NoFap o Ciclo) → ¿religioso?
  (activa/desactiva Religión) → intereses polímata (opcional, referencia a los 4 planes maestros).
- `onboarding_completed` en `profiles` controla el guard de `go_router` (redirige a onboarding
  si es `false`).
- Edición posterior de género/religión disponible en Ajustes en cualquier momento — el árbol de
  navegación se recalcula reactivamente (Riverpod provider que escucha `profiles`).

---

## 5. Privacidad y seguridad

- **RLS total**: cada tabla de datos de usuario en Supabase filtra por `auth.uid() = user_id`
  (ver `schema.sql`). Ningún usuario puede leer datos de otro, incluso vía API directa.
- **Cifrado de campos sensibles**: notas de NoFap y del ciclo menstrual se cifran con
  `pgcrypto` desde una Edge Function — la clave de cifrado nunca toca el cliente Flutter.
- **Bloqueo biométrico**: `local_auth`, activable por el usuario en Ajustes. Si está activo,
  se exige Face ID/huella/PIN al abrir la app y opcionalmente al entrar a NoFap/Ciclo/Religión
  específicamente (bloqueo granular por módulo).
- **Modo discreto**: cuando `discreet_mode_enabled = true`, el ícono y nombre visibles del
  dispositivo cambian a un alias genérico (`discreet_app_alias`), y las notificaciones push no
  muestran contenido explícito en la pantalla de bloqueo (solo "Tienes una actualización").
- **Exportación de datos**: botón en Ajustes que dispara `data_export_requested_at`; una Edge
  Function genera un JSON/PDF descargable con todos los datos del usuario (cumplimiento tipo
  portabilidad de datos).
- **Borrado de cuenta**: `on delete cascade` en todas las FK — al borrar el usuario en
  `auth.users`, se elimina toda su información en cascada.

---

## 6. Modo offline-first

- Drift (SQLite local) espeja las tablas críticas: `habits`, `habit_logs`, `pomodoro_sessions`,
  `nofap_log`, `cycle_log`, `gratitude_entries`.
- Cada fila local tiene `client_updated_at` y, donde aplica, `client_id` único (ver `schema.sql`)
  para permitir inserciones idempotentes al sincronizar.
- **Sync engine**: cola de operaciones pendientes (`sync_queue` en Drift) que se procesa cuando
  hay conectividad (`connectivity_plus`). Estrategia de resolución de conflictos: _last-write-wins_
  por `client_updated_at`, con excepción de `habit_logs`/`nofap_log` que son solo-inserción
  (no hay conflicto real, solo posible duplicado evitado por `client_id` único).
- El contador de NoFap (días/horas/minutos/segundos) se calcula 100% en cliente a partir del
  último evento local — no depende de conexión para mostrarse correctamente.

---

## 7. Notificaciones inteligentes

- **Locales** (no requieren servidor): recordatorio checklist AM/PM según
  `notification_prefs.checklist_am_time/pm_time`, recordatorio de sesión Pomodoro pendiente.
- **Server-driven** (vía `notification_queue` + pg_cron + Edge Function + FCM/APNs):
  - Pasaje bíblico diario (si `is_religious = true`).
  - Alerta de "racha en riesgo" (ej. no ha hecho check-in NoFap en X horas cercanas a su patrón
    habitual de recaída).
  - Resumen semanal (`weekly_summary_enabled`).
- Todas las notificaciones respetan `discreet_mode_enabled` en el payload (texto genérico si
  está activo).

---

## 8. Gamificación unificada

- Un solo sistema de XP (`user_xp`, `xp_events`) alimentado por **todos** los módulos:
  hábito completado, sesión Pomodoro terminada, día limpio NoFap, entrada de gratitud, etc.
  (ver trigger `apply_xp_event` en `schema.sql`).
- Nivel calculado como `floor(sqrt(total_xp / 100)) + 1` — curva de dificultad creciente.
- `achievements` es la tabla única de medallas, con `module` para saber de dónde viene
  (evita reinventar un sistema de logros por módulo).
- Pantalla "Mi Progreso" en Launcher muestra XP total, nivel, y las últimas 3 medallas
  desbloqueadas, sin importar el módulo de origen.

---

## 9. Analítica / Dashboard semanal · mensual · anual

- Vistas SQL ya agregadas server-side: `analytics_weekly`, `analytics_monthly`,
  `analytics_annual`, `analytics_pomodoro_weekly` (ver `schema.sql`) — evita cálculos pesados
  en el cliente.
- Pantalla de Analítica con selector de rango (semana/mes/año) y gráficas (usar `fl_chart`):
  - Hábitos completados por período.
  - Minutos de enfoque (Pomodoro).
  - XP ganado por módulo (gráfica de barras apiladas).
  - Si aplica: racha NoFap o resumen de ciclo del período.
- Todo filtrado automáticamente por RLS — el cliente solo puede consultar sus propias filas.

---

## 10. Widgets nativos de pantalla de inicio

- Paquete: `home_widget` (Flutter) — puentea con Android App Widgets (Kotlin/Glance) e
  iOS WidgetKit (Swift).
- Tabla `widget_cache` en Supabase (+ espejo local en Drift) guarda el payload ya calculado
  para que el widget nativo lea instantáneamente sin esperar a la app:
  - `nofap_counter`: días/horas/minutos actuales.
  - `habit_today`: próximo hábito pendiente del día.
  - `streak_summary`: racha activa más relevante.
- El widget se actualiza: (a) cada vez que la app está en primer plano y detecta cambios,
  (b) mediante un `WorkManager`/`BackgroundFetch` periódico (cada 15-30 min) para que el
  contador NoFap se vea "vivo" aunque la app esté cerrada.
- **Nota sobre "Launcher minimalista":** si te refieres a un _reemplazo real de la pantalla de
  inicio de Android_ (intent-filter `HOME`), eso es un módulo nativo Android aparte, fuera del
  alcance de Flutter puro — avísame si es lo que necesitas y lo separamos como su propio
  sub-proyecto. Si te refieres a un dashboard interno minimalista dentro de la app, ya está
  cubierto en `features/launcher/`.

---

## 11. Roadmap sugerido (fases)

1. **Fase 0** — Supabase project + `schema.sql` + Auth + onboarding + tema visual.
2. **Fase 1** — Motor de hábitos + Pomodoro + Launcher (dashboard básico).
3. **Fase 2** — Módulos condicionales: Religión, NoFap, Ciclo Menstrual.
4. **Fase 3** — Finanzas + Gratitud + Guías/Lista 50 hábitos (contenido estático).
5. **Fase 4** — Gamificación unificada + Analítica (dashboard semanal/mensual/anual).
6. **Fase 5** — Offline-first (Drift + sync engine) + Notificaciones inteligentes.
7. **Fase 6** — Privacidad avanzada (biometría, modo discreto, cifrado, export de datos) +
   Widgets nativos.
8. **Fase 7** — Pulido visual, internacionalización, monetización (freemium/premium).

---

## 12. Pendiente de definir contigo

- Modelo de monetización exacto (qué módulos son premium).
- Si el "Launcher" debe ser un reemplazo real de pantalla de inicio Android o solo dashboard.
- Proveedor de contenido para pasajes bíblicos (API externa vs. contenido propio curado).
- Si quieres vincular el módulo de hábitos con tus Planes Maestros Polímata (24 semanas) para
  trackear ese progreso dentro de la misma app.

---

# PROMPT_MAESTRO — Addendum: Módulos Adicionales de Bienestar

Este documento extiende `PROMPT_MAESTRO_FocusHabitual_Life.md` con los nuevos módulos
solicitados. Se integran al mismo motor de hábitos, gamificación y sistema de notificaciones
ya definidos — no son sistemas paralelos.

> Nota de interpretación: "Registro Prenupcial" en el Calendario Menstrual lo interpreto como
> **registro de planificación familiar natural** (temperatura basal, moco cervical, método
> sintotérmico) — el tipo de seguimiento que usan parejas antes de casarse para conocer su
> fertilidad conjunta, muy alineado con el módulo de Religión y un enfoque tradicional/familiar.
> Si te referías a otra cosa (ej. checklist de preparación de boda), dímelo y lo ajusto.

---

## 1. Ubicación en la navegación

Estos módulos son transversales a género y no son condicionales (excepto el Calendario
Menstrual, que sigue condicionado a `gender = 'female'`). Se agregan así:

```
Tab 4: Bienestar
 ├── NoFap (condicional: male)              ← ya existente
 ├── Calendario Menstrual (condicional: female) ← ya existente, ahora expandido
 ├── Afirmaciones Positivas                 ← NUEVO
 ├── Agua                                   ← NUEVO
 ├── Alimentación                           ← NUEVO
 └── Retos (sub-navegación por tabs)        ← NUEVO
      ├── Meditación
      ├── Yoga
      └── Yoga Facial
```

---

## 2. Afirmaciones Positivas diarias

**Funcionalidad:**

- Una afirmación distinta cada día, mostrada en el Launcher y enviada como notificación matutina.
- Biblioteca curada por categoría (autoestima, disciplina, fe —si `is_religious`—, abundancia,
  salud). Usuario puede marcar como favorita y volver a verlas en "Mis favoritas".

**Modelo de datos:**

```sql
create table public.affirmations (
  id uuid primary key default uuid_generate_v4(),
  text text not null,
  category text not null default 'general',
  language text not null default 'es'
);

create table public.affirmation_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  affirmation_id uuid not null references public.affirmations(id),
  shown_at timestamptz not null default now(),
  is_favorite boolean not null default false
);

alter table public.affirmation_log enable row level security;
create policy "affirmation_log_all_own" on public.affirmation_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.affirmations enable row level security;
create policy "affirmations_read_all" on public.affirmations
  for select using (auth.role() = 'authenticated');
```

**Notificación:** una diaria a la hora configurada en `notification_prefs` (agregar columna
`affirmation_time time default '08:00'`).

---

## 3. Agua — recordatorios e ingesta

**Funcionalidad:**

- Meta diaria en ml (configurable, sugerida por peso si el usuario la ingresa opcionalmente).
- Botón de registro rápido (+250ml, +500ml, personalizado) con anillo de progreso tipo Apple
  Watch en el Launcher.
- Recordatorios espaciados automáticamente entre hora de despertar y hora de dormir del usuario.

**Modelo de datos:**

```sql
create table public.water_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  daily_goal_ml int not null default 2000,
  reminder_interval_minutes int not null default 90,
  wake_time time not null default '07:00',
  sleep_time time not null default '22:30',
  reminders_enabled boolean not null default true
);

create table public.water_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount_ml int not null,
  logged_at timestamptz not null default now(),
  client_id uuid not null default uuid_generate_v4()
);
create unique index water_log_client_id_idx on public.water_log(client_id);

alter table public.water_settings enable row level security;
alter table public.water_log enable row level security;
create policy "water_settings_all_own" on public.water_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "water_log_all_own" on public.water_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

**Lógica de recordatorios:** se generan localmente en el cliente (no requieren servidor) —
calcular `(sleep_time - wake_time) / reminder_interval_minutes` recordatorios locales
programados con `flutter_local_notifications`, silenciados automáticamente si el usuario ya
alcanzó su meta del día.

---

## 4. Alimentación — recordatorios

**Funcionalidad (alcance intencionalmente simple, no es un contador de calorías):**

- Recordatorios de horario de comida (desayuno, comida, cena, snacks opcionales).
- Tips diarios de alimentación saludable (contenido estático curado, no personalizado
  nutricionalmente — evita responsabilidad médica).
- Registro opcional de "comí" (check simple) para alimentar XP y streak, sin detalle calórico.

**Modelo de datos:**

```sql
create table public.nutrition_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  breakfast_time time default '08:00',
  lunch_time time default '14:00',
  dinner_time time default '20:00',
  reminders_enabled boolean not null default true
);

create table public.nutrition_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  meal_type text not null check (meal_type in ('breakfast','lunch','dinner','snack')),
  logged_at timestamptz not null default now()
);

create table public.nutrition_tips (
  id uuid primary key default uuid_generate_v4(),
  tip_text text not null,
  category text default 'general'
);

alter table public.nutrition_settings enable row level security;
alter table public.nutrition_log enable row level security;
alter table public.nutrition_tips enable row level security;
create policy "nutrition_settings_all_own" on public.nutrition_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "nutrition_log_all_own" on public.nutrition_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "nutrition_tips_read_all" on public.nutrition_tips
  for select using (auth.role() = 'authenticated');
```

---

## 5. Retos: Meditación, Yoga, Yoga Facial

Los tres comparten la misma estructura de reto (motor reutilizable, no tres sistemas distintos).

**Funcionalidad común:**

- Plan de días (configurable, ej. 21 días) con un ejercicio/tip por día.
- Recordatorio diario a hora configurable.
- Reproductor de audio integrado (crítico para Meditación: sonidos de naturaleza — olas, lluvia,
  bosque — en loop, con temporizador de sesión).
- Marcado de día completado → alimenta el mismo `habits`/`xp_events` engine (categoría
  `challenge_21` reutilizada, con `challenge_type` extendido).

**Modelo de datos:**

```sql
create table public.wellness_challenges (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  challenge_type text not null check (challenge_type in ('meditation','yoga','yoga_facial')),
  total_days int not null default 21,
  started_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table public.wellness_challenge_progress (
  id uuid primary key default uuid_generate_v4(),
  challenge_id uuid not null references public.wellness_challenges(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  day_number int not null,
  completed_at timestamptz not null default now(),
  unique (challenge_id, day_number)
);

-- Contenido estático curado (mismo patrón para los 3 tipos, filtrado por challenge_type)
create table public.wellness_exercises (
  id uuid primary key default uuid_generate_v4(),
  challenge_type text not null check (challenge_type in ('meditation','yoga','yoga_facial')),
  day_number int not null,
  title text not null,
  tip text,
  instructions text,
  video_url text,
  duration_minutes int,
  unique (challenge_type, day_number)
);

create table public.ambient_sounds (
  id uuid primary key default uuid_generate_v4(),
  name text not null,          -- 'Olas del mar', 'Lluvia', 'Bosque'
  category text not null default 'nature',
  audio_url text not null,
  loopable boolean not null default true
);

alter table public.wellness_challenges enable row level security;
alter table public.wellness_challenge_progress enable row level security;
alter table public.wellness_exercises enable row level security;
alter table public.ambient_sounds enable row level security;

create policy "wellness_challenges_all_own" on public.wellness_challenges
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "wellness_progress_all_own" on public.wellness_challenge_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "wellness_exercises_read_all" on public.wellness_exercises
  for select using (auth.role() = 'authenticated');
create policy "ambient_sounds_read_all" on public.ambient_sounds
  for select using (auth.role() = 'authenticated');
```

**Nota técnica de audio:** los archivos de sonido ambiental (`ambient_sounds.audio_url`) se
sirven desde Cloudflare R2 (ya en tu stack), no desde Supabase Storage — más barato para
archivos grandes con tráfico repetido. Usar `just_audio` en Flutter para loop + mezclas
(permite combinar "lluvia" + "olas" simultáneamente si se desea).

---

## 6. Calendario Menstrual — expansión

La tabla `cycle_log` original se mantiene para el registro básico de periodo. Se agregan tablas
específicas para separar los cuatro tipos de registro pedidos, ya que cada uno tiene datos y
frecuencia distintos:

```sql
-- Registro de ovulación (más detallado que solo predicción calculada)
create table public.ovulation_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_date date not null,
  basal_body_temp numeric(4,2),          -- °C, para método sintotérmico
  cervical_mucus text check (cervical_mucus in ('dry','sticky','creamy','egg_white')),
  ovulation_test_result text check (ovulation_test_result in ('negative','positive','peak')),
  notes text
);

-- Registro de embarazo (si el ciclo se interrumpe por embarazo)
create table public.pregnancy_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  estimated_conception_date date,
  due_date date,
  current_week int,
  is_active boolean not null default true,
  notes_encrypted bytea,
  created_at timestamptz not null default now()
);

-- Registro "prenupcial" / planificación familiar natural (ver nota de interpretación arriba)
create table public.fertility_awareness_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_date date not null,
  method text not null default 'symptothermal'
    check (method in ('symptothermal','billings','rhythm')),
  fertile_window_status text check (fertile_window_status in ('fertile','infertile','uncertain')),
  partner_shared boolean not null default false,  -- si se comparte con la pareja dentro de la app
  notes text
);

-- Síntomas del ciclo (ya cubierto parcialmente por cycle_log.symptoms jsonb,
-- se separa para permitir histórico granular por día en vez de por ciclo completo)
create table public.cycle_symptoms_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  logged_date date not null,
  symptoms jsonb not null default '{}'::jsonb,   -- {"cramps":3,"mood":"irritable","flow":"heavy"}
  unique (user_id, logged_date)
);

alter table public.ovulation_log enable row level security;
alter table public.pregnancy_log enable row level security;
alter table public.fertility_awareness_log enable row level security;
alter table public.cycle_symptoms_log enable row level security;

create policy "ovulation_log_all_own" on public.ovulation_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "pregnancy_log_all_own" on public.pregnancy_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "fertility_log_all_own" on public.fertility_awareness_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "cycle_symptoms_all_own" on public.cycle_symptoms_log
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

**UI del Calendario Menstrual:** un solo calendario visual con capas activables (toggle chips):
Periodo · Ovulación · Embarazo · Fertilidad/Prenupcial · Síntomas — en vez de 5 pantallas
separadas, para mantener el diseño "elegante/corporativo" sin saturar de tabs.

**Privacidad reforzada:** `pregnancy_log.notes_encrypted` sigue el mismo patrón de cifrado con
`pgcrypto` que `nofap_log` — es de los datos más sensibles de toda la app.

---

## 7. Integración con gamificación y notificaciones existentes

- Todos los módulos nuevos emiten `xp_events` con `source_module` correspondiente
  (`affirmation`, `water`, `nutrition`, `wellness_meditation`, `wellness_yoga`,
  `wellness_yoga_facial`) — agregar estos valores al `check constraint` de `xp_events` en
  `schema.sql`.
- Nuevos logros sugeridos en `achievements`: `water_goal_7d`, `meditation_streak_21`,
  `yoga_streak_21`, `affirmation_reader_30d`.
- Todos los recordatorios nuevos (agua, comidas, afirmación, retos) se agregan como columnas en
  `notification_prefs` ya existente, no como tabla nueva — mantiene un solo lugar de
  configuración de notificaciones para el usuario.
- El widget nativo de pantalla de inicio puede añadir un cuarto tipo:
  `widget_type = 'water_progress'` en `widget_cache`.

---

## 8. Pendiente de confirmar contigo

- Los sonidos son naturales de la carpeta "Sonidos Naturales"
- Los Retos de Yoga y Yoga Facial seran por video demostrativo (Ilustraciones, Gifs) paso a paso con instrucciones claras y con temporizadores incluidos.
