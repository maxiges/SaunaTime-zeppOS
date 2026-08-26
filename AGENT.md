# AGENT.md — Żywa Dokumentacja Projektu `sauna_time`

Dokument ten stanowi **główne źródło kontekstu** dla każdego agenta AI oraz programisty pracującego nad projektem **`sauna_time`**.
Każdy agent podejmujący zadanie w projekcie ma obowiązek przeczytać ten dokument przed rozpoczęciem pracy oraz zaktualizować go po zakończeniu swojego etapu.

---

## 1. O Projekcie

**`sauna_time`** to aplikacja mobilna Flutter stworzona wyłącznie na platformy **Android** oraz **iOS**, służąca do rejestrowania, edycji, przeglądania i analizowania sesji saunowania.

### Główne funkcje wdrożone w projekcie:

1. **Ręczne wprowadzanie i edycja sesji sauny** (`AddSessionScreen` w trybie create/edit: data, godzina, szybkie chipy czasu trwania, temperatura, notatki, walidacja).
   1b. **Typ sauny (Sucha / Parowa)** — możliwość wyboru typu sauny dla każdej sesji. Wpływa to na kalkulację kalorii (różne temperatury referencyjne). Domyślny typ można ustawić w profilu użytkownika.
   1c. **Tętno przy ręcznym dodawaniu** — opcjonalne pola **Średnie tętno** (do oszacowania kalorii) oraz **Min/Maks tętno**. Gdy podano min i maks, aplikacja generuje **liniowo rosnący przebieg tętna** (`_generateLinearHrSamples`, 12 próbek od startu do końca sesji od min do maks) i zapisuje jako `heartRateSamples` + `maxHeartRate`. Jeśli nie podano średniego, przyjmuje (min+maks)/2. Walidacja: zakres 30–250, min/maks razem, min < maks (`_validateHr`).
2. **Analityka Aktywności Tygodniowej (`WeeklyActivityCard`)** — zaawansowana karta aktywności z ostatnich 7 dni, oferująca **6 trybów wizualnych** wybieranych w profilu:
   *   **Obok siebie (Side-by-side)**: Czas całkowity i nagrzewania jako dwa oddzielne paski.
   *   **Skumulowany (Stacked)**: Czas nagrzewania jako segment wewnątrz słupka całkowitego.
   *   **Intensywność (Intensity)**: Heatmapa (kwadraty) o nasyceniu zależnym od czasu sesji.
   *   **Pierścienie (Rings)**: Pierścienie postępu dla każdego dnia (styl Apple Watch).
   *   **Wykres liniowy (Line Chart)**: Wygładzona krzywa z gradientem i punktami danych.
   *   **Czas całkowity (Total Only)**: Klasyczny, minimalistyczny widok słupkowy.
3. **Kopia Zapasowa & Eksport/Import z plików (`BackupService` & `BackupScreen`)** (eksport całej bazy do **pliku** JSON wybranego przez użytkownika — `FilePicker.saveFile`; import sesji z pliku `.json` — `FilePicker.pickFile`; ochrona przed duplikatami). Brak już kopiowania/wklejania stringów.
4. **Wbudowany lokalny serwer HTTP** (działający w tle na urządzeniu, nasłuchujący pod `POST /api/sessions` lub `POST /session`, z obsługą CORS, statusem `GET /api/status`, konfigurowalnym portem i generatorem poleceń cURL).
   4b. **Informacje o adresie IP** — ekran serwera wyświetla lokalny adres IP urządzenia (`localIp`), co ułatwia konfigurację zegarka. Dodano również wskazówkę, że w przypadku korzystania z aplikacji Zepp na tym samym urządzeniu (np. emulator lub Zepp App + Sauna Time na jednym telefonie), można użyć adresu `localhost` zamiast IP.
5. **Automatyczny import i parser danych telemetrycznych z zegarka** (przetwarzanie próbek tętna `heartRateSamples`, temperatury w czasie `temperatureSamples`, statystyk min/avg/max i automatyczny zapis do bazy).
   5b. **Etapy saunowania z zegarka (od 1 do 3)** — sesja może zawierać 1, 2 lub 3 etapy: Nagrzewanie (czerwony), Chłodzenie (niebieski), Odpoczywanie (zielony). Serwer HTTP (`phases` w payload) oraz aplikacja obsługują dowolną liczbę etapów; próbki mogą być oznaczane fazą (`phase` in `MeasurementSample`), a wykresy `TelemetryChart` rysują każdy etap w dedykowanym kolorze z legendą. Symulator zegarka pozwala wybrać liczbę etapów (1-3) i generuje realistyczne, losowe dane z szumem sensorów.
