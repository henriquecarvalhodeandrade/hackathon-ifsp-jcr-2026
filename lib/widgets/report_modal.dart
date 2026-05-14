import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/firestore_service.dart';
import '../services/geocoding_service.dart';

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
  final _descricaoController = TextEditingController();
  bool _isLoading = false;

  // Endereço resolvido automaticamente
  String? _enderecoResolvido;
  bool _resolvendoEndereco = true;

  @override
  void initState() {
    super.initState();
    _resolverEndereco();
  }

  Future<void> _resolverEndereco() async {
    final endereco = await GeocodingService.reverseGeocode(
      widget.currentPosition.latitude,
      widget.currentPosition.longitude,
    );
    if (mounted) {
      setState(() {
        _enderecoResolvido = endereco;
        _resolvendoEndereco = false;
      });
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

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
      await widget.firestoreService.salvarDenuncia(
        categoria: _categoriaSelecionada!,
        descricao: _descricaoController.text.trim(),
        latitude: widget.currentPosition.latitude,
        longitude: widget.currentPosition.longitude,
        gravidade: _gravidadeSelecionada,
        userId: widget.userId,
        endereco: _enderecoResolvido,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Denúncia registrada com sucesso!', style: TextStyle(color: Colors.white, fontSize: 14)),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF3E3E3E), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Nova Denúncia', style: TextStyle(color: Color(0xFFDEFF9A), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 4),

            // Endereço resolvido
            _buildEnderecoInfo(),

            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _categoriaSelecionada,
              hint: const Text('Selecione a categoria'),
              dropdownColor: const Color(0xFF2E2E2E),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              iconEnabledColor: const Color(0xFFDEFF9A),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFF2E2E2E),
                labelText: 'Categoria',
                labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDEFF9A), width: 1.5)),
              ),
              items: FirestoreService.categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoriaSelecionada = v),
            ),
            const SizedBox(height: 16),
            const Text('Gravidade', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: FirestoreService.gravidades.map((g) {
                final sel = _gravidadeSelecionada == g;
                final c = _corGravidade(g);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gravidadeSelecionada = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? c.withOpacity(0.2) : const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? c : Colors.transparent, width: 1.5),
                      ),
                      child: Column(children: [
                        Icon(_iconeGravidade(g), color: sel ? c : Colors.white38, size: 18),
                        const SizedBox(height: 4),
                        Text(g, textAlign: TextAlign.center, style: TextStyle(color: sel ? c : Colors.white38, fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController, maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Descrição', hintText: 'Descreva o problema encontrado…', alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDEFF9A), foregroundColor: const Color(0xFF1A1A1A),
                  disabledBackgroundColor: const Color(0xFF9EAF6A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A1A1A)))
                    : const Text('CONFIRMAR DENÚNCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnderecoInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFFDEFF9A), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: _resolvendoEndereco
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF9E9E9E))),
                      const SizedBox(width: 8),
                      Text('Buscando endereço...', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    ],
                  )
                : Text(
                    _enderecoResolvido ?? 'Endereço não encontrado',
                    style: TextStyle(
                      color: _enderecoResolvido != null ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.35),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  Color _corGravidade(String g) => switch (g) { 'Alta' => const Color(0xFFF44336), 'Média' => const Color(0xFFFFC107), _ => const Color(0xFF4CAF50) };
  IconData _iconeGravidade(String g) => switch (g) { 'Alta' => Icons.keyboard_double_arrow_up_rounded, 'Média' => Icons.remove_rounded, _ => Icons.keyboard_double_arrow_down_rounded };
}
