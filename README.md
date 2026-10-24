# BikeRc Rehab

Analiza ruchu stopy i nogi pod kątem rehabilitacji (MediaPipe Pose, działa w przeglądarce).

- `index.html` – wersja na telefon / tablet (Safari, Chrome): tryb Rehabilitacja i Bike fitting
- `komputer.html` – wersja na komputer

Nagrania i zdjęcia zostają na urządzeniu. Wysyłane nie są nigdy.

## Baza pacjentów i zawodników (Supabase)

Zakładka **Pacjent / Klient** w `index.html` ma bazę osób: pacjenci (tryb Rehabilitacja) i zawodnicy (tryb Bike fitting).
Po zalogowaniu „Zapisz w historii” zapisuje sesję (wyniki, bez zdjęć) także w karcie osoby w bazie.

Podłączenie:

1. Utwórz projekt w Supabase.
2. SQL Editor → New query → wklej całość `supabase.sql` → Run.
3. Authentication → Sign In / Providers → wyłącz „Allow new users to sign up”.
4. Authentication → Users → Add user → Create new user (e-mail, hasło, „Auto Confirm User”).
5. W `index.html` uzupełnij `SB_URL` (Project URL) i `SB_KEY` (publishable / anon key).
   Klucza `service_role` / secret nigdy nie wpisuj do strony.

Każdy zalogowany widzi tylko swoje osoby i sesje (RLS). Bez logowania baza nic nie zwraca.