6. **Ekran historii sesji** (pełna lista z filtrowaniem po źródle: Ręczne / Zegarek HTTP, sortowaniem po dacie/czasie trwania, usuwaniem sesji z potwierdzeniem i swipe-to-delete).
7. **Interaktywny kalendarz z wyborem zakresu** (`CalendarScreen`) — pozwala na zaznaczanie pojedynczych dni lub przedziałów czasowych (start-koniec). Podświetla wybrany zakres w formie "wstążki", sumuje czas w saunie dla wybranego okresu i dynamicznie filtruje listę sesji pod kalendarzem.
8. **Szczegółowy podgląd sesji z edycją** (`SessionDetailScreen`: przedział czasowy, czas trwania, temperatura, tętno średnie/maksymalne, notatki, źródło, edycja i usuwanie).
   8b. **Dokładny czas trwania (sekundy)** — dotknięcie kafelka czasu trwania na ekranie szczegółów sesji przełącza widok między zaokrąglonymi minutami a dokładnym czasem z uwzględnieniem sekund (obliczanym jako różnica między `startTime` a `endTime`).
9. **Wykresy telemetryczne** (`TelemetryChart` oparty na zoptymalizowanym `CustomPainter` z wygładzoną krzywą tętna/temperatury, wypełnieniem gradientowym i statystykami). Wykres zawsze sortuje próbki po czasie (lewa->prawa), linia rysowana jest ciągła (odcinek między każdą parą punktów, kolor wg etapu), a kropki są subtelne — dzięki temu przebieg tętna/temperatury jest dobrze widoczny.
   9b. **Interakcja z wykresem (dotknij, aby zobaczyć wartość)** — dotknięcie lub przesunięcie palcem po wykresie (`_ChartInteractive`) pokazuje dokładną wartość w danym punkcie: linia pomocnicza na osi czasu + wyróżniona kropka + dymek z czasem (`HH:mm:ss`), wartością z jednostką i nazwą etapu (jeśli próbka ma fazę). Podpowiedź „dotknij wykres…" (`chart_tap_hint`) znika po zaznaczeniu. Pełnoekranowy zoom (`_openFullScreen`, `InteractiveViewer` 1-8x) otwiera teraz ikona zoomu w nagłówku wykresu (wcześniej otwierało go dotknięcie wykresu).
