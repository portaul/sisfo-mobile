import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/peminjamanmodel.dart';

class PeminjamanService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Mengambil token dari storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Mengambil user ID dari storage
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Membuat headers dengan authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Membuat peminjaman baru dengan status default 'pending'
  Future<PeminjamanModel> createPeminjaman({
    required int barangId,
    required String namaPeminjam,
    required String tanggalPinjam,
    required String tanggalKembali,
  }) async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();

      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/peminjaman'),
        headers: headers,
        body: jsonEncode({
          'barang_id': barangId,
          'user_id': userId,
          'nama_peminjam': namaPeminjam,
          'tanggal_pinjam': tanggalPinjam,
          'tanggal_kembali': tanggalKembali,
          'status': 'pending', // Default status
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PeminjamanModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal membuat peminjaman');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Mengambil semua data peminjaman
  Future<List<PeminjamanModel>> getAllPeminjaman() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> peminjamanList = data['data'] ?? [];

        return peminjamanList
            .map((json) => PeminjamanModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil data peminjaman');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Mengambil peminjaman berdasarkan user yang sedang login
  Future<List<PeminjamanModel>> getMyPeminjaman() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();

      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman/user/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> peminjamanList = data['data'] ?? [];

        return peminjamanList
            .map((json) => PeminjamanModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil data peminjaman');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Mengambil detail peminjaman berdasarkan ID
  Future<PeminjamanModel> getPeminjamanById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/peminjaman/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PeminjamanModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Peminjaman tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Gagal mengambil detail peminjaman',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Update status peminjaman (untuk admin)
  Future<PeminjamanModel> updateStatusPeminjaman({
    required int id,
    required String status,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/peminjaman/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PeminjamanModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Peminjaman tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Gagal mengupdate status peminjaman',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Update peminjaman
  Future<PeminjamanModel> updatePeminjaman({
    required int id,
    int? barangId,
    String? namaPeminjam,
    String? tanggalPinjam,
    String? tanggalKembali,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {};

      if (barangId != null) body['barang_id'] = barangId;
      if (namaPeminjam != null) body['nama_peminjam'] = namaPeminjam;
      if (tanggalPinjam != null) body['tanggal_pinjam'] = tanggalPinjam;
      if (tanggalKembali != null) body['tanggal_kembali'] = tanggalKembali;

      final response = await http.put(
        Uri.parse('$baseUrl/peminjaman/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PeminjamanModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Peminjaman tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengupdate peminjaman');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Delete peminjaman
  Future<bool> deletePeminjaman(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/peminjaman/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Peminjaman tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal menghapus peminjaman');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }
}
