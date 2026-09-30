# PROMPT_MAESTRO — FocusHabitual Life

Documento de contexto maestro del proyecto. Úsalo como referencia en cada sesión de desarrollo.
Última actualización: **2026-09-29**

---

## 1. Visión del producto

**FocusHabitual Life** es una app móvil Flutter para personas polímatas: usuarios con múltiples
intereses y habilidades que necesitan una sola herramienta elegante y corporativa para gestionar
enfoque (Pomodoro), hábitos, finanzas, gratitud, bienestar físico/mental, y módulos personales
condicionales (religión, NoFap, ciclo menstrual, filosofía) según su perfil.

**Principios de diseño:** elegante, profesional, corporativo. Sin infantilismos visuales pese a
la gamificación — pensar en Notion / Things 3 / banca digital, no en apps de "juego".

---

## 2. Stack técnico

| Capa                   | Tecnología / Paquete                                                  | Versión           |
| ---------------------- | --------------------------------------------------------------------- | ----------------- |
| Framework              | Flutter / Dart                                                        | SDK ^3.13.4       |
| Estado                 | `flutter_riverpod` (StateNotifier / AsyncNotifier)                    | ^3.4.3            |
| Navegación             | `go_router` con ShellRoute + guards condicionales                     | ^18.0.1           |
| Backend                | Supabase (Auth, Postgres + RLS, Realtime, Storage, Edge Functions)    | ^2.17.2           |
| Local / offline        | `drift` (SQLite) — espejo local de tablas críticas                    | ^2.35.0           |
| SQLite nativo          | `sqlite3_flutter_libs` + `sqlite3`                                    | ^0.6.0 / ^3.6.0   |
| Tipografía             | `google_fonts` (Plus Jakarta Sans, JetBrains Mono, etc.)             | ^8.2.1            |
| Gráficas               | `fl_chart`                                                            | ^1.2.0            |
| Notificaciones locales | `flutter_local_notifications` + `timezone`                            | ^22.3.1 / ^0.11.1 |
| Audio / Sonido ambient | `just_audio`                                                          | ^0.10.6           |
| Biometría              | `local_auth`                                                          | ^3.0.2            |
| Internacionalización   | `intl`                                                                | ^0.20.3           |
| Variables de entorno   | `flutter_dotenv` (archivo `.env` en root)                             | ^6.0.1            |
| UUID                   | `uuid`                                                                | ^4.6.0            |
| Cifrado sensible       | `pgcrypto` (server-side, vía Edge Function)                           | —                 |
| Widgets nativos        | `android_ios_widget_bridge.dart` (puente futuro a `home_widget`)      | pendiente         |
| Code gen / ORM         | `drift_dev` + `build_runner` (dev)                                    | ^2.35.0 / ^2.16.1 |

---

