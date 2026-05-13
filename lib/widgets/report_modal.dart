import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firestore_service.dart';

class ReportModal extends StatefulWidget {
  final LatLng currentPosition;
  final FirestoreService firestoreService;
  final String? userId;

  const ReportModal({
    super.key,
    required this.currentPosition,
    required this.firestoreService,
    this.userId,
  });

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String? _categoriaSelecionada;
  String _gravidadeSelecionada = 'Média';
  final TextEditingController _descricaoController = TextEditingController();
  bool _isLoading = false;
  XFile? _fotoSelecionada;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  // ── Upload de foto ─────────────────────────────────────────────────────────

  Future<void> _selecionarFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (foto != null) setState(() => _fotoSelecionada = foto);
    } catch (e) {
      _showSnack('Erro ao selecionar foto: $e');
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Adicionar foto',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFDEFF9A)),
              title: const Text('Câmera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _selecionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFDEFF9A)),
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _selecionarFoto(ImageSource.gallery);
              },
            ),
            if (_fotoSelecionada != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remover foto', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _fotoSelecionada = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadFoto() async {
    if (_fotoSelecionada == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('denuncias')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask task;
      if (kIsWeb) {
        final bytes = await _fotoSelecionada!.readAsBytes();
        task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putFile(File(_fotoSelecionada!.path));
      }

      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showSnack('Erro ao fazer upload da foto: $e');
      return null;
    }
  }

  // ── Submissão ─────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    if (_categoriaSelecionada == null) {
      _showSnack('Selecione uma categoria para continuar.');
      return;
    }
    if (_descricaoController.text.trim().isEmpty) {
      _showSnack('Preencha a descrição da ocorrência.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fotoUrl = await _uploadFoto();

      await widget.firestoreService.salvarDenuncia(
        categoria: _categoriaSelecionada!,
        descricao: _descricaoController.text.trim(),
        latitude: widget.currentPosition.latitude,
        longitude: widget.currentPosition.longitude,
        gravidade: _gravidadeSelecionada,
        fotoUrl: fotoUrl,
        userId: widget.userId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Denúncia registrada com sucesso!'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2E2E2E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // final lat = widget.currentPosition.latitude.toStringAsFixed(5);
    // final lng = widget.currentPosition.longitude.toStringAsFixed(5);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF242424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3E3E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Text(
              'Nova Denúncia',
              style: TextStyle(
                color: Color(0xFFDEFF9A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Localização capturada automaticamente.',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Dropdown de categoria
            DropdownButtonFormField<String>(
              value: _categoriaSelecionada,
              hint: const Text('Selecione a categoria'),
              dropdownColor: const Color(0xFF2E2E2E),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              iconEnabledColor: const Color(0xFFDEFF9A),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                labelText: 'Categoria',
                labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDEFF9A), width: 1.5),
                ),
              ),
              items: FirestoreService.categorias
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _categoriaSelecionada = val),
            ),
            const SizedBox(height: 16),

            // Seleção de gravidade
            const Text(
              'Gravidade',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: FirestoreService.gravidades.map((g) {
                final isSelected = _gravidadeSelecionada == g;
                final color = _corGravidade(g);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gravidadeSelecionada = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _iconeGravidade(g),
                            color: isSelected ? color : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? color : Colors.white38,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Campo de descrição
            TextFormField(
              controller: _descricaoController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva o problema encontrado…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Área de foto
            GestureDetector(
              onTap: _mostrarOpcoesFoto,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _fotoSelecionada != null ? 160 : 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fotoSelecionada != null
                        ? const Color(0xFFDEFF9A).withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                    style: BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: _fotoSelecionada != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb
                              ? Image.network(
                                  _fotoSelecionada!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_fotoSelecionada!.path),
                                  fit: BoxFit.cover,
                                ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            color: Color(0xFF9E9E9E),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Adicionar foto (opcional)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão confirmar
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDEFF9A),
                  foregroundColor: const Color(0xFF1A1A1A),
                  disabledBackgroundColor: const Color(0xFF9EAF6A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF1A1A1A),
                        ),
                      )
                    : const Text(
                        'CONFIRMAR DENÚNCIA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _corGravidade(String g) {
    switch (g) {
      case 'Alta':
        return const Color(0xFFF44336);
      case 'Média':
        return const Color(0xFFFFC107);
      case 'Baixa':
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _iconeGravidade(String g) {
    switch (g) {
      case 'Alta':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'Média':
        return Icons.remove_rounded;
      case 'Baixa':
      default:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }
}
