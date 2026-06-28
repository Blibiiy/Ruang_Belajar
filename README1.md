# 📚 Ruang Belajar - Smart Focus & AI-Assisted Study Planner

**Ruang Belajar** adalah aplikasi mobile berbasis Flutter yang dirancang untuk mengoptimalkan produktivitas dan kualitas belajar secara cerdas. Aplikasi ini menggabungkan teknik manajemen waktu **Pomodoro Timer**, **Deteksi Wajah Real-Time Berbasis Machine Learning (Google ML Kit)** untuk menjaga fokus, serta **Penjadwalan Otomatis Berbasis Generative AI (Google Gemini)** untuk mengelola tugas-tugas belajar yang belum terjadwal (*unscheduled tasks*).

Aplikasi ini dikembangkan sebagai proyek **Ujian Akhir Semester (UAS) Mobile Programming Lanjut**.

---

## 🌟 Fitur Utama

### 1. 📋 Manajemen Tugas (Task Management)
*   **Create, Read, Update, Delete (CRUD) Tasks**: Pengguna dapat mencatat tugas belajar beserta deskripsi lengkapnya.
*   **Priority Level**: Klasifikasi prioritas tugas menjadi **Low**, **Medium**, dan **High**.
*   **Deadline Management**: Menetapkan tenggat waktu pengumpulan atau pengerjaan tugas.
*   **Status Tugas**: Membedakan tugas yang belum dijadwalkan (*unscheduled*) dengan tugas yang telah dijadwalkan (*scheduled*).

### 2. 📅 Kalender Interaktif (Calendar Planner)
*   Menggunakan visualisasi bulanan berbasis `table_calendar`.
*   Menampilkan penanda (*event markers*) pada tanggal-tanggal yang memiliki jadwal belajar.
*   Memfilter daftar tugas harian secara langsung berdasarkan tanggal yang dipilih oleh pengguna.
*   Membuat tugas baru atau mereschedule tugas langsung dari halaman kalender.

### 3. ⏱️ Pomodoro Timer & AI Face Focus Monitoring
*   **Siklus Pomodoro**: Menyediakan timer fokus dan istirahat (*break time*) yang dapat disesuaikan (durasi fokus, durasi istirahat, dan jumlah siklus/cycle).
*   **Real-Time AI Face Monitoring**: Menggunakan kamera depan perangkat dan **Google ML Kit Face Detection** untuk mendeteksi wajah dan melacak tingkat fokus pengguna:
    *   **Present (Hadir)**: Wajah terdeteksi menghadap layar dengan mata terbuka.
    *   **Absent (Tidak Ada)**: Wajah tidak terdeteksi di depan kamera. Jika pengguna meninggalkan layar lebih dari **3 detik (grace period)**, timer belajar akan otomatis dijeda (*paused*).
    *   **Distracted (Teralihkan)**: Pengguna mendongak, menunduk, atau menoleh keluar layar (dihitung berdasarkan sudut *Yaw* dan *Pitch* wajah).
    *   **Fatigued (Lelah/Mengantuk)**: Rata-rata probabilitas mata terbuka kiri dan kanan berada di bawah batas normal.
*   **Camera Debug Overlay**: Pratinjau kamera depan mini di sudut kanan atas layar yang menampilkan visualisasi langsung sudut wajah (*Yaw*, *Pitch*, *Roll*) serta status mata.

### 4. 🤖 Penjadwalan Otomatis AI (Gemini Auto-Scheduling)
*   Mengintegrasikan **Google Generative AI SDK (Gemini)** untuk menyusun jadwal belajar secara otomatis bagi tugas-tugas yang belum terjadwal (*unscheduled*).
*   AI memproses input berupa:
    *   Jam aktif belajar pengguna (contoh: 08:00 - 22:00).
    *   Hari aktif belajar (Weekdays saja atau Setiap Hari).
    *   Strategi prioritas (*Deadline-first* atau *Priority-first*).
    *   *Buffer* waktu istirahat antar tugas.
*   Gemini menghasilkan usulan tanggal dan jam mulai belajar secara logis, yang kemudian diselaraskan oleh sistem agar tidak bentrok dengan jadwal yang sudah ada dan tidak melewati tenggat waktu (*deadline*) tugas.

### 5. 🔔 Notifikasi Pengingat Lokal (Local Notifications)
*   Menggunakan `flutter_local_notifications` untuk memicu alarm pengingat belajar secara lokal di perangkat.
*   Notifikasi secara dinamis dijadwalkan ketika tugas diberi tanggal/jam belajar secara manual maupun otomatis oleh AI Gemini.
*   Notifikasi akan dibatalkan/dijadwalkan ulang secara otomatis jika tugas dihapus atau di-*reschedule*.

