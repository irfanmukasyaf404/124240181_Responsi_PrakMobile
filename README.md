# SpaceNews Explorer 🚀

Aplikasi mobile Flutter untuk responsi Praktikum Pemrograman Mobile: **SpaceNews Explorer**. Aplikasi ini menyajikan berita terkini seputar eksplorasi luar angkasa dengan integrasi API Spaceflight News dan penyimpanan data lokal menggunakan SQLite (Local Database).

---

## 📋 Fitur Aplikasi Sesuai Ketentuan Soal

### 1. Halaman Register dan Login (Local Database)
- **Registrasi Akun Baru**: Pengguna dapat mendaftarkan akun (username, password, dan konfirmasi password) yang divalidasi dan disimpan langsung ke database lokal SQLite (`users` table).
- **Validasi Lengkap**: Pengecekan username unik (tidak boleh duplikat), panjang minimal karakter, serta kecocokan konfirmasi password.
- **Login Akun**: Otentikasi username dan password terhadap database lokal.
- **Session Management**: Menggunakan `SharedPreferences` untuk menyimpan status sesi pengguna yang sedang login.
- **Feedback Visual**: Menampilkan `SnackBar` hijau saat berhasil dan merah saat gagal/salah input.

### 2. Halaman Home
- **Daftar Berita (>10 Berita)**: Mengambil data berita dari endpoint Spaceflight News API (`https://api.spaceflightnewsapi.net/v4/articles`).
- **Informasi Kartu Berita**:
  - Gambar berita (`image_url`) dengan animasi pemuatan dan fallback gambar rusak.
  - Judul berita (`title`).
  - Sumber berita / News site (`news_site`).
  - Tanggal publikasi (`published_at`) yang diformat rapi (misal: `16 Nov 2026, 12:05`).
- **AppBar Khusus**:
  - Menampilkan **username pengguna yang sedang login** pada title AppBar.
  - Sediakan button di sebelah kanan AppBar yang mengarah langsung ke **Halaman Bookmark**.
  - Dilengkapi tombol Logout dengan dialog konfirmasi.
- **Loading Indicator**: Menampilkan `CircularProgressIndicator` saat data sedang dimuat dari internet.
- **Fitur Tambahan (Bonus)**:
  - Fitur Search / Pencarian berita luar angkasa berdasarkan kata kunci.
  - Fitur Pull-to-Refresh untuk memuat ulang berita terkini.

### 3. Fitur Filter Berita (pada Halaman Home)
- Pengguna dapat memilih dan memfilter berita berdasarkan sumber publikasi (`news_site`), seperti NASA, SpaceNews, Space.com, NASASpaceflight, SpaceX, ESA, dll.
- Pilihan kategori filter diambil dinamis dari endpoint API info (`https://api.spaceflightnewsapi.net/v4/info/`) dengan opsi "Semua" untuk mereset filter.

### 4. Halaman Detail Berita
- Dibuka ketika salah satu berita pada daftar diklik.
- Menampilkan:
  - Gambar banner berita.
  - Judul lengkap berita.
  - Sumber berita (badge sumber).
  - Tanggal publikasi terformat.
  - Penulis berita (`authors`).
  - Ringkasan berita (`summary`).
- **Tombol Read Full Article**: Membuka tautan artikel asli di browser menggunakan `url_launcher`.
- **Tombol Bookmark Interaktif**:
  - **Tambah Bookmark**: Menekan icon bookmark yang belum aktif akan menyimpannya ke database lokal, icon berubah warna (kuning/amber), dan memunculkan **SnackBar hijau** ("*Berita berhasil ditambahkan ke bookmark*").
  - **Hapus Bookmark**: Menekan icon bookmark yang aktif akan menghapusnya dari database lokal, icon kembali ke semula (putih outline), dan memunculkan **SnackBar merah** ("*Berita dihapus dari bookmark*").

### 5. Halaman Bookmark
- Menampilkan seluruh berita yang telah ditambahkan ke bookmark dari database lokal SQLite.
- **Swipe to Delete (Dismissible)**: Pengguna dapat menghapus berita dari bookmark cukup dengan menggeser (swipe) ke kiri dengan latar belakang merah dan ikon tempat sampah.
- **Sinkronisasi Database**: Berita yang dihapus langsung terhapus dari tabel database SQLite dan daftar UI diperbarui otomatis dengan notifikasi SnackBar merah.
- **Empty State**: Tampilan ilustrasi informatif jika belum ada berita yang disimpan.

---

## 🛠️ Struktur Proyek

```text
lib/
├── models/
│   ├── article_model.dart     # Model data artikel (JSON API & SQLite mapping)
│   └── user_model.dart        # Model data pengguna
├── services/
│   ├── api_service.dart       # Pengambilan data API (Spaceflight News v4)
│   └── database_helper.dart   # Manajemen SQLite (User, Bookmark, Session)
├── screens/
│   ├── login_screen.dart      # Layar Login pengguna
│   ├── register_screen.dart   # Layar Registrasi akun
│   ├── home_screen.dart       # Layar Beranda (List berita, filter, search, appbar user)
│   ├── detail_screen.dart     # Layar Detail berita (Read Full Article, Bookmark toggle)
│   └── bookmark_screen.dart   # Layar Bookmark (Swipe to delete)
└── main.dart                  # Entry point aplikasi & konfigurasi tema
```

---

## 🚀 Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK telah terpasang di sistem.
2. Unduh dependensi:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi pada perangkat/emulator yang tersedia:
   - **Emulator Android**:
     ```bash
     flutter emulators --launch Pixel_6_Pro
     flutter run -d android
     ```
   - **Google Chrome / Edge (Web)**:
     ```bash
     flutter run -d chrome
     ```
   - **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```

4. Menjalankan pengujian:
   ```bash
   flutter test
   ```