10. **Konsola zarządzania serwerem HTTP i symulator zegarka** (włączanie/wyłączanie serwera, wyświetlanie lokalnego IP, live log żądań HTTP, zmiana portu, przycisk do symulacji i testowania importu ze smartwatcha). Logi HTTP są **w języku angielskim** i zawierają szczegóły: adres IP klienta, User-Agent, ciało żądania/odpowiedzi, błąd i czas obsługi w ms; **kliknięcie w log otwiera arkusz ze szczegółami** (`_showLogDetails`).
11. **Lokalne przechowywanie offline (offline-first)** — persistence w oparciu o `SharedPreferences` i JSON.
    11b. **Pełna lokalizacja interfejsu (pl/en/de/fr)** — wszystkie ekrany (pulpit, historia, kalendarz, szczegóły, serwer HTTP, kopia zapasowa, ustawienia) używają `AppLocalizations`; polskie teksty zostały usunięte z widoków. Pomocnicze metody: `sourceLabel`, `phaseLabel`, `sessionsCountLabel`, `minInSauna`, `stagesLabel`, szablony `{placeholder}` przez `_fmt`.
    11c. **Motyw ciepło/chłód (pomarańcz + niebieski)** — `main.dart` buduje `ColorScheme` z `seedColor: Colors.deepOrange` z nadpisaniami `primary` (pomarańcz = ciepło) i `secondary` (niebieski = chłód) w jasnym i ciemnym motywie. Stałe kolorów w `lib/core/theme/app_colors.dart` (`AppColors`): `warmOrange`, `coldBlue`, `warmRed` (czerwony akcent: tętno/usuwanie/wykres) oraz **neutralne szare powierzchnie kart** (`surface`, `surfaceContainer*`) — bez różowego odcienia M3. Karty sesji pokazują **ikonę zegarka** (`Icons.watch_rounded`) w kolorze niebieskim dla sesji ze smartwatcha (spójnie na pulpicie, w historii, kalendarzu i szczegółach). Wybór motywu (systemowy / jasny / ciemny) w Ustawieniach — `ThemeController` (`lib/core/theme/theme_controller.dart`) zapisuje `ThemeMode` w `SharedPreferences`.
    11d. **Zaawansowana kalkulacja kalorii + profil użytkownika** — `CalorieCalculator` (`lib/features/sessions/domain/calorie_calculator.dart`) szacuje spalone kalorie (wzór Keytel: płeć, waga, wiek, tętno, czas trwania). 
        *   **Korekta temperaturowa** stosowana jest wyłącznie dla etapu `heating` (sauna).
        *   **Typ sauny** zmienia punkt odniesienia temperatury (Dry: 75°C, Steam: 45°C).
        *   **Pomiar odcinkowy**: jeśli dostępne są próbki tętna, kalorie liczone są dla każdego odcinka czasu osobno.
        *   Profil użytkownika (płeć / waga / wiek / preferowana sauna) konfigurowany w Ustawieniach -> Profil.
    11e. **Rozróżnienie temperatury sauny od temperatury ciała** — zgłoszona przez zegarek temperatura może być temperaturą **sauny** (powietrze) lub **ciała** (skóra użytkownika). `classifyTemperature()` w `calorie_calculator.dart`: próg **45°C** — temperatura ≥45°C → `TemperatureKind.sauna`, <45°C → `TemperatureKind.body`, brak → `TemperatureKind.unknown`. UI wyświetla odpowiednie etykiety i noty.
    11f. **Podsumowanie na pulpicie = ostatnie 7 dni** — karta podsumowania na `HomeScreen` (kafelki **Sesje łącznie** i **Czas w saunie**) pokazuje dane **tylko z ostatnich 7 dni** (włącznie z dziś).
    11g. **Brak stopera** — aplikacja służy wyłącznie do **odczytu danych z zegarka**; opcja Timera saunowania została usunięta.
    11h. **Zarządzanie danymi** — w Ustawieniach dodano "Strefę niebezpieczną" umożliwiającą nieodwracalne usunięcie całej historii sesji z pamięci urządzenia (`clearAllSessions`).
12. **Animowany Splash Screen i personalizacja UI**:
    12a. **SplashScreen** (`lib/features/home/presentation/splash_screen.dart`) z animacją logotypu i paska postępu, maskujący ładowanie danych przy starcie.
    12b. **Niestandardowe menu nawigacyjne**: Usunięto domyślny wskaźnik (pill) Material 3. Aktywne elementy w `NavigationBar` i `NavigationRail` mają pomarańczowe ikony z delikatnym efektem **glow** (cień `Shadow`) oraz pogrubione etykiety.

---

## 2. Podstawowe Zasady Pracy & Rozwiązane Problemy

1. **Iteracyjny rozwój (krok po kroku)**:
   - Zmiany wprowadzane w sposób modułowy, bez zbędnych, niesprawdzonych bibliotek.
   - Po każdej większej zmianie: analiza statyczna (`flutter analyze`) oraz zestaw testów (`flutter test`).
2. **Utrzymanie spójności**:
   - Preferuj modyfikowanie istniejących plików nad tworzeniem redundantnych.
3. **Czysta architektura**:
   - Warstwy: `presentation`, `domain`/`models`, `data`/`storage`, `services` (`http_server`, `backup`).
   - Logika biznesowa i stan zarządzane poprzez `ChangeNotifier` (`SessionController`, `LocalHttpServerService`).
4. **Platformy**:
   - Wyłącznie **Android** i **iOS**.
5. **Konfiguracja Gradle / Kotlin (Windows cross-drive fix)**:
   - Rozwiązanie problemu `IllegalArgumentException: this and base files have different roots` poprzez wyłączenie kompilacji przyrostowej Kotlina w `gradle.properties`.

---

## 3. Struktura Projektu

... (bez zmian w strukturze plików)