### 6. 📊 Analitik & Statistik Belajar (Focus Analytics)
*   **Daily Progress**: Menampilkan total waktu fokus, waktu istirahat, dan jumlah sesi Pomodoro yang selesai dikerjakan hari ini.
*   **7-Day Focus Chart**: Visualisasi durasi fokus harian selama satu minggu terakhir menggunakan grafik bar progress.
*   **Riwayat Sesi Lengkap**: Riwayat sesi belajar yang memuat status sesi, waktu mulai/selesai, serta metrik keaktifan.
*   **Focus Score (%)**: Skor persentase fokus pintar yang dihitung dari total durasi aktif fokus pengguna (ketika wajah berada di layar dan tidak mengantuk/teralihkan) dibagi total durasi sesi belajar.

---

## 🛠️ Tech Stack & Pustaka (Libraries)

Aplikasi ini dibangun menggunakan SDK Flutter terbaru dengan pustaka pendukung berikut:

| Pustaka | Kegunaan |
|---|---|
| **Flutter BLoC (`flutter_bloc`)** | Manajemen *State* aplikasi menggunakan pola BLoC (Business Logic Component). |
| **Equatable (`equatable`)** | Mempermudah perbandingan nilai *state* dan objek Dart. |
| **Sqflite (`sqflite`)** | Database SQL lokal untuk penyimpanan data relasional secara offline. |
| **Google Generative AI (`google_generative_ai`)** | Integrasi API model Gemini (seperti `gemini-1.5-flash` & `gemini-2.5-flash`) untuk auto-scheduling. |
| **Google ML Kit Face Detection (`google_mlkit_face_detection`)** | Pengenalan wajah, arah pandangan (angles), dan deteksi mata terbuka/tertutup secara lokal. |
| **Camera (`camera`)** | Akses dan *streaming* frame gambar kamera depan secara real-time. |
| **Table Calendar (`table_calendar`)** | Widget kalender kustomisasi penuh untuk penjadwalan. |
| **Flutter Local Notifications (`flutter_local_notifications`)** | Penjadwalan pengingat lokal berbasis waktu (*scheduled reminders*). |
| **Timezone (`timezone` & `flutter_timezone`)** | Pengaturan zona waktu lokal perangkat untuk keakuratan alarm notifikasi. |
| **Intl (`intl`)** | Pemformatan tanggal, waktu, dan lokalisasi data. |

---

## 📂 Struktur Proyek (Clean Architecture - Feature-First)

Struktur kode sumber menggunakan pendekatan **Clean Architecture** berbasis modular/fitur untuk menjaga keterbacaan, skalabilitas, dan kemudahan pengujian kode:

```text
lib/
├── app/
│   ├── app.dart              # Root Widget, RepositoryProvider, dan BlocProvider global.
│   └── theme.dart            # Konfigurasi sistem tema gelap (Dark Theme) & palet warna.
├── core/
│   ├── datetime/
│   │   └── datetime_ext.dart # Ekstensi pembantu manipulasi objek DateTime.
│   └── env/
│   │   └── app_env.dart      # Membaca konfigurasi variabel lingkungan (Gemini API Key).
└── features/
    ├── ai_scheduling/        # Logika & UI Auto-Scheduling dengan Gemini API.
    ├── calendar/             # UI Halaman Kalender bulanan & harian.
    ├── focus/                # UI Halaman Fokus, timer Pomodoro, dan kontrol sesi.
    ├── focus_metrics/        # Repositori & entitas data hasil pemantauan fokus.
    ├── focus_monitoring/     # BLoC, Helper ML Kit, dan integrasi streaming kamera.
    ├── home/                 # UI Dashboard Utama (Hero Card, Unscheduled & Scheduled Soon).
    ├── notifications/        # Service pembungkus inisialisasi & penjadwalan notifikasi lokal.
    ├── profile/              # Placeholder fitur profil pengguna.
    ├── sessions/             # Repositori sesi belajar & detail analisis per sesi.
    ├── shell/                # Kerangka navigasi bawah (Bottom Navigation Bar).
    ├── stats/                # Halaman statistik & grafik kemajuan mingguan.
    └── tasks/                # BLoC, Model, SQL Helpers, dan UI Form Tugas.
```

---

## 💾 Skema Database Lokal (SQLite)

