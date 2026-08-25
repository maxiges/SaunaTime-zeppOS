import 'package:flutter/material.dart';

import '../../features/sessions/domain/models/sauna_phase.dart';
import '../../features/sessions/domain/models/session_source.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('pl'),
    Locale('de'),
    Locale('fr'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Sauna Time',
      'tab_dashboard': 'Dashboard',
      'tab_history': 'History',
      'tab_calendar': 'Calendar',
      'sessions_total': 'Total sessions',
      'sauna_time_total': 'Sauna time',
      'weekly_activity': '7-day activity',
      'weekly_total': 'min total',
      'recent_sessions': 'Recent sessions',
      'view_all': 'View all',
      'no_sessions_yet': 'No recorded sessions yet',
      'add_first_session_prompt':
          'Add your first session manually using the button below.',
      'add_session': 'Add session',
      'edit_session': 'Edit sauna session',
      'save_session': 'Save session',
      'save_changes': 'Save changes',
      'saving': 'Saving...',
      'session_date': 'Session date',
      'start_time': 'Start time',
      'duration_minutes': 'Duration (minutes) *',
      'duration_hint': 'e.g. 15',
      'temperature_label': 'Temperature (°C) (optional)',
      'temperature_hint': 'e.g. 85',
      'notes_label': 'Notes / comments (optional)',
      'notes_hint': 'e.g. 3 rounds, good humidity, menthol...',
      'change': 'Change',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'history_title': 'Session History',
      'source_all': 'All sources',
      'source_manual': 'Manual',
      'source_watch': 'Watch (HTTP)',
      'source_label': 'Source',
      'sort_label': 'Sort',
      'sort_newest': 'Newest',
      'sort_oldest': 'Oldest',
      'sort_longest': 'Longest',
      'sort_shortest': 'Shortest',
      'no_history_sessions': 'No sauna session history',
      'no_filtered_sessions': 'No sessions match current filter',
      'delete_session_title': 'Delete session',
      'delete_session_confirm':
          'Are you sure you want to delete this sauna session?',
      'session_deleted': 'Session has been deleted.',
      'calendar_title': 'Session Calendar',
      'calendar_sessions_for': 'Sessions:',
      'calendar_no_sessions': 'No sessions on this day',
      'calendar_no_selection': 'Pick a date or range',
      'calendar_clear_range': 'Clear range',
      'calendar_mode_single': 'Mode: day',
      'calendar_mode_range': 'Mode: range',
      'details_title': 'Session Details',
      'details_duration': 'Duration',
      'details_time_range': 'Time range',
      'details_temperature': 'Temperature',
      'details_avg_hr': 'Average heart rate',
      'details_max_hr': 'Session max heart rate',
      'add_hr_section': 'Heart rate (optional)',
      'avg_hr_label': 'Average heart rate',
      'min_hr_label': 'Minimum heart rate',
      'max_hr_label': 'Maximum heart rate',
      'hr_linear_hint': 'Provide min. and max. heart rate — the app will generate a linear (rising) heart-rate curve across the session.',
      'error_hr_range': 'Enter a heart rate between 30 and 250.',
      'error_hr_min_max_both':
          'Provide both a minimum and a maximum heart rate.',
      'error_hr_min_max_order':
          'Minimum heart rate must be lower than maximum.',
      'details_notes': 'Notes & impressions',
      'no_telemetry_title': 'No continuous telemetry data',
      'no_telemetry_desc': 'Continuous heart rate and temperature charts are available for sessions imported from smartwatch.',
      'chart_hr_title': 'Heart rate during session',
      'chart_temp_title': 'Temperature profile over time',
      'chart_min': 'Min',
      'chart_avg': 'Avg',
      'chart_max': 'Max',
      'server_screen_title': 'HTTP Server & Watch',
      'server_active': 'Server Active',
      'server_stopped': 'Server Stopped',
      'server_port': 'Listening port:',
      'server_local_ip': 'IP Address (local):',
      'server_localhost_note': 'Tip: If you use the Zepp app on the same device, you can use "localhost" instead of the IP address in your watch settings.',
      'server_post_endpoint': 'POST Endpoint:',
      'copy_curl': 'Copy cURL command for test',
      'watch_phase_cooling': 'Cooling',
      'watch_phase_heating': 'Heating',
      'watch_phase_resting': 'Resting',
      'watch_simulator': 'Smartwatch Simulator',
      'watch_simulator_desc': 'Test smartwatch integration by generating a realistic telemetry dataset (heart rate over time, temperature, stats).',
      'generate_watch_session': 'Generate & import watch session',
      'http_logs_title': 'HTTP Request Log',
      'http_logs_print': 'Print logs to console',
      'http_logs_printed': 'Printed {count} log entries to console',
      'no_http_logs': 'No HTTP requests recorded',
      'clear_logs': 'Clear logs',
      'backup_title': 'Backup & Export',
      'backup_export_title': 'Export session history',
      'backup_export_desc':
          'Save all your sessions in universal JSON or CSV spreadsheet format.',
      'backup_export_json_btn': 'Export JSON (file)',
      'backup_export_csv_btn': 'Export CSV (file)',
      'backup_import_title': 'Import sessions from JSON',
      'backup_import_desc': 'Pick a backup file (.json) from your device to restore your history.',
      'backup_import_btn': 'Import from file',
      'select_language': 'Select language',
      'language_pl': 'Polski',
      'language_en': 'English',
      'language_de': 'Deutsch',
      'language_fr': 'Français',
      'day_mon': 'Mon',
      'day_tue': 'Tue',
      'day_wed': 'Wed',
      'day_thu': 'Thu',
      'day_fri': 'Fri',
      'day_sat': 'Sat',
      'day_sun': 'Sun',
      'settings_title': 'Settings',
      // ── Settings: section navigation ──
      'settings_language_subtitle': 'Choose the app language',
      'settings_theme_subtitle': 'Theme: system, light or dark',
      'settings_profile_subtitle': 'Sex, weight and age (calorie calculation)',
      'settings_watch_section': 'Watch / HTTP',
      'settings_watch_subtitle': 'HTTP server and watch session import',
      'settings_about_subtitle': 'Version and app information',
      'settings_language_section': 'App language',
      'settings_language_dev_hint': 'To add a new language, open lib/core/localization/app_localizations.dart and add a new block in the _localizedValues map following the existing translations as a template.',
      'settings_about_section': 'About',
      'settings_platform_label': 'Platform',
      'settings_danger_zone': 'Danger Zone',
      'settings_clear_data': 'Clear all data',
      'settings_clear_data_subtitle': 'Irreversibly delete all session history',
      // ── Theme / appearance ──
      'settings_theme_section': 'Appearance',
      'theme_mode_system': 'System',
      'theme_mode_light': 'Light',
      'theme_mode_dark': 'Dark',
      // ── User profile / calories ──
      'settings_profile_section': 'Profile',
      'profile_sex': 'Sex',
      'profile_male': 'Male',
      'profile_female': 'Female',
      'profile_weight': 'Weight',
      'profile_age': 'Age',
      'profile_age_unit': 'years',
      'profile_preferred_sauna_type': 'Preferred sauna type',
      'calorie_button': 'Calories burned',
      'calorie_hint': 'Estimated energy expenditure (time, heart rate, temperature, profile)',
      'calorie_estimate': 'Estimated calories burned',
      'calorie_need_hr': 'Average heart rate is required for the calculation.',
      'home_calories_based_on': 'based on {count} sessions with heart rate',
      'home_calories_today': 'Today',
      'home_calories_week': 'This week',
      'calorie_samples_label': 'Interval measurement',
      'calorie_samples_count': 'based on {count} heart rate samples',
      'chart_zoom_hint': 'Tap to zoom the chart',
      'chart_tap_hint': 'Tap the chart to see the exact value at a point',
      'chart_samples_count': '{count} samples',
      'temp_kind_sauna': 'Sauna temperature',
      'temp_kind_body': 'Body temperature',
      'calorie_body_temp_note':
          'No temperature adjustment — this is body temperature, not sauna.',
      'calorie_estimate_title': 'Calories Burned Details',
      'calorie_profile_used': 'Profile used:',
      'calorie_formula_note_title': 'About the calculation',
      'calorie_formula_note_desc': 'Calculations are based on the Keytel formula, taking into account heart rate, age, weight, and sex.',
      'calorie_per_min': 'kcal/min',
      'no_measurement': 'No measurement',
      'minutes_abbr': 'min',
      'seconds_abbr': 's',
      'bpm_abbr': 'bpm',
      // ── Add / edit session ──
      'add_session_title': 'Add sauna session',
      'session_sauna_type': 'Sauna type',
      'sauna_type_dry': 'Dry',
      'sauna_type_steam': 'Steam',
      'error_duration_required': 'Enter session duration',
      'error_duration_positive': 'Duration must be a number greater than zero',
      'error_temperature_range': 'Enter a valid temperature (1 - 140 °C)',
      'session_updated_saved': 'Session changes have been saved!',
      'session_saved': 'Session saved successfully!',
      'error_saving_session': 'An error occurred while saving.',
      'watch_edit_locked_note': 'Watch data — measurements (heart rate, temperature) cannot be edited.',
      // ── History ──
      'error_delete_session': 'Failed to delete the session.',
      'avg_abbr': 'Avg',
      'confirm_delete_session': 'Are you sure you want to delete the session from {date} ({minutes} {unit})?',
      'clear_data_confirm_title': 'Delete everything',
      'clear_data_confirm_message': 'Are you sure you want to delete all session history? This action cannot be undone.',
      'clear_data_success': 'All data has been deleted.',
      // ── Calendar ──
      'calendar_min_in_sauna': '{minutes} min in sauna',
      // ── Session details ──
      'phases_label': 'Sauna phases',
      // ── HTTP Server / Watch ──
      'change_port_tooltip': 'Change port',
      'server_change_port_title': 'Change HTTP server port',
      'server_port_number': 'Port number',
      'server_port_hint': 'e.g. 8080, 8081, 9090',
      'server_change_and_restart': 'Change & restart',
      'server_restarted': 'Server restarted on port {port}',
      'curl_copied': 'Example cURL command copied to clipboard!',
      'phase_count_label': 'Number of sauna phases',
      'watch_session_imported':
          'Watch session imported successfully ({count} {stages})!',
      'watch_session_failed': 'Failed to send watch session.',
      'logs_count': '{count} entries',
      // ── Backup ──
      'backup_export_saved': 'Backup saved to file',
      'backup_imported': 'Successfully imported {count} new sessions!',
      'backup_import_error': 'JSON import error: {error}',
      'backup_entries': '{count} entries',
      'backup_export_desc_count': 'Save all your sessions ({count} entries) in universal JSON or CSV spreadsheet format.',
      // ── About ──
      'about_description': 'This is the official companion application for the „Sauna Time” ecosystem, designed to read and analyze data from your sauna sessions.',
      'about_contact_support': 'Contact Support:',
    },
    'pl': {
      'app_title': 'Sauna Time',
      'tab_dashboard': 'Pulpit',
      'tab_history': 'Historia',
      'tab_calendar': 'Kalendarz',
      'sessions_total': 'Sesji łącznie',
      'sauna_time_total': 'Czas w saunie',
      'weekly_activity': 'Aktywność z 7 dni',
      'weekly_total': 'min łącznie',
      'recent_sessions': 'Ostatnie sesje',
      'view_all': 'Zobacz wszystkie',
      'no_sessions_yet': 'Brak zarejestrowanych sesji',
      'add_first_session_prompt':
          'Dodaj swoją pierwszą sesję ręcznie za pomocą przycisku poniżej.',
      'add_session': 'Dodaj sesję',
      'edit_session': 'Edytuj sesję sauny',
      'save_session': 'Zapisz sesję',
      'save_changes': 'Zapisz zmiany',
      'saving': 'Zapisywanie...',
      'session_date': 'Data sesji',
      'start_time': 'Godzina rozpoczęcia',
      'duration_minutes': 'Czas trwania (minuty) *',
      'duration_hint': 'np. 15',
      'temperature_label': 'Temperatura (°C) (opcjonalnie)',
      'temperature_hint': 'np. 85',
      'notes_label': 'Notatki / uwagi (opcjonalnie)',
      'notes_hint': 'np. 3 serie, dobra wilgotność, mentol...',
      'change': 'Zmień',
      'cancel': 'Anuluj',
      'delete': 'Usuń',
      'history_title': 'Historia sesji',
      'source_all': 'Wszystkie źródła',
      'source_manual': 'Ręczne',
      'source_watch': 'Zegarek (HTTP)',
      'source_label': 'Źródło',
      'sort_label': 'Sortuj',
      'sort_newest': 'Najnowsze',
      'sort_oldest': 'Najstarsze',
      'sort_longest': 'Najdłuższe',
      'sort_shortest': 'Najkrótsze',
      'no_history_sessions': 'Brak historii sesji saunowania',
      'no_filtered_sessions': 'Brak sesji spełniających kryteria filtra',
      'delete_session_title': 'Usuń sesję',
      'delete_session_confirm':
          'Czy na pewno chcesz usunąć tę sesję saunowania?',
      'session_deleted': 'Sesja została usunięta.',
      'calendar_title': 'Kalendarz sesji',
      'calendar_sessions_for': 'Sesje:',
      'calendar_no_sessions': 'Brak sesji w tym dniu',
      'calendar_no_selection': 'Wybierz datę lub zakres',
      'calendar_clear_range': 'Wyczyść zakres',
      'calendar_mode_single': 'Tryb: dzień',
      'calendar_mode_range': 'Tryb: zakres',
      'details_title': 'Szczegóły sesji',
      'details_duration': 'Czas trwania',
      'details_time_range': 'Przedział godzin',
      'details_temperature': 'Temperatura',
      'details_avg_hr': 'Średnie tętno',
      'details_max_hr': 'Maksymalne tętno sesji',
      'add_hr_section': 'Tętno (opcjonalnie)',
      'avg_hr_label': 'Średnie tętno',
      'min_hr_label': 'Minimalne tętno',
      'max_hr_label': 'Maksymalne tętno',
      'hr_linear_hint': 'Podaj min. i maks. tętno — aplikacja wygeneruje liniowy (rosnący) przebieg tętna w trakcie sesji.',
      'error_hr_range': 'Podaj tętno w zakresie 30–250.',
      'error_hr_min_max_both':
          'Podaj zarówno minimalną, jak i maksymalną wartość tętna.',
      'error_hr_min_max_order':
          'Minimalne tętno musi być niższe niż maksymalne.',
      'details_notes': 'Notatki i uwagi',
      'no_telemetry_title': 'Brak ciągłych danych telemetrycznych',
      'no_telemetry_desc': 'Wykresy pulsu i temperatury w czasie są dostępne dla sesji rejestrowanych przez smartwatch.',
      'chart_hr_title': 'Przebieg tętna w saunie',
      'chart_temp_title': 'Profil temperatury w czasie',
      'chart_min': 'Min',
      'chart_avg': 'Średnia',
      'chart_max': 'Max',
      'server_screen_title': 'Serwer HTTP & Zegarek',
      'server_active': 'Serwer Aktywny',
      'server_stopped': 'Serwer Zatrzymany',
      'server_port': 'Port nasłuchu:',
      'server_local_ip': 'Adres IP (lokalny):',
      'server_localhost_note': 'Wskazówka: Jeśli używasz aplikacji Zepp na tym samym urządzeniu, w ustawieniach zegarka możesz wpisać "localhost" zamiast adresu IP.',
      'server_post_endpoint': 'Endpoint POST:',
      'copy_curl': 'Kopiuj polecenie cURL do testu',
      'watch_phase_cooling': 'Chłodzenie',
      'watch_phase_heating': 'Nagrzewanie',
      'watch_phase_resting': 'Odpoczywanie',
      'watch_simulator': 'Symulator zegarka',
      'watch_simulator_desc': 'Możesz przetestować integrację z zegarkiem, generując pełny pakiet danych telemetrycznych (tętno w czasie, temperatura, statystyki).',
      'generate_watch_session': 'Generuj i zaimportuj sesję z zegarka',
      'http_logs_title': 'Dziennik żądań HTTP',
      'http_logs_print': 'Drukuj logi do konsoli',
      'http_logs_printed': 'Wydrukowano {count} wpisów logów w konsoli',
      'no_http_logs': 'Brak zarejestrowanych żądań HTTP',
      'clear_logs': 'Wyczyść logi',
      'backup_title': 'Kopia zapasowa & Eksport',
      'backup_export_title': 'Eksportuj historię sesji',
      'backup_export_desc': 'Zapisz wszystkie swoje sesje w uniwersalnym formacie JSON lub arkuszu CSV.',
      'backup_export_json_btn': 'Eksportuj JSON (plik)',
      'backup_export_csv_btn': 'Eksportuj CSV (plik)',
      'backup_import_title': 'Importuj sesje z kopii JSON',
      'backup_import_desc': 'Wybierz plik kopii zapasowej (.json) z urządzenia, aby przywrócić historię sesji.',
      'backup_import_btn': 'Importuj z pliku',
      'select_language': 'Wybierz język',
      'language_pl': 'Polski',
      'language_en': 'English',
      'language_de': 'Deutsch',
      'language_fr': 'Français',
      'day_mon': 'Pn',
      'day_tue': 'Wt',
      'day_wed': 'Śr',
      'day_thu': 'Cz',
      'day_fri': 'Pt',
      'day_sat': 'Sb',
      'day_sun': 'Nd',
      'settings_title': 'Ustawienia',
      // ── Settings: section navigation ──
      'settings_language_subtitle': 'Wybierz język aplikacji',
      'settings_theme_subtitle': 'Motyw: systemowy, jasny lub ciemny',
      'settings_profile_subtitle': 'Płeć, waga i wiek (kalkulacja kalorii)',
      'settings_watch_section': 'Zegarek / HTTP',
      'settings_watch_subtitle': 'Serwer HTTP i import sesji z zegarka',
      'settings_about_subtitle': 'Wersja i informacje o aplikacji',
      'settings_language_section': 'Język aplikacji',
      'settings_language_dev_hint': 'Aby dodać nowy język, otwórz plik lib/core/localization/app_localizations.dart i dodaj nowy blok w mapie _localizedValues, wzorując się na istniejących tłumaczeniach.',
      'settings_about_section': 'O aplikacji',
      'settings_platform_label': 'Platforma',
      'settings_danger_zone': 'Strefa niebezpieczna',
      'settings_clear_data': 'Wyczyść wszystkie dane',
      'settings_clear_data_subtitle': 'Usuń nieodwracalnie całą historię sesji',
      // ── Theme / appearance ──
      'settings_theme_section': 'Wygląd',
      'theme_mode_system': 'Systemowy',
      'theme_mode_light': 'Jasny',
      'theme_mode_dark': 'Ciemny',
      // ── User profile / calories ──
      'settings_profile_section': 'Profil',
      'profile_sex': 'Płeć',
      'profile_male': 'Mężczyzna',
      'profile_female': 'Kobieta',
      'profile_weight': 'Waga',
      'profile_age': 'Wiek',
      'profile_age_unit': 'lat',
      'profile_preferred_sauna_type': 'Preferowany typ sauny',
      'calorie_button': 'Spalone kalorie',
      'calorie_hint':
          'Orientacyjne zużycie energii (czas, tętno, temperatura, profil)',
      'calorie_estimate': 'Szacowane spalone kalorie',
      'calorie_need_hr': 'Do kalkulacji potrzebne jest średnie tętno sesji.',
      'home_calories_based_on': 'na podstawie {count} sesji z pomiarem tętna',
      'home_calories_today': 'Dziś',
      'home_calories_week': 'Ten tydzień',
      'calorie_samples_label': 'Pomiar odcinkowy',
      'calorie_samples_count': 'na podstawie {count} próbek tętna',
      'chart_zoom_hint': 'Dotknij, aby powiększyć wykres',
      'chart_tap_hint': 'Dotknij wykres, aby zobaczyć wartości w danym punkcie',
      'chart_samples_count': '{count} próbek',
      'temp_kind_sauna': 'Temperatura sauny',
      'temp_kind_body': 'Temperatura ciała',
      'calorie_body_temp_note':
          'Brak korekty temperaturowej — to temperatura ciała, nie sauny.',
      'calorie_estimate_title': 'Szczegóły spalonych kalorii',
      'calorie_profile_used': 'Użyty profil:',
      'calorie_formula_note_title': 'O kalkulacji',
      'calorie_formula_note_desc': 'Obliczenia opierają się na formule Keytela, biorąc pod uwagę tętno, wiek, wagę oraz płeć.',
      'calorie_per_min': 'kcal/min',
      'no_measurement': 'Brak pomiaru',
      'minutes_abbr': 'min',
      'seconds_abbr': 's',
      'bpm_abbr': 'bpm',
      // ── Add / edit session ──
      'add_session_title': 'Dodaj sesję sauny',
      'session_sauna_type': 'Typ sauny',
      'sauna_type_dry': 'Sucha',
      'sauna_type_steam': 'Parowa',
      'error_duration_required': 'Podaj czas trwania sesji',
      'error_duration_positive': 'Czas musi być liczbą większą od zera',
      'error_temperature_range': 'Podaj prawidłową temperaturę (1 - 140 °C)',
      'session_updated_saved': 'Zmiany w sesji zostały zapisane!',
      'session_saved': 'Sesja została pomyślnie zapisana!',
      'error_saving_session': 'Wystąpił błąd podczas zapisu.',
      'watch_edit_locked_note':
          'Dane z zegarka — pomiarów (tętno, temperatura) nie można edytować.',
      // ── History ──
      'error_delete_session': 'Nie udało się usunąć sesji.',
      'avg_abbr': 'Śr.',
      'confirm_delete_session':
          'Czy na pewno chcesz usunąć sesję z dnia {date} ({minutes} {unit})?',
      'clear_data_confirm_title': 'Usuń wszystko',
      'clear_data_confirm_message': 'Czy na pewno chcesz usunąć całą historię sesji? Tej operacji nie można cofnąć.',
      'clear_data_success': 'Wszystkie dane zostały usunięte.',
      // ── Calendar ──
      'calendar_min_in_sauna': '{minutes} min w saunie',
      // ── Session details ──
      'phases_label': 'Etapy saunowania',
      // ── HTTP Server / Watch ──
      'change_port_tooltip': 'Zmień port',
      'server_change_port_title': 'Zmień port serwera HTTP',
      'server_port_number': 'Numer portu',
      'server_port_hint': 'np. 8080, 8081, 9090',
      'server_change_and_restart': 'Zmień i zrestartuj',
      'server_restarted': 'Serwer zrestartowany na porcie {port}',
      'curl_copied': 'Skopiowano przykładowe polecenie cURL do schowka!',
      'phase_count_label': 'Liczba etapów saunowania',
      'watch_session_imported':
          'Pomyślnie zaimportowano sesję z zegarka ({count} {stages})!',
      'watch_session_failed': 'Nie udało się przesłać sesji z zegarka.',
      'logs_count': '{count} wpisów',
      // ── Backup ──
      'backup_export_saved': 'Kopia zapasowa zapisana do pliku',
      'backup_imported': 'Pomyślnie zaimportowano {count} nowych sesji!',
      'backup_import_error': 'Błąd importu JSON: {error}',
      'backup_entries': '{count} wpisów',
      'backup_export_desc_count': 'Zapisz wszystkie swoje sesje ({count} wpisów) in uniwersalnym formacie JSON lub arkuszu CSV.',
      // ── About ──
      'about_description': 'To jest oficjalna aplikacja towarzysząca ekosystemowi „Sauna Time”, służąca do odczytu i analizy danych z Twoich sesji saunowania.',
      'about_contact_support': 'Kontakt z pomocą techniczną:',
    },
    'de': {
      'app_title': 'Sauna Time',
      'tab_dashboard': 'Übersicht',
      'tab_history': 'Verlauf',
      'tab_calendar': 'Kalender',
      'sessions_total': 'Sitzungen gesamt',
      'sauna_time_total': 'Saunazeit gesamt',
      'weekly_activity': '7-Tage-Aktivität',
      'weekly_total': 'Min. gesamt',
      'recent_sessions': 'Letzte Sitzungen',
      'view_all': 'Alle anzeigen',
      'no_sessions_yet': 'Noch keine Saunasitzungen vorhanden',
      'add_first_session_prompt':
          'Füge deine erste Sitzung manuell über die Schaltfläche unten hinzu.',
      'add_session': 'Sitzung hinzufügen',
      'edit_session': 'Sitzung bearbeiten',
      'save_session': 'Sitzung speichern',
      'save_changes': 'Änderungen speichern',
      'saving': 'Wird gespeichert...',
      'session_date': 'Datum',
      'start_time': 'Startzeit',
      'duration_minutes': 'Dauer (Minuten) *',
      'duration_hint': 'z.B. 15',
      'temperature_label': 'Temperatur (°C) (optional)',
      'temperature_hint': 'z.B. 85',
      'notes_label': 'Notizen (optional)',
      'notes_hint': 'z.B. 3 Durchgänge, Menthol...',
      'change': 'Ändern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'history_title': 'Sitzungsverlauf',
      'source_all': 'Alle Quellen',
      'source_manual': 'Manuell',
      'source_watch': 'Smartwatch (HTTP)',
      'source_label': 'Quelle',
      'sort_label': 'Sortieren',
      'sort_newest': 'Neueste',
      'sort_oldest': 'Älteste',
      'sort_longest': 'Längste',
      'sort_shortest': 'Kürzeste',
      'no_history_sessions': 'Keine Saunasitzungen aufgezeichnet',
      'no_filtered_sessions': 'Keine Sitzungen entsprechen dem Filter',
      'delete_session_title': 'Sitzung löschen',
      'delete_session_confirm':
          'Möchtest du diese Saunasitzung wirklich löschen?',
      'session_deleted': 'Sitzung wurde gelöscht.',
      'calendar_title': 'Sitzungskalender',
      'calendar_sessions_for': 'Sitzungen am:',
      'calendar_no_sessions': 'Keine Sitzungen an diesem Tag',
      'calendar_no_selection': 'Datum oder Bereich wählen',
      'calendar_clear_range': 'Bereich löschen',
      'calendar_mode_single': 'Modus: Tag',
      'calendar_mode_range': 'Modus: Bereich',
      'details_title': 'Sitzungsdetails',
      'details_duration': 'Dauer',
      'details_time_range': 'Zeitspanne',
      'details_temperature': 'Temperatur',
      'details_avg_hr': 'Durchschnittspuls',
      'details_max_hr': 'Maximalpuls',
      'add_hr_section': 'Herzfrequenz (optional)',
      'avg_hr_label': 'Durchschnittspuls',
      'min_hr_label': 'Min. Puls',
      'max_hr_label': 'Max. Puls',
      'hr_linear_hint': 'Gib min. und max. Puls an — die App erzeugt einen linearen (steigenden) Pulsverlauf über die Sitzung.',
      'error_hr_range': 'Gib einen Puls zwischen 30 und 250 angegeben.',
      'error_hr_min_max_both':
          'Gib sowohl einen minimalen als auch einen maximalen Puls an.',
      'error_hr_min_max_order':
          'Der minimale Puls muss niedriger sein als der maximale.',
      'details_notes': 'Notizen & Eindrücke',
      'no_telemetry_title': 'Keine kontinuierlichen Telemetriedaten',
      'no_telemetry_desc': 'Verlaufskurven für Puls und Temperatur sind für Smartwatch-Sitzungen verfügbar.',
      'chart_hr_title': 'Pulsverlauf während der Sitzung',
      'chart_temp_title': 'Temperaturverlauf über die Zeit',
      'chart_min': 'Min',
      'chart_avg': 'Durchschn.',
      'chart_max': 'Max',
      'server_screen_title': 'HTTP-Server & Smartwatch',
      'server_active': 'Server aktiv',
      'server_stopped': 'Server gestoppt',
      'server_port': 'Port:',
      'server_local_ip': 'IP-Adresse (lokal):',
      'server_localhost_note': 'Tipp: Wenn Sie die Zepp-App auf demselben Gerät verwenden, können Sie in Ihren Uhreinstellungen "localhost" anstelle der IP-Adresse verwenden.',
      'server_post_endpoint': 'POST-Endpunkt:',
      'copy_curl': 'cURL-Befehl kopieren',
      'watch_phase_cooling': 'Abkühlung',
      'watch_phase_heating': 'Aufheizen',
      'watch_phase_resting': 'Ruhe',
      'watch_simulator': 'Smartwatch-Simulator',
      'watch_simulator_desc': 'Teste die Integration mit simulierten Telemetriedaten (Pulsverlauf, Temperatur, Statistiken).',
      'generate_watch_session': 'Smartwatch-Sitzung simulieren',
      'http_logs_title': 'HTTP-Anfrageprotokoll',
      'http_logs_print': 'Protokoll in Konsole drucken',
      'http_logs_printed':
          '{count} Protokolleinträge in der Konsole ausgegeben',
      'no_http_logs': 'Keine Anfragen protokolliert',
      'clear_logs': 'Protokoll löschen',
      'backup_title': 'Sicherung & Export',
      'backup_export_title': 'Verlauf exportieren',
      'backup_export_desc':
          'Speichere alle Sitzungen im JSON- oder CSV-Tabellenformat.',
      'backup_export_json_btn': 'JSON exportieren (Datei)',
      'backup_export_csv_btn': 'CSV exportieren (Datei)',
      'backup_import_title': 'Sitzungen aus JSON importieren',
      'backup_import_desc': 'Wähle eine Sicherungsdatei (.json) auf deinem Gerät aus, um deinen Verlauf wiederherzustellen.',
      'backup_import_btn': 'Aus Datei importieren',
      'select_language': 'Sprache auswählen',
      'language_pl': 'Polski',
      'language_en': 'English',
      'language_de': 'Deutsch',
      'language_fr': 'Français',
      'day_mon': 'Mo',
      'day_tue': 'Di',
      'day_wed': 'Mi',
      'day_thu': 'Do',
      'day_fri': 'Fr',
      'day_sat': 'Sa',
      'day_sun': 'So',
      'settings_title': 'Einstellungen',
      // ── Einstellungen: Abschnittsnavigation ──
      'settings_language_subtitle': 'App-Sprache auswählen',
      'settings_theme_subtitle': 'Design: System, Hell oder Dunkel',
      'settings_profile_subtitle':
          'Geschlecht, Gewicht und Alter (Kalorienberechnung)',
      'settings_watch_section': 'Uhr / HTTP',
      'settings_watch_subtitle': 'HTTP-Server and Import von Watch-Sitzungen',
      'settings_about_subtitle': 'Version and App-Informationen',
      'settings_language_section': 'App-Sprache',
      'settings_language_dev_hint': 'Um eine neue Sprache hinzuzufügen, otwórz plik lib/core/localization/app_localizations.dart i dodaj nowy blok w mapie _localizedValues, wzorując się na istniejących tłumaczeniach.',
      'settings_about_section': 'Über die App',
      'settings_platform_label': 'Plattform',
      'settings_danger_zone': 'Gefahrenzone',
      'settings_clear_data': 'Alle Daten löschen',
      'settings_clear_data_subtitle':
          'Gesamten Sitzungsverlauf unwiderruflich löschen',
      // ── Darstellung / Design ──
      'settings_theme_section': 'Darstellung',
      'theme_mode_system': 'System',
      'theme_mode_light': 'Hell',
      'theme_mode_dark': 'Dunkel',
      // ── Benutzerprofil / Kalorien ──
      'settings_profile_section': 'Profil',
      'profile_sex': 'Geschlecht',
      'profile_male': 'Männlich',
      'profile_female': 'Weiblich',
      'profile_weight': 'Gewicht',
      'profile_age': 'Alter',
      'profile_age_unit': 'Jahre',
      'profile_preferred_sauna_type': 'Bevorzugter Saunatyp',
      'calorie_button': 'Verbrannte Kalorien',
      'calorie_hint': 'Geschätzter Energieverbrauch (Zeit, Herzfrequenz, Temperatur, Profil)',
      'calorie_estimate': 'Geschätzte verbrannte Kalorien',
      'calorie_need_hr': 'Für die Berechnung wird die durchschnittliche Herzfrequenz benötigt.',
      'home_calories_based_on':
          'basierend auf {count} Sitzungen mit Herzfrequenz',
      'home_calories_today': 'Heute',
      'home_calories_week': 'Diese Woche',
      'calorie_samples_label': 'Abschnittsmessung',
      'calorie_samples_count': 'basierend auf {count} Herzfrequenzmesswerten',
      'chart_zoom_hint': 'Zum Vergrößern des Diagramms tippen',
      'chart_tap_hint':
          'Tippe auf das Diagramm, um den Wert an einer Stelle zu sehen',
      'chart_samples_count': '{count} Messwerte',
      'temp_kind_sauna': 'Saunatemperatur',
      'temp_kind_body': 'Körpertemperatur',
      'calorie_body_temp_note':
          'Keine Temperaturkorrektur — das ist Körpertemperatur, nicht Sauna.',
      'calorie_estimate_title': 'Details zu verbrannten Kalorien',
      'calorie_profile_used': 'Verwendetes Profil:',
      'calorie_formula_note_title': 'Über die Berechnung',
      'calorie_formula_note_desc': 'Die Berechnungen basieren na der Keytel-Formel unter Berücksichtigung von Herzfrequenz, Alter, Gewicht und Geschlecht.',
      'calorie_per_min': 'kcal/min',
      'no_measurement': 'Keine Messung',
      'minutes_abbr': 'Min.',
      'seconds_abbr': 's',
      'bpm_abbr': 'bpm',
      // ── Sitzung hinzufügen / bearbeiten ──
      'add_session_title': 'Saunasitzung hinzufügen',
      'session_sauna_type': 'Saunatyp',
      'sauna_type_dry': 'Trocken',
      'sauna_type_steam': 'Dampf',
      'error_duration_required': 'Bitte Sitzungsdauer angeben',
      'error_duration_positive':
          'Die Dauer muss eine Zahl größer als null sein',
      'error_temperature_range': 'Gültige Temperatur angeben (1 - 140 °C)',
      'session_updated_saved': 'Änderungen wurden gespeichert!',
      'session_saved': 'Sitzung erfolgreich gespeichert!',
      'error_saving_session': 'Beim Speichern ist ein Fehler aufgetreten.',
      'watch_edit_locked_note': 'Uhr-Daten — Messwerte (Herzfrequenz, Temperatur) können nicht bearbeitet werden.',
      // ── Verlauf ──
      'error_delete_session': 'Sitzung konnte nicht gelöscht werden.',
      'avg_abbr': 'Durchschn.',
      'confirm_delete_session': 'Möchtest du die Sitzung vom {date} ({minutes} {unit}) wirklich löschen?',
      'clear_data_confirm_title': 'Alles löschen',
      'clear_data_confirm_message': 'Möchtest du wirklich den gesamten Sitzungsverlauf löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.',
      'clear_data_success': 'Alle Daten wurden gelöscht.',
      // ── Kalender ──
      'calendar_min_in_sauna': '{minutes} Min. in der Sauna',
      // ── Sitzungsdetails ──
      'phases_label': 'Saunaphasen',
      // ── HTTP-Server / Uhr ──
      'change_port_tooltip': 'Port ändern',
      'server_change_port_title': 'HTTP-Server-Port ändern',
      'server_port_number': 'Portnummer',
      'server_port_hint': 'z.B. 8080, 8081, 9090',
      'server_change_and_restart': 'Ändern & neu starten',
      'server_restarted': 'Server auf Port {port} neu gestartet',
      'curl_copied': 'Beispiel-cURL-Befehl in die Zwischenablage kopiert!',
      'phase_count_label': 'Anzahl der Saunaphasen',
      'watch_session_imported':
          'Smartwatch-Sitzung erfolgreich importiert ({count} {stages})!',
      'watch_session_failed':
          'Smartwatch-Sitzung konnte nicht gesendet werden.',
      'logs_count': '{count} Einträge',
      // ── Sicherung ──
      'backup_export_saved': 'Sicherung in Datei gespeichert',
      'backup_imported': 'Erfolgreich {count} neue Sitzungen importiert!',
      'backup_import_error': 'JSON-Importfehler: {error}',
      'backup_entries': '{count} Einträge',
      'backup_export_desc_count': 'Speichere alle Sitzungen ({count} Einträge) im JSON- oder CSV-Format.',
      // ── About ──
      'about_description': 'Dies ist die offizielle Begleit-App für das „Sauna Time”-Ökosystem, entwickelt zum Auslesen und Analysieren Ihrer Saunagänge.',
      'about_contact_support': 'Support kontaktieren:',
    },
    'fr': {
      'app_title': 'Sauna Time',
      'tab_dashboard': 'Tableau de bord',
      'tab_history': 'Historique',
      'tab_calendar': 'Calendrier',
      'sessions_total': 'Total des séances',
      'sauna_time_total': 'Temps total au sauna',
      'weekly_activity': 'Activité sur 7 jours',
      'weekly_total': 'min au total',
      'recent_sessions': 'Séances récentes',
      'view_all': 'Voir tout',
      'no_sessions_yet': 'Aucune séance enregistrée',
      'add_first_session_prompt': "Ajoutez votre première séance manuellement à l'aide du bouton ci-dessous.",
      'add_session': 'Ajouter une séance',
      'edit_session': 'Modifier la séance',
      'save_session': 'Enregistrer la séance',
      'save_changes': 'Enregistrer les modifications',
      'saving': 'Enregistrement...',
      'session_date': 'Date de la séance',
      'start_time': 'Heure de début',
      'duration_minutes': 'Durée (minutes) *',
      'duration_hint': 'ex. 15',
      'temperature_label': 'Température (°C) (facultatif)',
      'temperature_hint': 'ex. 85',
      'notes_label': 'Notes / remarques (facultatif)',
      'notes_hint': 'ex. 3 passages, bonne humidité, menthol...',
      'change': 'Changer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'history_title': 'Historique des séances',
      'source_all': 'Toutes les sources',
      'source_manual': 'Manuel',
      'source_watch': 'Montre (HTTP)',
      'source_label': 'Source',
      'sort_label': 'Trier',
      'sort_newest': 'Plus récentes',
      'sort_oldest': 'Plus anciennes',
      'sort_longest': 'Plus longues',
      'sort_shortest': 'Plus courtes',
      'no_history_sessions': 'Aucun historique de sauna',
      'no_filtered_sessions': 'Aucune séance ne correspond au filtre',
      'delete_session_title': 'Supprimer la séance',
      'delete_session_confirm': 'Voulez-vous vraiment supprimer cette séance ?',
      'session_deleted': 'La séance a été supprimée.',
      'calendar_title': 'Calendrier des séances',
      'calendar_sessions_for': 'Séances du :',
      'calendar_no_sessions': 'Aucune séance ce jour-là',
      'calendar_no_selection': 'Choisir une date ou plage',
      'calendar_clear_range': 'Effacer la plage',
      'calendar_mode_single': 'Mode: jour',
      'calendar_mode_range': 'Mode: plage',
      'details_title': 'Détails de la séance',
      'details_duration': 'Durée',
      'details_time_range': 'Plage horaire',
      'details_temperature': 'Température',
      'details_avg_hr': 'Fréquence cardiaque moyenne',
      'details_max_hr': 'Fréquence cardiaque max',
      'add_hr_section': 'Fréquence cardiaque (optionnel)',
      'avg_hr_label': 'Fréquence cardiaque moyenne',
      'min_hr_label': 'Fréquence min',
      'max_hr_label': 'Fréquence max',
      'hr_linear_hint': "Indiquez les fréquences min. et max. — l'application générera une courbe linéaire (croissante) sur la séance.",
      'error_hr_range': 'Indiquez une fréquence entre 30 et 250.',
      'error_hr_min_max_both': 'Indiquez une fréquence minimale et maximale.',
      'error_hr_min_max_order':
          'La fréquence minimale doit être inférieure à la maximale.',
      'details_notes': 'Notes et impressions',
      'no_telemetry_title': 'Aucune donnée télémétrique continue',
      'no_telemetry_desc': 'Les graphiques continus de fréquence cardiaque et de température sont disponibles pour les séances enregistrées via montre.',
      'chart_hr_title': 'Évolution de la fréquence cardiaque',
      'chart_temp_title': 'Profil de température',
      'chart_min': 'Min',
      'chart_avg': 'Moy',
      'chart_max': 'Max',
      'server_screen_title': 'Serveur HTTP & Montre',
      'server_active': 'Serveur Actif',
      'server_stopped': 'Serveur Arrêté',
      'server_port': "Port d'écoute :",
      'server_local_ip': 'Adresse IP (locale) :',
      'server_localhost_note': 'Astuce : Si vous utilisez l\'application Zepp sur le même appareil, vous pouvez utiliser "localhost" au lieu de l\'adresse IP dans les paramètres de votre montre.',
      'server_post_endpoint': 'Point de terminaison POST :',
      'copy_curl': 'Copier la commande cURL',
      'watch_phase_cooling': 'Refroidissement',
      'watch_phase_heating': 'Échauffement',
      'watch_phase_resting': 'Repos',
      'watch_simulator': 'Simulateur de montre',
      'watch_simulator_desc': "Testez l'intégration en générant un ensemble réaliste de télémétrie.",
      'generate_watch_session': 'Générer et importer une séance',
      'http_logs_title': 'Journal des requêtes HTTP',
      'http_logs_print': 'Imprimer les journaux dans la console',
      'http_logs_printed':
          '{count} entrées de journal imprimées dans la console',
      'no_http_logs': 'Aucune requête enregistrée',
      'clear_logs': 'Effacer le journal',
      'backup_title': 'Sauvegarde & Export',
      'backup_export_title': "Exporter l'historique",
      'backup_export_desc':
          'Enregistrez toutes vos séances au format JSON ou CSV.',
      'backup_export_json_btn': 'Exporter JSON (fichier)',
      'backup_export_csv_btn': 'Exporter CSV (fichier)',
      'backup_import_title': 'Importer des séances (JSON)',
      'backup_import_desc': 'Choisissez un fichier de sauvegarde (.json) sur votre appareil pour restaurer votre historique.',
      'backup_import_btn': 'Importer depuis un fichier',
      'select_language': 'Choisir la langue',
      'language_pl': 'Polski',
      'language_en': 'English',
      'language_de': 'Deutsch',
      'language_fr': 'Français',
      'day_mon': 'Lun',
      'day_tue': 'Mar',
      'day_wed': 'Mer',
      'day_thu': 'Jeu',
      'day_fri': 'Ven',
      'day_sat': 'Sam',
      'day_sun': 'Dim',
      'settings_title': 'Paramètres',
      // ── Paramètres : navigation par section ──
      'settings_language_subtitle': "Choisir la langue de l'application",
      'settings_theme_subtitle': 'Thème : système, clair ou sombre',
      'settings_profile_subtitle': 'Sexe, poids et âge (calcul des calories)',
      'settings_watch_section': 'Montre / HTTP',
      'settings_watch_subtitle':
          'Serveur HTTP et import de sessions de la montre',
      'settings_about_subtitle': "Version et informations sur l'application",
      'settings_language_section': "Langue de l'application",
      'settings_language_dev_hint': 'Pour ajouter une nouvelle langue, ouvrez lib/core/localization/app_localizations.dart et ajoutez un nouveau bloc dans la map _localizedValues en suivant les traductions existantes comme modèle.',
      'settings_about_section': 'À propos',
      'settings_platform_label': 'Plateforme',
      'settings_danger_zone': 'Zone de danger',
      'settings_clear_data': 'Effacer toutes les données',
      'settings_clear_data_subtitle':
          'Supprimer irréversiblement tout l\'historique',
      // ── Apparence / thème ──
      'settings_theme_section': 'Apparence',
      'theme_mode_system': 'Système',
      'theme_mode_light': 'Clair',
      'theme_mode_dark': 'Sombre',
      // ── User profile / calories ──
      'settings_profile_section': 'Profil',
      'profile_sex': 'Sexe',
      'profile_male': 'Homme',
      'profile_female': 'Femme',
      'profile_weight': 'Poids',
      'profile_age': 'Âge',
      'profile_age_unit': 'ans',
      'profile_preferred_sauna_type': 'Type de sauna préféré',
      'calorie_button': 'Calories brûlées',
      'calorie_hint': 'Dépense énergétique estimée (temps, fréquence cardiaque, température, profil)',
      'calorie_estimate': 'Calories estimées brûlées',
      'calorie_need_hr':
          'La fréquence cardiaque moyenne est requise for the calcul.',
      'home_calories_based_on':
          'basé sur {count} séances avec fréquence cardiaque',
      'home_calories_today': "Aujourd'hui",
      'home_calories_week': 'Cette semaine',
      'calorie_samples_label': 'Mesure par segments',
      'calorie_samples_count':
          'basé sur {count} échantillons de fréquence cardiaque',
      'chart_zoom_hint': 'Touchez pour agrandir le graphique',
      'chart_tap_hint':
          'Touchez le graphique pour voir la valeur exacte à un point',
      'chart_samples_count': '{count} échantillons',
      'temp_kind_sauna': 'Température du sauna',
      'temp_kind_body': 'Température corporelle',
      'calorie_body_temp_note': "Aucune correction de température — c'est la température corporelle, pas le sauna.",
      'calorie_estimate_title': 'Détails des calories brûlées',
      'calorie_profile_used': 'Profil utilisé :',
      'calorie_formula_note_title': 'À propos du calcul',
      'calorie_formula_note_desc': 'Les calculs sont basés na la formule Keytel, tenant compte de la fréquence cardiaque, de l\'âge, du poids et du sexe.',
      'calorie_per_min': 'kcal/min',
      'no_measurement': 'Aucune mesure',
      'minutes_abbr': 'min',
      'seconds_abbr': 's',
      'bpm_abbr': 'bpm',
      // ── Ajouter / modifier une séance ──
      'add_session_title': 'Ajouter une séance de sauna',
      'session_sauna_type': 'Type de sauna',
      'sauna_type_dry': 'Sec',
      'sauna_type_steam': 'Vapeur',
      'error_duration_required': 'Saisissez la durée de la séance',
      'error_duration_positive':
          'La durée doit être un nombre supérieur à zéro',
      'error_temperature_range':
          'Saisissez une température valide (1 - 140 °C)',
      'session_updated_saved': 'Modifications enregistrées !',
      'session_saved': 'Séance enregistrée avec succès !',
      'error_saving_session':
          "Une erreur est survenue lors de l'enregistrement.",
      'watch_edit_locked_note': 'Données de la montre — les mesures (fréquence cardiaque, temperatura) ne peuvent pas être modifiées.',
      // ── Historique ──
      'error_delete_session': 'Impossible de supprimer la séance.',
      'avg_abbr': 'Moy.',
      'confirm_delete_session': 'Voulez-vous vraiment supprimer la séance du {date} ({minutes} {unit}) ?',
      'clear_data_confirm_title': 'Tout supprimer',
      'clear_data_confirm_message': 'Voulez-vous vraiment supprimer tout l\'historique des séances ? Cette opération est irréversible.',
      'clear_data_success': 'Toutes les données ont été supprimées.',
      // ── Kalendarz ──
      'calendar_min_in_sauna': '{minutes} min au sauna',
      // ── Détails de la séance ──
      'phases_label': 'Phases de sauna',
      // ── Serveur HTTP / Montre ──
      'change_port_tooltip': 'Changer le port',
      'server_change_port_title': 'Changer le port du serveur HTTP',
      'server_port_number': 'Numéro de port',
      'server_port_hint': 'ex. 8080, 8081, 9090',
      'server_change_and_restart': 'Modifier et redémarrer',
      'server_restarted': 'Serveur redémarré sur le port {port}',
      'curl_copied': 'Commande cURL copiée dans le presse-papiers !',
      'phase_count_label': 'Nombre de phases de sauna',
      'watch_session_imported':
          'Séance de montre importée avec succès ({count} {stages}) !',
      'watch_session_failed': "Impossible d'envoyer la séance de montre.",
      'logs_count': '{count} entrées',
      // ── Sauvegarde ──
      'backup_export_saved': 'Sauvegarde enregistrée dans un fichier',
      'backup_imported': 'Nouveaux épisodes importés avec succès !',
      'backup_import_error': "Erreur d'import JSON : {error}",
      'backup_entries': '{count} entrées',
      'backup_export_desc_count': 'Enregistrez toutes vos séances ({count} entrées) au format JSON ou CSV.',
      // ── About ──
      'about_description': 'C\'est l\'application compagnon officielle de l\'écosystème „Sauna Time”, conçue pour lire et analyser les données de vos séances de sauna.',
      'about_contact_support': 'Contacter le support :',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  String translate(String key) {
    final langCode = locale.languageCode;
    final map = _localizedValues[langCode] ?? _localizedValues['en']!;
    return map[key] ?? _localizedValues['en']?[key] ?? key;
  }

  String operator [](String key) => translate(key);

  /// Localized name of the sauna phase (heating/cooling/resting).
  String phaseLabel(SaunaPhase phase) => translate(phase.labelKey);

  /// Localized name of the session source (Manual / Watch HTTP).
  String sourceLabel(SessionSource source) => translate(source.labelKey);

  /// Replacing {key} placeholders in the template with values.
  String _fmt(String key, [Map<String, Object> args = const {}]) {
    var text = translate(key);
    for (final entry in args.entries) {
      text = text.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return text;
  }

  /// Number of sessions with correct pluralization (e.g., 1 session / 2 sessions).
  String sessionsCountLabel(int count) {
    if (locale.languageCode == 'pl') {
      if (count == 1) return '1 sesja';
      if (count % 10 >= 2 &&
          count % 10 <= 4 &&
          (count % 100 < 12 || count % 100 > 14)) {
        return '$count sesje';
      }
      return '$count sesji';
    }
    switch (locale.languageCode) {
      case 'de':
        return count == 1 ? '1 Sitzung' : '$count Sitzungen';
      case 'fr':
        return count == 1 ? '1 séance' : '$count séances';
      case 'en':
      default:
        return count == 1 ? '1 session' : '$count sessions';
    }
  }

  /// "{minutes} min in sauna" depending on the language.
  String minInSauna(int minutes) {
    switch (locale.languageCode) {
      case 'pl':
        return '$minutes min w saunie';
      case 'de':
        return '$minutes Min. in der Sauna';
      case 'fr':
        return '$minutes min au sauna';
      case 'en':
      default:
        return '$minutes min in sauna';
    }
  }

  /// Pluralization of the word "phase" (e.g., 1 phase / 2 phases).
  String stagesLabel(int count) {
    if (locale.languageCode == 'pl') {
      if (count == 1) return 'etap';
      if (count < 5) return 'etapy';
      return 'etapów';
    }
    switch (locale.languageCode) {
      case 'de':
        return count == 1 ? 'Phase' : 'Phasen';
      case 'fr':
        return count == 1 ? 'phase' : 'phases';
      case 'en':
      default:
        return count == 1 ? 'phase' : 'phases';
    }
  }

  String confirmDeleteSession(String date, int minutes) => _fmt(
    'confirm_delete_session',
    {'date': date, 'minutes': minutes, 'unit': this['minutes_abbr']},
  );

  String watchSessionImported(int count) => _fmt('watch_session_imported', {
    'count': count,
    'stages': stagesLabel(count),
  });

  String backupExportSaved() => translate('backup_export_saved');
  String backupImported(int count) => _fmt('backup_imported', {'count': count});
  String backupImportError(String error) =>
      _fmt('backup_import_error', {'error': error});
  String backupExportDesc(int count) =>
      _fmt('backup_export_desc_count', {'count': count});
  String backupEntriesLabel(int count) =>
      _fmt('backup_entries', {'count': count});
  String logsCountLabel(int count) => _fmt('logs_count', {'count': count});
  String logsPrintedLabel(int count) =>
      _fmt('http_logs_printed', {'count': count});
  String serverRestarted(int port) => _fmt('server_restarted', {'port': port});
  String homeCaloriesBasedOn(int count) =>
      _fmt('home_calories_based_on', {'count': count});
  String calorieSamplesCount(int count) =>
      _fmt('calorie_samples_count', {'count': count});
  String chartSamplesCount(int count) =>
      _fmt('chart_samples_count', {'count': count});
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['pl', 'en', 'de', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