## 3. Estructura de carpetas (estado actual · feature-first)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                        # MaterialApp raíz
│   ├── router.dart                     # go_router: rutas + guards condicionales
│   ├── theme.dart                      # AppTheme: colores, tipografía, tokens
│   ├── di.dart                         # providers globales Riverpod
│   └── widgets/
│       └── brand_logo.dart             # Logo FocusHabitual reutilizable
├── core/
│   ├── config/
│   │   └── env.dart                    # Lectura segura de variables .env
│   ├── supabase/
│   │   └── supabase_client.dart        # Singleton SupabaseClient
│   ├── local_db/
│   │   ├── database.dart               # Drift DB + tablas + DAOs
│   │   └── sync_engine.dart            # Cola de sync offline → Supabase
│   ├── notifications/
│   │   ├── local_notification_service.dart   # Recordatorios AM/PM, hidratación, etc.
│   │   ├── notification_controller.dart      # Riverpod provider + lógica de permisos
│   │   └── notification_settings_model.dart  # Modelo de preferencias de notificación
│   ├── security/
│   │   ├── biometric_gate.dart         # Widget guardia biométrico
│   │   ├── biometric_service.dart      # local_auth wrapper
│   │   ├── discreet_mode.dart          # Alias de app + notificaciones genéricas
│   │   ├── module_security_gate.dart   # Bloqueo granular por módulo
│   │   ├── security_controller.dart    # Riverpod provider de seguridad
│   │   ├── security_settings_model.dart
│   │   └── six_digit_pin_view.dart     # PIN alternativo a biometría
│   └── gamification/
│       ├── xp_engine.dart              # Cálculo de XP + nivel
│       ├── achievement_engine.dart     # Lógica de desbloqueo de logros
│       ├── achievement_model.dart      # Modelo de medalla/achievement
│       ├── gamification_controller.dart
│       ├── data/
│       │   └── achievement_repository.dart
│       └── presentation/
│           └── my_progress_sheet.dart  # Bottom sheet "Mi Progreso" (XP + medallas)
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── user_profile.dart
│   │   ├── login/
│   │   │   └── login_screen.dart
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart  # nombre → género → religioso → intereses
│   │   └── presentation/controllers/
│   │       └── auth_controller.dart
│   ├── launcher/
│   │   └── presentation/
│   │       └── launcher_screen.dart    # Dashboard principal (todos los módulos)
│   ├── habits/
│   │   ├── data/
│   │   │   └── habit_repository.dart
│   │   ├── domain/
│   │   │   ├── habit.dart
│   │   │   ├── master_habits_catalog.dart  # Lista curada 50+ hábitos
│   │   │   └── challenge_21_data.dart      # Reto 21 días
│   │   └── presentation/
│   │       ├── habits_screen.dart
│   │       ├── master_habits_catalog_screen.dart
│   │       ├── controllers/
│   │       │   └── habits_controller.dart
│   │       └── widgets/
│   │           └── add_habit_sheet.dart
│   ├── pomodoro/
│   │   ├── domain/
│   │   │   └── pomodoro_models.dart
│   │   └── presentation/
│   │       ├── pomodoro_screen.dart
│   │       ├── controllers/
│   │       │   ├── pomodoro_controller.dart
│   │       │   └── ambient_sound_controller.dart
│   │       └── widgets/
│   │           ├── ambient_sound_bar.dart
│   │           ├── daily_blocks_sheet.dart
│   │           ├── interruption_sheet.dart
│   │           ├── kinesthetic_break_view.dart
│   │           ├── post_session_summary_dialog.dart
│   │           └── startup_checklist_sheet.dart
│   ├── religion/                        # condicional: is_religious == true
│   │   ├── data/
│   │   │   └── religion_repository.dart
│   │   ├── domain/
│   │   │   ├── prayer_request.dart
│   │   │   └── religion_content.dart
│   │   └── presentation/
│   │       ├── religion_screen.dart     # tabs: Devocional / Oración / Biblioteca
│   │       ├── controllers/
│   │       │   └── religion_controller.dart
│   │       └── widgets/
│   │           ├── add_prayer_sheet.dart
│   │           └── prayer_answered_dialog.dart
│   ├── nofap/                           # condicional: gender == male
│   │   ├── data/
│   │   │   └── nofap_repository.dart
│   │   ├── domain/
│   │   │   └── nofap_models.dart
│   │   └── presentation/
│   │       ├── nofap_screen.dart        # Contador en tiempo real + protocolo
│   │       ├── nofap_education_screen.dart
│   │       ├── controllers/
│   │       │   └── nofap_controller.dart
│   │       └── widgets/
│   │           └── cooling_protocol_sheet.dart
│   ├── cycle/                           # condicional: gender == female
│   │   ├── data/
│   │   │   └── cycle_repository.dart
│   │   ├── domain/
│   │   │   └── cycle_models.dart
│   │   └── presentation/
│   │       ├── woman_cycle_screen.dart
│   │       ├── controllers/
│   │       │   └── cycle_controller.dart
│   │       └── widgets/
│   │           ├── cycle_day_logger_sheet.dart
│   │           ├── cycle_layer_calendar.dart
│   │           ├── cycle_layer_chips.dart
│   │           ├── woman_cycle_detail_sheet.dart
│   │           └── woman_cycle_settings_card.dart
│   ├── finance/
│   │   ├── data/
│   │   │   └── finance_repository.dart
│   │   ├── domain/
│   │   │   ├── finance_account.dart
│   │   │   ├── finance_budget.dart
│   │   │   └── finance_transaction.dart
│   │   └── presentation/
│   │       ├── finance_screen.dart
│   │       ├── controllers/
│   │       │   └── finance_controller.dart
│   │       └── widgets/
│   │           ├── add_account_sheet.dart
│   │           ├── add_transaction_sheet.dart
│   │           ├── edit_budget_sheet.dart
│   │           ├── finance_calendar_widget.dart
│   │           ├── finance_chart_widget.dart
│   │           └── quick_receive_sheet.dart
│   ├── gratitude/
│   │   ├── data/
│   │   │   └── gratitude_repository.dart
│   │   ├── domain/
│   │   │   └── gratitude_model.dart
│   │   └── presentation/
│   │       ├── gratitude_screen.dart
│   │       └── controllers/
│   │           └── gratitude_controller.dart
│   ├── wellness/                        # Bienestar: agua, nutrición, retos, yoga, afirmaciones
│   │   ├── data/
│   │   │   ├── ambient_audio_service.dart
│   │   │   └── wellness_repository.dart
│   │   ├── domain/
│   │   │   ├── affirmation.dart
│   │   │   ├── challenge_catalog.dart
│   │   │   ├── challenge_data.dart
│   │   │   ├── nutrition_data.dart
│   │   │   ├── water_data.dart
│   │   │   └── yoga_and_facial_catalog.dart
│   │   └── presentation/
│   │       ├── wellness_screen.dart
│   │       ├── controllers/
│   │       │   ├── wellness_controller.dart
│   │       │   └── challenges_controller.dart
│   │       └── widgets/
│   │           ├── ambient_sound_player_sheet.dart
│   │           ├── challenge_day_detail_sheet.dart
│   │           ├── challenges_tab_view.dart
│   │           ├── custom_water_dialog.dart
│   │           ├── exercise_timer_widget.dart
│   │           ├── log_meal_sheet.dart
│   │           ├── water_tracker_card.dart
│   │           ├── wellness_visual_guide.dart
│   │           └── yoga_and_facial_catalog_sheet.dart
│   ├── philosophy/                      # Biblioteca de 100 Sabios / Pensadores
│   │   ├── data/
│   │   │   ├── thinkers_catalog.dart    # Catálogo estático de 100 figuras
│   │   │   └── thinkers_repository.dart
│   │   ├── domain/
│   │   │   └── thinker.dart
│   │   └── presentation/
│   │       ├── thinkers_library_screen.dart
│   │       ├── controllers/
│   │       │   └── thinkers_controller.dart
│   │       └── widgets/
│   │           ├── thinker_card.dart
│   │           └── thinker_detail_sheet.dart
│   ├── analytics/
│   │   ├── data/
│   │   │   └── analytics_repository.dart
│   │   ├── domain/
│   │   │   └── analytics_data.dart
│   │   └── presentation/
│   │       ├── analytics_screen.dart
│   │       ├── controllers/
│   │       │   └── analytics_controller.dart
│   │       └── widgets/
│   │           ├── analytics_charts.dart
│   │           ├── bimodal_focus_card.dart
│   │           └── score_calendar_card.dart
│   └── settings/
│       └── presentation/
│           ├── settings_screen.dart
│           └── widgets/
│               ├── notification_settings_card.dart
│               └── security_settings_card.dart
└── widgets_native/
    └── android_ios_widget_bridge.dart   # Puente futuro a home_widget (Android/iOS)
