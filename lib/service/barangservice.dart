import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/barangmodel.dart';

class BarangService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Mengambil token dari storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  // Mengambil semua data barang
  Future<List<BarangModel>> getAllBarang() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/barang'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Mengambil data dari key 'data' sesuai struktur API
        final List<dynamic> barangList = data['data'] ?? [];

        return barangList.map((json) => BarangModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil data barang');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Mengambil detail barang berdasarkan ID
  Future<BarangModel> getBarangById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/barang/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return BarangModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Barang tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengambil detail barang');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Mencari barang berdasarkan nama
  Future<List<BarangModel>> searchBarang(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/barang?search=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> barangList = data['data'] ?? [];

        return barangList.map((json) => BarangModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mencari barang');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Menambah barang baru (jika diperlukan)
  Future<BarangModel> createBarang({
    required String namaBarang,
    required int stok,
    required String deskripsi,
    String? foto,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/barang'),
        headers: headers,
        body: jsonEncode({
          'nama_barang': namaBarang,
          'stok': stok,
          'deskripsi': deskripsi,
          if (foto != null) 'foto': foto,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return BarangModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal menambah barang');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Update barang (jika diperlukan)
  Future<BarangModel> updateBarang({
    required int id,
    String? namaBarang,
    int? stok,
    String? deskripsi,
    String? foto,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {};

      if (namaBarang != null) body['nama_barang'] = namaBarang;
      if (stok != null) body['stok'] = stok;
      if (deskripsi != null) body['deskripsi'] = deskripsi;
      if (foto != null) body['foto'] = foto;

      final response = await http.put(
        Uri.parse('$baseUrl/barang/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return BarangModel.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Barang tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal mengupdate barang');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  // Delete barang (jika diperlukan)
  Future<bool> deleteBarang(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/barang/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah expired');
      } else if (response.statusCode == 404) {
        throw Exception('Barang tidak ditemukan');
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Gagal menghapus barang');
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
