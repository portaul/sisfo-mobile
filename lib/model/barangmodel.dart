class BarangModel {
  final int id;
  final String namaBarang;
  final int stok;
  final String deskripsi;
  final String foto;

  BarangModel({
    required this.id,
    required this.namaBarang,
    required this.stok,
    required this.deskripsi,
    required this.foto,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      id: json['id'] ?? 0,
      namaBarang: json['nama_barang'] ?? '',
      stok: json['stok'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      foto: json['foto'] ?? '',
    );
  }

  // Method untuk convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_barang': namaBarang,
      'stok': stok,
      'deskripsi': deskripsi,
      'foto': foto,
    };
  }

  // Method untuk membuat copy dengan perubahan
  BarangModel copyWith({
    int? id,
    String? namaBarang,
    int? stok,
    String? deskripsi,
    String? foto,
  }) {
    return BarangModel(
      id: id ?? this.id,
      namaBarang: namaBarang ?? this.namaBarang,
      stok: stok ?? this.stok,
      deskripsi: deskripsi ?? this.deskripsi,
      foto: foto ?? this.foto,
    );
  }

  @override
  String toString() {
    return 'BarangModel(id: $id, namaBarang: $namaBarang, stok: $stok, deskripsi: $deskripsi, foto: $foto)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarangModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  bool get isAvailable => stok > 0;
  bool get isOutOfStock => stok <= 0;

  String get stockStatus {
    if (stok <= 0) return 'Habis';
    if (stok <= 5) return 'Stok Menipis';
    return 'Tersedia';
  }

  // Get full image URL
  String get fullImageUrl {
    if (foto.isEmpty) return '';
    if (foto.startsWith('http')) return foto;
    return 'http://127.0.0.1:8000/storage/$foto';
  }
}