Database local menggunakan SQLite dengan nama berkas `ruang_belajar.db` dan memiliki tiga tabel utama yang saling berelasi:

### 1. Tabel `tasks` (Tugas)
Menyimpan informasi tugas-tugas belajar yang dibuat oleh pengguna.
```sql
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
```

### 2. Tabel `study_sessions` (Sesi Belajar)
Mencatat riwayat sesi belajar Pomodoro yang dijalankan oleh pengguna.
```sql
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
```

### 3. Tabel `focus_session_metrics` (Metrik Fokus ML Kit)
Menyimpan akumulasi metrik pelacakan wajah real-time selama sesi belajar berlangsung. Berelasi `ON DELETE CASCADE` dengan tabel `study_sessions`.
```sql
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

---

## 🧠 Logika Pemantauan Fokus (AI Focus Logic)

Tingkat kefokusan pengguna dievaluasi setiap detik saat kamera depan aktif mengalirkan data (*streaming image frames*) ke Face Detector ML Kit:

1.  **Yaw & Pitch Thresholds**:
    *   Sudut gelengan wajah kiri-kanan (*Yaw*) dibatasi maksimal $\pm 15^\circ$.
    *   Sudut tunduk-tengadah wajah (*Pitch*) dibatasi maksimal $\pm 15^\circ$.
    *   Jika melampaui batas ini selama lebih dari 3 detik secara kontinu, pengguna dikategorikan **Distracted (Teralihkan)**.
2.  **Eye Open Probability**:
    *   Pintu masuk klasifikasi mata mengantuk/tertutup dihitung dari rata-rata probabilitas mata kiri dan kanan terbuka.
    *   Batas minimum (*Threshold*) diatur sebesar `0.5`. Jika rata-rata di bawah `0.5` selama lebih dari 3 detik, pengguna dikategorikan **Fatigued (Lelah/Mengantuk)**.
3.  **Absent Auto-Pause**:
    *   Jika wajah tidak terdeteksi sama sekali pada kamera depan selama lebih dari **3 detik secara kontinu** (contoh: pengguna meninggalkan meja belajar), sistem akan memicu event `FocusTimerPaused` untuk menghentikan timer secara otomatis demi keakuratan metrik belajar.

---

## 🚀 Cara Menjalankan Aplikasi (Getting Started)

### Prasyarat
1.  **Flutter SDK** (Versi Dart yang disarankan `^3.9.2`).
2.  **Android Studio / VS Code** lengkap dengan emulator Android atau perangkat fisik Android yang memiliki kamera depan aktif.
3.  **Kunci API Google Gemini** (Dapatkan secara gratis melalui [Google AI Studio](https://aistudio.google.com/)).

### Langkah Instalasi

1.  **Kloning Repositori**:
    ```bash
    git clone https://github.com/username/ruang_belajar.git
    cd ruang_belajar
    ```

2.  **Instalasi Dependensi**:
    Unduh paket-paket dependensi pubspec yang diperlukan:
    ```bash
    flutter pub get
    ```

3.  **Setup API Key Gemini**:
    Konfigurasikan API Key Gemini Anda menggunakan variabel lingkungan `--dart-define` saat menjalankan aplikasi.

4.  **Jalankan Aplikasi**:
    *   **Debug / Run via Terminal**:
        ```bash
        flutter run --dart-define=GEMINI_API_KEY=KUNCI_API_GEMINI_ANDA
        ```
    *   **VS Code Configuration (`.vscode/launch.json`)**:
        Tambahkan argumen `toolArgs` agar tidak perlu menulis ulang kunci API di terminal:
        ```json
        {
          "version": "0.2.0",
          "configurations": [
            {
              "name": "Ruang Belajar",
              "request": "launch",
              "type": "dart",
              "toolArgs": [
                "--dart-define",
                "GEMINI_API_KEY=KUNCI_API_GEMINI_ANDA"
              ]
            }
          ]
        }
        ```

---

## 📸 Dokumentasi Antarmuka (Screenshots)

Berikut adalah beberapa tangkapan layar antarmuka aplikasi **Ruang Belajar**:

<p align="center">
  <img src="flutter_01.png" width="300" alt="Dashboard Utama dan Daftar Tugas" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="flutter_02.png" width="300" alt="Timer Pomodoro dengan AI Camera Overlay" />
</p>

*Catatan: Tangkapan layar di atas menunjukkan halaman beranda serta halaman timer fokus Pomodoro yang terintegrasi dengan sensor deteksi wajah (AI Focus Active).*
