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
  static const List<String> _categorias = [
    'Buraco na Via',
    'Iluminação Pública',
    'Acúmulo de Lixo',
    'Enchente/Drenagem',
  ];

  String? _categoriaSelecionada;
  final TextEditingController _descricaoController = TextEditingController();
  bool _isLoading = false;

  // [AJUSTE 1] Foto é totalmente opcional — null significa "sem foto".
  // Adicione aqui a lógica de câmera quando quiser (ex: image_picker).
  // String? _fotoPath;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  // ── [AJUSTE 1] Submissão — foto é opcional ─────────────────────────────────

  Future<void> _submitReport() async {
    // Valida somente os campos obrigatórios (categoria + descrição).
    // A ausência de foto NÃO impede o envio.
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
        // fotoUrl: _fotoPath,  // passe aqui quando implementar a câmera
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
    final lat = widget.currentPosition.latitude.toStringAsFixed(5);
    final lng = widget.currentPosition.longitude.toStringAsFixed(5);

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

          // [AJUSTE 2] Mostra as coordenadas da mira (centro do mapa)
          Row(
            children: [
              const Icon(Icons.location_pin,
                  color: Color(0xFFDEFF9A), size: 14),
              const SizedBox(width: 4),
              Text(
                '$lat, $lng  •  posição da mira',
                style: const TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 12),
              ),
            ],
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
                borderSide:
                    const BorderSide(color: Color(0xFFDEFF9A), width: 1.5),
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
          const SizedBox(height: 12),

          // [AJUSTE 1] Indicador visual de que a foto é opcional
          Row(
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: Color(0xFF616161), size: 16),
              const SizedBox(width: 6),
              const Text(
                'Foto opcional — implemente image_picker para habilitar',
                style: TextStyle(color: Color(0xFF616161), fontSize: 11),
              ),
            ],
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
    );
  }
}
