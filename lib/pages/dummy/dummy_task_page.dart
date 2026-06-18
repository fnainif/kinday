import 'package:flutter/material.dart';

class DummyTask {
  final String title;
  final String description;
  final String dueDate;
  final String dueTime;
  final String priority;
  final String energyLevelNeeded;
  final List<String> subtasks;

  DummyTask({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.energyLevelNeeded,
    this.subtasks = const [],
  });
}

final List<DummyTask> dummyTasks = [
  DummyTask(
    title: 'Belanja Bulanan di Supermarket',
    description: 'Membeli stok bahan makanan, produk perawatan tubuh, dan kebutuhan rumah tangga untuk persediaan satu bulan ke depan. Jangan lupa bawa kantong belanja sendiri.',
    dueDate: '2026-06-15',
    dueTime: '10:00 AM',
    priority: 'High',
    energyLevelNeeded: 'High',
    subtasks: [
      'Beli beras dan minyak goreng',
      'Beli sabun mandi dan shampoo',
      'Beli tisu wajah dan tisu dapur',
      'Beli buah-buahan segar',
    ],
  ),
  DummyTask(
    title: 'Bersihkan dan Rapikan Inbox Email',
    description: 'Sortir email masuk yang menumpuk. Hapus spam, arsipkan email lama yang sudah selesai, dan tandai email penting yang butuh tindak lanjut segera.',
    dueDate: '2026-06-12',
    dueTime: '04:00 PM',
    priority: 'Medium',
    energyLevelNeeded: 'Mid-low',
  ),
  DummyTask(
    title: 'Olahraga Ringan (Stretching)',
    description: 'Lakukan peregangan seluruh tubuh selama 15 menit untuk mengurangi kaku otot akibat terlalu lama duduk di depan laptop.',
    dueDate: '2026-06-11',
    dueTime: '05:30 PM',
    priority: 'Low',
    energyLevelNeeded: 'Low',
  ),
  DummyTask(
    title: 'Evaluasi Laporan Keuangan Bulanan',
    description: 'Tinjau kembali arus kas masuk dan keluar selama sebulan terakhir. Bandingkan dengan target budget yang sudah ditetapkan di awal bulan.',
    dueDate: '2026-06-14',
    dueTime: '01:00 PM',
    priority: 'High',
    energyLevelNeeded: 'Mid-high',
    subtasks: [
      'Unduh rekening koran/mutasi bank',
      'Rekap pengeluaran kategori makanan & transportasi',
      'Hitung sisa alokasi dana tabungan',
    ],
  ),
  DummyTask(
    title: 'Diskusi Proyek Baru dengan Klien',
    description: 'Diskusi awal mengenai scope of work, target audiens, dan timeline pengerjaan proyek desain aplikasi terbaru bersama pihak klien.',
    dueDate: '2026-06-16',
    dueTime: '11:00 AM',
    priority: 'Medium',
    energyLevelNeeded: 'Medium',
    subtasks: [
      'Siapkan dokumen proposal proyek',
      'Cek kembali koneksi internet dan audio sebelum meeting',
    ],
  ),
];

class DummyTaskPage extends StatelessWidget {
  const DummyTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dummy Tasks'),
      ),
      body: ListView.builder(
        itemCount: dummyTasks.length,
        itemBuilder: (context, index) {
          final task = dummyTasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(task.description),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('${task.dueDate}  ${task.dueTime}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('Priority: ${task.priority}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.battery_charging_full, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('Energy: ${task.energyLevelNeeded}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Subtasks:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...task.subtasks.map((subtask) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(subtask)),
                            ],
                          ),
                        )),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
