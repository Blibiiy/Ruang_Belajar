# Ruang Belajar

Ruang Belajar adalah aplikasi mobile berbasis Flutter (target platform Android/iOS) yang mengintegrasikan sistem manajemen tugas, pelacakan fokus waktu nyata berbasis visi komputer, dan penjadwalan otomatis bertenaga LLM. Aplikasi ini memecahkan masalah degradasi konsentrasi pengguna selama sesi belajar dengan memanfaatkan kamera depan untuk pemantauan status wajah secara lokal serta menggunakan model Generative AI untuk melakukan alokasi waktu belajar yang optimal berdasarkan batasan waktu aktif pengguna.

## Fitur Utama

- **Manajemen Tugas & Prioritas**: Operasi CRUD tugas belajar yang dilengkapi atribut tingkat prioritas (low, medium, high), tenggat waktu (deadline), dan status pemetaan jadwal.
- **Kalender Planner Terintegrasi**: Visualisasi jadwal tugas dalam tampilan bulanan dan harian menggunakan kalender interaktif yang menyinkronkan repositori tugas lokal.
- **Siklus Pomodoro dengan Pemantauan Fokus Visi Komputer**: Timer Pomodoro yang disinkronkan dengan pemrosesan frame video kamera depan untuk melacak tingkat kehadiran pengguna, distraksi arah pandang (sudut euler wajah), dan indikator kelelahan (eye open probability).
- **Penjadwalan Otomatis Berbasis Gemini API**: Pengambilan keputusan jadwal dinamis untuk memetakan tugas-tugas tanpa jadwal (unscheduled) ke dalam slot waktu kosong berdasarkan kriteria jam belajar aktif, jeda antar tugas (buffer), dan strategi prioritas.
- **Notifikasi Alarm Lokal Asinkronus**: Sistem pengingat waktu belajar yang dijadwalkan secara otomatis pada platform native OS ketika slot jadwal tugas ditentukan.
- **Analitik Kinerja Belajar (Focus Score)**: Pengumpulan statistik sesi belajar historis dan perhitungan metrik persentase efisiensi fokus menggunakan data pelacakan wajah.

## Arsitektur Sistem & Tech Stack

- **Frontend**: Flutter SDK (Dart ^3.9.2), Flutter BLoC (State Management), Camera API, Table Calendar.
- **Backend / Core Services**: Google Generative AI SDK untuk pemanggilan model Gemini secara langsung.
- **Infrastruktur & Penyimpanan**: SQLite Database (melalui paket `sqflite`), berkas path lokal (`path_provider`), Native Android Notification Manager (`flutter_local_notifications`).
- **Layanan ML / AI**: Google ML Kit Face Detection API (proses inferensi lokal secara offline di perangkat), Gemini API Models (`gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-pro`, `gemini-2.5-flash`).

## Struktur Proyek

Aplikasi ini menggunakan pola arsitektur **Feature-First (Clean Architecture berbasis Fitur)** untuk memisahkan tanggung jawab (separation of concerns) dan mempermudah pemeliharaan modular:

```text
lib/
├── app/                  # Konfigurasi dasar aplikasi, tema global (ThemeData), dan inisialisasi awal
├── core/                 # Layanan utilitas bersama dan pembaca environment variables
│   ├── datetime/         # Helper pemformatan dan operasi matematika tanggal
│   └── env/              # Kelas pembaca kredensial API Key
└── features/             # Lapisan modular pembungkus fungsionalitas sistem
    ├── ai_scheduling/    # Logika inferensi API scheduling Gemini
    ├── calendar/         # Presentasi kalender dan visualisasi tugas terjadwal
    ├── focus/            # Kontrol timer Pomodoro dan status interaksi user interface
    ├── focus_metrics/    # Model repositori data statistik deteksi wajah
    ├── focus_monitoring/ # Pipeline streaming frame kamera dan deteksi wajah ML Kit
    ├── home/             # Halaman dashboard utama dan pengelompokan tugas
    ├── notifications/    # Pembungkus konfigurasi saluran notifikasi lokal native
    ├── sessions/         # Manajemen perekaman riwayat sesi Pomodoro ke dalam database
    ├── stats/            # Pengolahan metrik belajar ke bentuk visualisasi mingguan
    └── tasks/            # Model data, lapisan repositori SQLite, dan operasi CRUD tugas
```

## Panduan Setup & Instalasi Lokal

### Prasyarat

- Flutter SDK versi 3.9.2 atau lebih baru
- Dart SDK versi 3.9.2 atau lebih baru
- Android Studio / VS Code dengan ekstensi Flutter terpasang
- Emulator Android atau perangkat fisik Android yang memiliki kamera depan aktif
- Kunci API Google Gemini (Gemini API Key)

