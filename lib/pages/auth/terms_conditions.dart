import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_widget.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.button),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Syarat & Ketentuan",
            style: TextStyle(
              color: AppColors.button,
              fontFamily: "Super",
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1,
                  style: BorderStyle.solid,
                  color: AppColors.background,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Syarat & Ketentuan Penggunaan Kinday",
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.button,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Terakhir diperbarui: 8 Juli 2026",
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 12,
                        color: AppColors.button.withAlpha(153),
                      ),
                    ),
                    const Divider(height: 30),
                    _buildSectionTitle("1. Pengenalan"),
                    _buildSectionBody(
                      "Selamat datang di Kinday! Dengan membuat akun atau menggunakan aplikasi kami, Anda setuju untuk terikat oleh Syarat dan Ketentuan ini. Harap baca dokumen ini dengan saksama sebelum menggunakan Layanan kami.",
                    ),
                    _buildSectionTitle("2. Akun Pengguna"),
                    _buildSectionBody(
                      "Untuk menggunakan fitur tertentu, Anda wajib membuat akun dengan menyediakan informasi yang akurat dan lengkap. Anda bertanggung jawab penuh untuk menjaga kerahasiaan kata sandi akun Anda dan atas semua aktivitas yang terjadi di bawah akun Anda.",
                    ),
                    _buildSectionTitle("3. Penggunaan Layanan"),
                    _buildSectionBody(
                      "Anda setuju untuk menggunakan Kinday hanya untuk tujuan yang sah dan tidak melanggar hukum atau hak orang lain. Anda dilarang keras menyalahgunakan sistem kami, mencoba mengakses data pengguna lain tanpa izin, atau mengganggu kinerja aplikasi.",
                    ),
                    _buildSectionTitle("4. Hak Kekayaan Intelektual"),
                    _buildSectionBody(
                      "Semua materi, desain, logo, dan kode di dalam Kinday merupakan hak milik eksklusif kami atau pemberi lisensi kami. Anda tidak diperbolehkan menyalin, memodifikasi, mendistribusikan, atau menjual bagian apa pun dari Layanan kami tanpa persetujuan tertulis dari kami.",
                    ),
                    _buildSectionTitle("5. Batasan Tanggung Jawab"),
                    _buildSectionBody(
                      "Kinday disediakan 'sebagaimana adanya' tanpa jaminan apa pun, baik tersurat maupun tersirat. Kami tidak bertanggung jawab atas kerugian langsung, tidak langsung, atau konsekuensial yang timbul dari penggunaan atau ketidakmampuan Anda untuk menggunakan aplikasi kami.",
                    ),
                    _buildSectionTitle("6. Perubahan Ketentuan"),
                    _buildSectionBody(
                      "Kami berhak mengubah atau memperbarui Syarat dan Ketentuan ini kapan saja. Perubahan akan berlaku segera setelah dipublikasikan di dalam aplikasi. Penggunaan berkelanjutan Anda setelah perubahan tersebut dianggap sebagai persetujuan Anda terhadap ketentuan baru.",
                    ),
                    _buildSectionTitle("7. Hubungi Kami"),
                    _buildSectionBody(
                      "Jika Anda memiliki pertanyaan tentang Syarat dan Ketentuan ini, silakan hubungi kami melalui email dukungan kami di harumone.airin@gmail.com.",
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: "Nunito",
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.button,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Text(
      body,
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontFamily: "Nunito",
        fontSize: 13,
        height: 1.5,
        color: AppColors.button.withAlpha(204),
      ),
    );
  }
}
