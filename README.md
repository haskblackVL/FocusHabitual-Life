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
