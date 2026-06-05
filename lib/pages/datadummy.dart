import 'package:kinday/constant/app_widget.dart';

List<TaskCard> dummydata = [
  TaskCard(
    title: "Slicing UI Dashboard Utama",
    description:
        "Bikin halaman utama pakai CustomScrollView dan animasi transisi.",
    energylvl: 5, // High Energy
    prioritytask: 3, // High Priority
  ),
  TaskCard(
    title: "Fixing Bug Overflow Form Login",
    description:
        "Bungkus Column pakai SingleChildScrollView biar ga error pixel.",
    energylvl: 3, // Mid Energy
    prioritytask: 3, // High Priority
  ),
  TaskCard(
    title: "Setup Integrasi SQFLite Database",
    description:
        "Buat class DatabaseHelper, skema tabel task, dan fungsi CRUD.",
    energylvl: 5, // High Energy
    prioritytask: 3, // High Priority
  ),
  TaskCard(
    title: "Meeting Evaluasi Mingguan",
    description:
        "Bahas progress sprint 1 dan rintangan yang dihadapi bareng tim.",
    energylvl: 2, // Mid-Low
    prioritytask: 3, // High Priority
  ),
  TaskCard(
    title: "Integrasi API Jadwal Harian",
    description:
        "Setup service http request untuk fetch data user dari server.",
    energylvl: 4, // Mid-High
    prioritytask: 2, // Medium Priority
  ),
  TaskCard(
    title: "Review Code Pull Request Tim",
    description:
        "Cek codingan dari frontend developer lain untuk modul profile.",
    energylvl: 4, // Mid-High
    prioritytask: 2, // Medium Priority
  ),
  TaskCard(
    title: "Bikin Dokumentasi Struktur Project",
    description:
        "Tulis berkas README.md untuk panduan arsitektur folder folder.",
    energylvl: 2, // Mid-Low
    prioritytask: 2, // Medium Priority
  ),
  TaskCard(
    title: "Desain Ulang Komponen Dialog Pop-up",
    description:
        "Sesuaikan radius border dan skema warna biar makin aesthetic.",
    energylvl: 3, // Mid Energy
    prioritytask: 2, // Medium Priority
  ),
  TaskCard(
    title: "Persiapan Presentasi Flutter",
    description: "Siapkan slide materi State Management dan demo widget dasar.",
    energylvl: 2, // Mid-Low
    prioritytask: 3, // Low Priority
  ),
  TaskCard(
    title: "Cari Aset Ikon Lucu di Figma",
    description: "Download beberapa ilustrasi 3D tambahan untuk dekorasi app.",
    energylvl: 1, // Low Energy
    prioritytask: 3, // Low Priority
  ),
  TaskCard(
    title: "Refactor Fungsi Validasi Form",
    description: "Sederhanakan regex validasi email dan password biar clean.",
    energylvl: 3, // Mid Energy
    prioritytask: 3, // Low Priority
  ),
  TaskCard(
    title: "Merapikan File Lipatan Assets",
    description:
        "Kelompokkan gambar png, jpeg, dan svg ke foldernya masing-masing.",
    energylvl: 1, // Low Energy
    prioritytask: 3, // Low Priority
  ),
  TaskCard(
    title: "Research Package State Management",
    description:
        "Bandingkan performa Provider, Bloc, dan Riverpod untuk skala besar.",
    energylvl: 4, // Mid-High
    prioritytask: 3, // High Priority
  ),
  TaskCard(
    title: "Update Dependency pubspec.yaml",
    description:
        "Naikkan versi beberapa package ke yang paling stabil (stable release).",
    energylvl: 2, // Mid-Low
    prioritytask: 3, // Low Priority
  ),
  TaskCard(
    title: "Testing Aplikasi di Emulator Lama",
    description:
        "Pastikan layout tidak hancur saat dijalankan di Android versi 9.",
    energylvl: 3, // Mid Energy
    prioritytask: 2, // Medium Priority
  ),
];
