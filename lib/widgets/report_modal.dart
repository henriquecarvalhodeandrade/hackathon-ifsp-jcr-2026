import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';

class ReportModal extends StatefulWidget {
  final LatLng currentPosition;
  final FirestoreService firestoreService;

  const ReportModal({
    super.key,
    required this.currentPosition,
    required this.firestoreService,
  });

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  // Categorias disponíveis
  static const List<String> _categorias = [
    'Buraco na Via',
    'Iluminação Pública',
    'Acúmulo de Lixo',
    'Enchente/Drenagem',
  ];

  String? _categoriaSelecionada;
  final TextEditingController _descricaoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  // ── Submissão ─────────────────────────────────────────────────────────────

  Future<void> _submitReport() async {
    // Validação dos campos
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
      if (mounted) {
        _showSnack('Erro ao salvar: $e');
      }
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF242424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
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
          const SizedBox(height: 24),

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
            items: _categorias
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) => setState(() => _categoriaSelecionada = val),
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
          const SizedBox(height: 28),

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
    );
  }
}