```

---

## 4. Auth y perfil

- Registro/login: email+password, Google, Apple (Supabase Auth providers).
- Trigger `handle_new_user()` en Postgres crea automáticamente `profiles`, `user_xp`,
  `notification_prefs`, `app_settings` al registrarse — **la app nunca debe crear estas filas
  manualmente**.
- Onboarding obligatorio una sola vez: nombre → género (activa NoFap o Ciclo) → ¿religioso?
  (activa/desactiva Religión) → intereses polímata.
- `onboarding_completed` en `profiles` controla el guard de `go_router` (redirige a onboarding
  si es `false`).
- Edición posterior de género/religión disponible en Ajustes — el árbol de navegación se
  recalcula reactivamente (provider de `profiles` en Riverpod).

---

## 5. Módulos condicionales

| Módulo       | Condición de activación          | Ruta         |
| ------------ | -------------------------------- | ------------ |
| Religión     | `profiles.is_religious == true`  | `/religion`  |
| NoFap        | `profiles.gender == 'male'`      | `/nofap`     |
| Ciclo        | `profiles.gender == 'female'`    | `/cycle`     |
| Filosofía    | Siempre visible                  | `/thinkers`  |
| Wellness     | Siempre visible                  | `/wellness`  |

Los módulos se muestran u ocultan reactivamente en el Launcher y en `go_router`. No se
renderiza nada de UI si el módulo no corresponde al perfil del usuario.

---

## 6. Privacidad y seguridad

- **RLS total**: cada tabla en Supabase filtra por `auth.uid() = user_id`. Ningún usuario puede
  leer datos de otro, incluso vía API directa.
- **Cifrado de campos sensibles**: notas de NoFap y del ciclo menstrual se cifran con `pgcrypto`
  desde una Edge Function — la clave nunca toca el cliente Flutter.
- **Bloqueo biométrico**: `local_auth` + PIN de 6 dígitos. Activable por módulo granular
  (`module_security_gate.dart`): NoFap, Ciclo, Religión pueden tener bloqueo independiente.
- **Modo discreto**: cuando `discreet_mode_enabled = true`, las notificaciones push muestran
  solo texto genérico ("Tienes una actualización").
- **Exportación de datos**: botón en Ajustes que dispara `data_export_requested_at`; una Edge
  Function genera un JSON descargable (portabilidad de datos).
- **Borrado de cuenta**: `on delete cascade` en todas las FK — borrar el usuario en `auth.users`
  elimina toda su información en cascada.

---

## 7. Modo offline-first

- `drift` (SQLite local) espeja las tablas críticas: `habits`, `habit_logs`,
  `pomodoro_sessions`, `nofap_log`, `cycle_log`, `gratitude_entries`, `finance_transactions`.
- Cada fila local tiene `client_updated_at` + `client_id` único para inserciones idempotentes.
- **Sync engine** (`sync_engine.dart`): cola de operaciones pendientes que se procesa al
  recuperar conectividad. Estrategia: _last-write-wins_ por `client_updated_at`; los logs de
  solo-inserción evitan duplicados vía `client_id` único.
- El contador NoFap (días/horas/minutos/segundos) se calcula 100% en cliente — no depende de
  conexión para mostrarse.

---

## 8. Notificaciones inteligentes

- **Locales** (`local_notification_service.dart`):
  - Checklist AM / PM según horarios configurados en Ajustes.
  - Recordatorio de hidratación (cada 2 h o cada 3 h, entre 09:00–20:00).
  - Alarma de sesión Pomodoro pendiente.
- **Server-driven** (vía `notification_queue` + pg_cron + Edge Function + FCM/APNs):
  - Pasaje bíblico diario (si `is_religious = true`).
  - Alerta de "racha en riesgo" NoFap.
  - Resumen semanal de progreso.
- Todas las notificaciones respetan `discreet_mode_enabled` (texto genérico si está activo).

---

## 9. Gamificación unificada

- Un solo sistema de XP (`user_xp`, `xp_events`) alimentado por **todos** los módulos:
  hábito completado, sesión Pomodoro terminada, día limpio NoFap, entrada de gratitud,
  petición de oración respondida, reto de wellness, etc.
- Nivel: `floor(sqrt(total_xp / 100)) + 1` — curva de dificultad creciente.
- `achievements`: tabla única de medallas con campo `module` (origen).
- Bottom sheet **"Mi Progreso"** (`my_progress_sheet.dart`) en Launcher: XP total, nivel,
  últimas 3 medallas desbloqueadas, sin importar el módulo de origen.

---

## 10. Analítica / Dashboard

- Vistas SQL server-side: `analytics_weekly`, `analytics_monthly`, `analytics_annual`,
  `analytics_pomodoro_weekly` — evita cálculos pesados en cliente.
- Pantalla de Analítica con selector semana/mes/año y gráficas (`fl_chart`):
  - Hábitos completados por período.
  - Minutos de enfoque (Pomodoro) + bimodal focus card.
  - XP ganado por módulo (barras apiladas).
  - Score calendar (calendario de puntuación diaria).
  - Si aplica: racha NoFap o resumen de ciclo del período.

---

## 11. Wellness — bienestar integral

Módulo transversal siempre visible:

| Sub-módulo            | Descripción                                                |
| --------------------- | ---------------------------------------------------------- |
| Hidratación           | Tracker de vasos de agua + recordatorios configurables     |
| Nutrición             | Registro de comidas (`log_meal_sheet`)                     |
| Retos físicos         | Catálogo de retos progresivos (`challenges_controller`)    |
| Yoga & Cuidado facial | Catálogo visual con timer de ejercicios                    |
| Afirmaciones          | Frases diarias de autodominio                              |
| Sonidos ambient       | Reproductor de audio de fondo (`just_audio`)               |

---

## 12. Filosofía — Biblioteca de 100 Sabios

- Catálogo estático curado de 100 figuras históricas (Estoicos, Grecia Clásica, Guerreros,
  Místicos, Contemporáneos) para autodominio diario.
- Ruta: `/thinkers` · Screen: `thinkers_library_screen.dart`.
- Filtro por categoría, búsqueda, y detalle en bottom sheet.

---

## 13. Assets

```
assets/
├── .env                    # Variables de entorno (Supabase URL + anon key)
├── sounds/                 # Audio ambient para Pomodoro y Wellness
└── images/                 # Recursos gráficos (logo, ilustraciones)
```

---

## 14. Roadmap — estado actual

| Fase | Descripción                                                         | Estado       |
| ---- | ------------------------------------------------------------------- | ------------ |
| 0    | Supabase + schema.sql + Auth + Onboarding + Tema visual             | ✅ Completo  |
| 1    | Motor de hábitos + Pomodoro + Launcher (dashboard)                  | ✅ Completo  |
| 2    | Módulos condicionales: Religión, NoFap, Ciclo Menstrual             | ✅ Completo  |
| 3    | Finanzas + Gratitud + Catálogo hábitos + Filosofía + Wellness       | ✅ Completo  |
| 4    | Gamificación unificada + Analítica (semana/mes/año)                 | ✅ Completo  |
| 5    | Offline-first (Drift + sync engine) + Notificaciones inteligentes   | ✅ Completo  |
| 6    | Privacidad avanzada (biometría, PIN, modo discreto, cifrado)        | ✅ Completo  |
| 7    | Splash screen personalizado (reemplazo del logo Flutter)            | 🔄 Pendiente |
| 8    | Widgets nativos de pantalla de inicio (home_widget bridge)          | 🔄 Pendiente |
| 9    | Pulido visual, internacionalización, monetización freemium/premium  | 🔄 Pendiente |

---

## 15. Pendiente de definir

- **Modelo de monetización**: qué módulos son premium (Filosofía, Analytics avanzado, etc.).
- **Splash screen**: assets listos en `/documentos adicionales/focushabitual_modern_logo/`.
  Requiere actualizar `launch_background.xml` (Android ≤11) y `values-v31/styles.xml`
  (Android 12+), más `LaunchScreen.storyboard` en iOS.
- **Widgets nativos**: decidir si implementar `home_widget` para counter NoFap y resumen de
  hábitos en la pantalla de inicio del SO.
- **Push notifications**: configurar FCM (Android) y APNs (iOS) + pg_cron en Supabase para
  notificaciones server-driven.
- **Proveedor de pasajes bíblicos**: API externa vs. contenido propio curado (actualmente
  hardcodeado en `religion_content.dart`).
