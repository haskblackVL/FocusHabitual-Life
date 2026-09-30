# PROMPT_MAESTRO — Addendum: Pomodoro Avanzado / Deep Work

Extiende el módulo **Pomodoro** de `PROMPT_MAESTRO_FocusHabitual_Life.md`. El Pomodoro clásico
(25/5) se mantiene como modo por defecto; este addendum agrega modos alternativos para trabajo
cognitivo de alta demanda (programación, arquitectura, estudio técnico), protocolos de ejecución
y un planificador de bloques diario.

---

## 1. Modos de temporizador

| Modo                      | Estructura                                                                                                                       | Cuándo usarlo                                                                                                | Máx. bloques/día sugerido                          |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------- |
| **Clásico**               | 25 min trabajo / 5 min pausa                                                                                                     | Tareas cortas, tickets, mantenimiento, correo                                                                | Sin límite                                         |
| **Extendido 50/10**       | 50 min trabajo / 10 min pausa activa                                                                                             | Desarrollo de software, depuración, configuración de entornos — da ~30 min netos ya en zona de concentración | 4–6                                                |
| **Ultradiano 90/20**      | 90 min inmersión / 20-30 min desconexión total                                                                                   | Diseño de arquitectura, temas densos, aprendizaje profundo. Basado en los ciclos de energía de Kleitman      | **2 al día** (hard cap sugerido)                   |
| **Flowmodoro / Flowtime** | Cronómetro ascendente; se detiene la sesión al notar la primera señal de fatiga o interrupción. Pausa = 20% del tiempo trabajado | Trabajo exploratorio sin bloque de tiempo fijo predecible                                                    | Sin límite, con techo diario de horas de deep work |

**Regla de base:** el estado de flujo cognitivo tarda 15–20 minutos en alcanzarse — el modo
Clásico (25/5) es insuficiente para trabajo profundo y la app debe sugerir Extendido o Ultradiano
cuando el usuario etiquete la tarea como `deep_work` (ver sección 3, Pomodoro Bimodal).

---

## 2. Protocolos de ejecución (Deep Work)

### 2.1 Desacople cognitivo radical en las pausas

Durante el descanso de una sesión `deep_work`, la app debe **desincentivar activamente** revisar
terminales, feeds o mensajería — mirar contenido digital fragmenta la memoria de trabajo. La
pantalla de pausa sugiere descansos kinestésicos: hidratación, caminata breve, estiramientos,
respiración controlada. (Reutiliza la animación de respiración ya construida para el Control de
Pánico de No Fap — mismo componente, distinto contexto.)

### 2.2 Bloc de Descarga (Interruption Sheet)

Durante una sesión activa, un campo de texto siempre accesible (overlay o barra flotante) donde
el usuario anota en una línea cualquier idea dispersa, comando pendiente o duda externa, sin
salir de la pantalla de enfoque ni abrir otra app. Al terminar la sesión, la lista de notas
capturadas se muestra para revisión y conversión opcional en tareas o hábitos.

### 2.3 Pomodoro Bimodal — filtrado por tipo de esfuerzo

Cada sesión se etiqueta al iniciar como:

- **Horas de profundidad** (`deep_work`): una sola tarea nuclear, sin notificaciones de fondo,
  modos Extendido/Ultradiano/Flowmodoro sugeridos por defecto.
- **Horas de mantenimiento** (`shallow_work`): tickets menores, correos, documentación —
  modo Clásico 25/5 sugerido por defecto.

### 2.4 Checklist de arranque (obligatorio antes de iniciar una sesión `deep_work`)

1. Objetivo único y verificable escrito antes de iniciar el reloj (ej. _"Implementar y probar la
   autenticación de la API"_, no _"Avanzar proyecto"_ — la app debe rechazar objetivos vagos
   verificando que el texto no sea solo un verbo genérico sin resultado medible, con una
   validación simple de longitud/estructura, no con IA).
2. Confirmación de "navegadores/pestañas redundantes cerrados".
3. Confirmación de "notificaciones/terminales secundarias silenciadas" — dispara automáticamente
   el modo No Molestar del sistema si el usuario lo autorizó (`DND` en Android/iOS).
4. Bloc de Descarga visible y accesible antes de iniciar el cronómetro.

---

## 3. Planificador de bloques diario

Plantilla reutilizable que el usuario puede guardar y aplicar a cualquier día (no es un horario
fijo obligatorio, es una plantilla sugerida editable):

| Horario sugerido | Duración | Modo         | Tipo de tarea                                        |
| ---------------- | -------- | ------------ | ---------------------------------------------------- |
| 08:00–09:30      | 90 min   | Ultradiano   | Deep Work — estudio técnico denso o desarrollo core  |
| 09:30–10:00      | 30 min   | Pausa activa | Desconexión analógica total                          |
| 10:00–10:50      | 50 min   | Extendido    | Deep Work — depuración, testing, implementación      |
| 10:50–11:00      | 10 min   | Pausa activa | Hidratación y movilidad                              |
| 11:00–11:30      | 25 min   | Clásico      | Shallow Work — revisión de notas, commits, logística |

