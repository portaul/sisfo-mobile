import 'package:flutter/material.dart';
import '../../model/barangmodel.dart';
import '../../model/peminjamanmodel.dart';
import '../../service/barangservice.dart';
import '../../service/peminjamanservice.dart';

class PeminjamanFormView extends StatefulWidget {
  const PeminjamanFormView({super.key});

  @override
  State<PeminjamanFormView> createState() => _PeminjamanFormViewState();
}

class _PeminjamanFormViewState extends State<PeminjamanFormView> {
  final _formKey = GlobalKey<FormState>();
  final _namaPeminjamController = TextEditingController();
  final _tanggalPinjamController = TextEditingController();
  final _tanggalKembaliController = TextEditingController();

  final BarangService _barangService = BarangService();
  final PeminjamanService _peminjamanService = PeminjamanService();

  List<BarangModel> _availableBarang = [];
  BarangModel? _selectedBarang;
  bool _isLoading = false;
  bool _isLoadingBarang = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableBarang();
  }

  @override
  void dispose() {
    _namaPeminjamController.dispose();
    _tanggalPinjamController.dispose();
    _tanggalKembaliController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableBarang() async {
    setState(() {
      _isLoadingBarang = true;
      _errorMessage = null;
    });

    try {
      final barangList = await _barangService.getAllBarang();
      // Filter hanya barang yang tersedia (stok > 0)
      final availableBarang =
          barangList.where((barang) => barang.stok > 0).toList();

      if (mounted) {
        setState(() {
          _availableBarang = availableBarang;
          _isLoadingBarang = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoadingBarang = false;
        });
      }
    }
  }

  Future<void> _selectDate(
    TextEditingController controller, {
    DateTime? firstDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBarang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih barang yang akan dipinjam'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final peminjaman = await _peminjamanService.createPeminjaman(
        barangId: _selectedBarang!.id,
        namaPeminjam: _namaPeminjamController.text.trim(),
        tanggalPinjam: _tanggalPinjamController.text,
        tanggalKembali: _tanggalKembaliController.text,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                title: const Text('Berhasil!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Peminjaman berhasil dibuat dengan status pending.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID Peminjaman: #${peminjaman.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Back to previous page
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateNamaPeminjam(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama peminjam tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama peminjam minimal 3 karakter';
    }
    return null;
  }

  String? _validateTanggal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal tidak boleh kosong';
    }
    return null;
  }

  String? _validateTanggalKembali(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal kembali tidak boleh kosong';
    }

    if (_tanggalPinjamController.text.isNotEmpty) {
      try {
        final tanggalPinjam = DateTime.parse(_tanggalPinjamController.text);
        final tanggalKembali = DateTime.parse(value);

        if (tanggalKembali.isBefore(tanggalPinjam) ||
            tanggalKembali.isAtSameMomentAs(tanggalPinjam)) {
          return 'Tanggal kembali harus setelah tanggal pinjam';
        }
      } catch (e) {
        return 'Format tanggal tidak valid';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Peminjaman'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body:
          _isLoadingBarang
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat data barang...'),
                  ],
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi Kesalahan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadAvailableBarang,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
              : _availableBarang.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak Ada Barang Tersedia',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semua barang sedang tidak tersedia untuk dipinjam',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Card
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Peminjaman akan dibuat dengan status "Pending" dan menunggu persetujuan admin.',
                                  style: TextStyle(color: Colors.blue[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pilih Barang
                      Text(
                        'Pilih Barang',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            _selectedBarang == null
                                ? InkWell(
                                  onTap: _showBarangSelection,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Tap untuk memilih barang',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey[400],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : InkWell(
                                  onTap: _showBarangSelection,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: Colors.grey[200],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child:
                                                _selectedBarang!.foto.isNotEmpty
                                                    ? Image.network(
                                                      _selectedBarang!
                                                          .fullImageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons
                                                              .inventory_2_outlined,
                                                          color:
                                                              Colors.grey[400],
                                                        );
                                                      },
                                                    )
                                                    : Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      color: Colors.grey[400],
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedBarang!.namaBarang,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Stok: ${_selectedBarang!.stok}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit,
                                          color: Colors.grey[400],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 24),

                      // Nama Peminjam
                      TextFormField(
                        controller: _namaPeminjamController,
                        validator: _validateNamaPeminjam,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nama Peminjam',
                          hintText: 'Masukkan nama peminjam',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanggal Pinjam
                      TextFormField(
                        controller: _tanggalPinjamController,
                        validator: _validateTanggal,
                        readOnly: true,
                        onTap: () => _selectDate(_tanggalPinjamController),
                        decoration: InputDecoration(
                          labelText: 'Tanggal Pinjam',
                          hintText: 'Pilih tanggal pinjam',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tanggal Kembali
                      TextFormField(
                        controller: _tanggalKembaliController,
                        validator: _validateTanggalKembali,
                        readOnly: true,
                        onTap: () {
                          DateTime? firstDate;
                          if (_tanggalPinjamController.text.isNotEmpty) {
                            try {
                              firstDate = DateTime.parse(
                                _tanggalPinjamController.text,
                              ).add(const Duration(days: 1));
                            } catch (e) {
                              firstDate = DateTime.now().add(
                                const Duration(days: 1),
                              );
                            }
                          } else {
                            firstDate = DateTime.now().add(
                              const Duration(days: 1),
                            );
                          }
                          _selectDate(
                            _tanggalKembaliController,
                            firstDate: firstDate,
                          );
                        },
                        decoration: InputDecoration(
                          labelText: 'Tanggal Kembali',
                          hintText: 'Pilih tanggal kembali',
                          prefixIcon: const Icon(
                            Icons.event_available_outlined,
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Ajukan Peminjaman',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  void _showBarangSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pilih Barang',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableBarang.length,
                        itemBuilder: (context, index) {
                          final barang = _availableBarang[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      barang.foto.isNotEmpty
                                          ? Image.network(
                                            barang.fullImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.inventory_2_outlined,
                                                color: Colors.grey[400],
                                              );
                                            },
                                          )
                                          : Icon(
                                            Icons.inventory_2_outlined,
                                            color: Colors.grey[400],
                                          ),
                                ),
                              ),
                              title: Text(
                                barang.namaBarang,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (barang.deskripsi.isNotEmpty)
                                    Text(
                                      barang.deskripsi,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    'Stok: ${barang.stok}',
                                    style: TextStyle(
                                      color:
                                          barang.stok > 5
                                              ? Colors.green
                                              : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  _selectedBarang?.id == barang.id
                                      ? Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).primaryColor,
                                      )
                                      : const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                              onTap: () {
                                setState(() {
                                  _selectedBarang = barang;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
