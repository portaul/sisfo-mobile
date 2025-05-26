class PeminjamanModel {
  final int id;
  final int barangId;
  final int userId;
  final String namaPeminjam;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String status;

  PeminjamanModel({
    required this.id,
    required this.barangId,
    required this.userId,
    required this.namaPeminjam,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.status,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory PeminjamanModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanModel(
      id: json['id'] ?? 0,
      barangId: json['barang_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      namaPeminjam: json['nama_peminjam'] ?? '',
      tanggalPinjam: json['tanggal_pinjam'] ?? '',
      tanggalKembali: json['tanggal_kembali'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  // Method untuk convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barang_id': barangId,
      'user_id': userId,
      'nama_peminjam': namaPeminjam,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
      'status': status,
    };
  }

  // Method untuk membuat copy dengan perubahan
  PeminjamanModel copyWith({
    int? id,
    int? barangId,
    int? userId,
    String? namaPeminjam,
    String? tanggalPinjam,
    String? tanggalKembali,
    String? status,
  }) {
    return PeminjamanModel(
      id: id ?? this.id,
      barangId: barangId ?? this.barangId,
      userId: userId ?? this.userId,
      namaPeminjam: namaPeminjam ?? this.namaPeminjam,
      tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
      tanggalKembali: tanggalKembali ?? this.tanggalKembali,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'PeminjamanModel(id: $id, barangId: $barangId, userId: $userId, namaPeminjam: $namaPeminjam, tanggalPinjam: $tanggalPinjam, tanggalKembali: $tanggalKembali, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeminjamanModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods untuk status
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isReturned => status.toLowerCase() == 'returned';

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'returned':
        return 'Dikembalikan';
      default:
        return status;
    }
  }

  // Helper untuk parsing tanggal
  DateTime? get tanggalPinjamDate {
    try {
      return DateTime.parse(tanggalPinjam);
    } catch (e) {
      return null;
    }
  }

  DateTime? get tanggalKembaliDate {
    try {
      return DateTime.parse(tanggalKembali);
    } catch (e) {
      return null;
    }
  }

  // Helper untuk format tanggal display
  String get tanggalPinjamFormatted {
    final date = tanggalPinjamDate;
    if (date == null) return tanggalPinjam;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get tanggalKembaliFormatted {
    final date = tanggalKembaliDate;
    if (date == null) return tanggalKembali;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper untuk durasi peminjaman
  int get durasiHari {
    final pinjam = tanggalPinjamDate;
    final kembali = tanggalKembaliDate;
    if (pinjam == null || kembali == null) return 0;
    return kembali.difference(pinjam).inDays;
  }

  // Helper untuk status warna
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      case 'returned':
        return 'blue';
      default:
        return 'grey';
    }
  }
}