La app permite crear plantillas propias con N bloques, arrastrando/editando horario, modo y tipo
de tarea por bloque — esta tabla es solo la plantilla semilla ("Plan de Implementación
Inmediata") que se precarga en el onboarding del módulo Pomodoro.

---

## 4. Modelo de datos (extiende `schema.sql`)

```sql
-- Catálogo de modos (contenido global, lectura abierta)
create table public.pomodoro_modes (
  key text primary key check (key in ('classic','extended','ultradian','flowmodoro')),
  name text not null,
  work_minutes int,                 -- null en flowmodoro (cronómetro ascendente)
  break_minutes int,
  break_ratio numeric(3,2),         -- 0.20 en flowmodoro (20% del tiempo trabajado)
  description text not null,
  suggested_daily_cap int           -- ej. 2 para ultradiano; null = sin límite
);

insert into public.pomodoro_modes (key, name, work_minutes, break_minutes, break_ratio, description, suggested_daily_cap) values
  ('classic',   'Clásico 25/5',      25, 5,  null, 'Tickets, correo, mantenimiento y tareas cortas.', null),
  ('extended',  'Extendido 50/10',   50, 10, null, 'Desarrollo, depuración, configuración de entornos.', 6),
  ('ultradian', 'Ultradiano 90/20',  90, 25, null, 'Arquitectura, estudio denso, máxima complejidad.', 2),
  ('flowmodoro','Flowmodoro',        null, null, 0.20, 'Cronómetro ascendente; detente ante la primera señal de fatiga.', null);

-- Extiende la tabla pomodoro_sessions ya existente
alter table public.pomodoro_sessions
  add column mode_key text not null default 'classic' references public.pomodoro_modes(key),
  add column work_type text not null default 'shallow_work' check (work_type in ('deep_work','shallow_work')),
  add column task_objective text,                -- objetivo único y verificable (checklist 2.4.1)
  add column startup_checklist jsonb not null default '{}'::jsonb,
     -- {"tabs_closed":true,"notifications_silenced":true,"notepad_ready":true}
  add column dnd_triggered boolean not null default false;

-- Bloc de Descarga (Interruption Sheet)
create table public.pomodoro_interruption_notes (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid not null references public.pomodoro_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  note_text text not null,
  captured_at timestamptz not null default now(),
  converted_to_habit_id uuid references public.habits(id)   -- si el usuario la convierte en hábito/tarea
);

-- Plantillas de bloques diarios (guardadas por el usuario)
create table public.daily_block_templates (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null default 'Mi plan de enfoque',
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.daily_block_template_items (
  id uuid primary key default uuid_generate_v4(),
  template_id uuid not null references public.daily_block_templates(id) on delete cascade,
  start_time time not null,
  duration_minutes int not null,
  mode_key text not null references public.pomodoro_modes(key),
  work_type text not null check (work_type in ('deep_work','shallow_work')),
  label text,                       -- ej. "Deep Work — desarrollo core"
  sort_order int not null default 0
);

-- RLS
alter table public.pomodoro_modes enable row level security;
alter table public.pomodoro_interruption_notes enable row level security;
alter table public.daily_block_templates enable row level security;
alter table public.daily_block_template_items enable row level security;

create policy "pomodoro_modes_read_all" on public.pomodoro_modes
  for select using (auth.role() = 'authenticated');

create policy "interruption_notes_all_own" on public.pomodoro_interruption_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "daily_templates_all_own" on public.daily_block_templates
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Los items heredan la protección del template padre (no tienen user_id propio)
create policy "daily_template_items_all_own" on public.daily_block_template_items
  for all using (
    exists (
      select 1 from public.daily_block_templates t
      where t.id = template_id and t.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.daily_block_templates t
      where t.id = template_id and t.user_id = auth.uid()
    )
  );
```

---

## 5. Integración con el resto de la app

- **XP:** una sesión `deep_work` completada otorga más XP que una `shallow_work` (ej. 1.5x) —
  ajustar el trigger `apply_xp_event` o calcular el monto en el cliente antes de insertar en
  `xp_events` según `work_type` y `mode_key`.
- **Logros sugeridos:** `deep_work_10_sessions`, `ultradian_master` (completar 2 bloques
  ultradianos en un mismo día durante 7 días), `flowmodoro_explorer`.
- **Analítica:** agregar `mode_key` y `work_type` a las vistas `analytics_weekly/monthly/annual`
  ya existentes para mostrar "minutos de deep work vs. shallow work" como gráfica separada.
- **Notificaciones:** al iniciar una sesión `deep_work`, silenciar temporalmente
  `notification_prefs` (guardar el estado previo y restaurarlo al terminar o cancelar la sesión).
- **Widget nativo:** el widget `habit_today` puede mostrar el siguiente bloque de la plantilla
  activa del día en vez de solo el próximo hábito, si el usuario tiene una plantilla marcada
  `is_default = true`.

---

## 6. UX del módulo

- **Pantalla de inicio de sesión:** selector de modo (con recomendación automática según
  `work_type` elegido primero, no al revés — el usuario decide _qué tipo de trabajo_ va a hacer,
  la app sugiere el modo).
- **Checklist de arranque:** modal de 3 pasos obligatorio solo para `deep_work` (no fricciona
  las sesiones cortas de mantenimiento).
- **Pantalla de sesión activa:** cronómetro grande, botón discreto de Bloc de Descarga
  (icono de nota, no interrumpe visualmente el foco), sin badges ni notificaciones parpadeantes.
- **Pantalla de pausa:** temporizador de pausa, sugerencia de descanso kinestésico (rotan entre
  hidratación, caminata, estiramiento, respiración), sin accesos directos a redes u otras apps
  del sistema (hasta donde el OS lo permite).
- **Resumen post-sesión:** minutos netos en flujo, notas del Bloc de Descarga capturadas (con
  opción de convertir cada una en tarea/hábito con un toque), XP ganado.