### Langkah-Langkah

1. Kloning repositori:
```bash
git clone <repo-url>
cd <repo-name>
```

2. Instal dependensi:
```bash
flutter pub get
```

3. Konfigurasi Environment:
Aplikasi memerlukan API Key Gemini untuk menjalankan modul penjadwalan otomatis. Konfigurasikan variabel environment melalui opsi kompilasi `--dart-define`:
- Nama Kunci: `GEMINI_API_KEY`
- Tipe Data: `String`
- Nilai: [Kunci API Anda dari Google AI Studio]

4. Menjalankan Aplikasi:
```bash
flutter run --dart-define=GEMINI_API_KEY=KUNCI_API_GEMINI_ANDA
```

## Logika Inti & Detail Arsitektur Sistem

### 1. Skema Database SQLite (Relasional)
Penyimpanan offline relasional diimplementasikan pada database `ruang_belajar.db` melalui skema berikut:

```sql
-- Tabel Tugas (tasks)
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  deadline_ms INTEGER,
  scheduled_at_ms INTEGER,
  priority INTEGER NOT NULL,
  notification_id INTEGER,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
);

-- Tabel Riwayat Sesi (study_sessions)
CREATE TABLE study_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER,
  started_at_ms INTEGER NOT NULL,
  ended_at_ms INTEGER NOT NULL,
  focus_seconds INTEGER NOT NULL,
  break_seconds INTEGER NOT NULL,
  planned_cycles INTEGER NOT NULL,
  completed_cycles INTEGER NOT NULL,
  is_completed INTEGER NOT NULL,
  created_at_ms INTEGER NOT NULL
);

-- Tabel Hasil Pemindaian Fokus (focus_session_metrics)
CREATE TABLE focus_session_metrics (
  session_id INTEGER PRIMARY KEY,
  focus_total_seconds INTEGER NOT NULL,
  focus_active_seconds INTEGER NOT NULL,
  absent_seconds INTEGER NOT NULL,
  distracted_seconds INTEGER NOT NULL,
  fatigued_seconds INTEGER NOT NULL,
  absent_events INTEGER NOT NULL,
  distracted_events INTEGER NOT NULL,
  fatigued_events INTEGER NOT NULL,
  focus_score REAL NOT NULL,
  created_at_ms INTEGER NOT NULL,
  FOREIGN KEY(session_id) REFERENCES study_sessions(id) ON DELETE CASCADE
);
```

### 2. Aturan Evaluasi Deteksi Fokus (ML Kit Pipeline)
Setiap frame video dianalisis oleh generator BLoC pemantau wajah (`FocusMonitoringBloc`) menggunakan batasan matematis berikut:

- **Ketidakhadiran (Absence)**: Jika wajah tidak terdeteksi dalam frame kamera depan selama $t \ge 3$ detik kontinu, state mesin mengirimkan event penundaan timer (`FocusTimerPaused`).
- **Distraksi Arah Pandang (Distracted)**: Ditentukan berdasarkan deviasi sudut kepala 3D (Euler Angles):
  $$\text{Distracted} \iff |\theta_{\text{Yaw}}| > 15^\circ \lor |\theta_{\text{Pitch}}| > 15^\circ$$
- **Tingkat Kelelahan (Fatigued)**: Dihitung dari probabilitas keterbukaan mata kiri ($E_L$) dan kanan ($E_R$):
  $$\text{Fatigued} \iff \frac{E_L + E_R}{2} < 0.5$$

### 3. Rumus Metrik Focus Score
Skor kinerja fokus ($S_f$) pada suatu sesi belajar dinyatakan dalam bentuk persentase efisiensi waktu aktif terhadap durasi total belajar yang berjalan:
$$S_f = \left( \frac{t_{\text{aktif}}}{t_{\text{total}}} \right) \times 100\%$$
Di mana:
- $t_{\text{aktif}}$ adalah total detik selama sesi berlangsung ketika status deteksi wajah berada pada kategori `Present` (tidak terdistraksi dan tidak terindikasi lelah).
- $t_{\text{total}}$ adalah total detik bersih dari sesi berjalan yang tersimpan di database.

## Deployment & Lingkungan Kerja

- **Target OS**: Android (Minimum SDK API 21) & iOS (Minimum iOS 12.0, membutuhkan izin penambahan deskripsi kamera pada `Info.plist`).
- **Environment**: Local Development (Physical Android Device dengan koneksi USB debugging).
- **Build Artifact**: APK (Android Application Package) / AAB (Android App Bundle) yang dikompilasi menggunakan perintah `flutter build apk --release`.
