import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ReportDetailSheet extends StatefulWidget {
  final Denuncia denuncia;
  final FirestoreService firestoreService;
  final bool isLoggedIn;

  const ReportDetailSheet({
    super.key,
    required this.denuncia,
    required this.firestoreService,
    required this.isLoggedIn,
  });

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  late String _statusAtual;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _statusAtual = widget.denuncia.status;
  }

  Future<void> _atualizarStatus(String novoStatus) async {
    setState(() => _isUpdating = true);
    try {
      await widget.firestoreService.atualizarStatus(
        widget.denuncia.id,
        novoStatus,
      );
      if (mounted) {
        setState(() => _statusAtual = novoStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status atualizado para "$novoStatus".'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: const Color(0xFF2E2E2E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _mostrarOpcaoStatus() {
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
              'Atualizar Status',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...FirestoreService.statusList.map((s) {
              final isAtual = s == _statusAtual;
              return ListTile(
                leading: CircleAvatar(
                  radius: 8,
                  backgroundColor: _corStatus(s),
                ),
                title: Text(
                  s,
                  style: TextStyle(
                    color: isAtual ? const Color(0xFFDEFF9A) : Colors.white,
                    fontWeight: isAtual ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isAtual
                    ? const Icon(Icons.check, color: Color(0xFFDEFF9A), size: 18)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (!isAtual) _atualizarStatus(s);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.denuncia;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF242424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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

            // Categoria + gravidade
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.categoria,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _GravidadeBadge(gravidade: d.gravidade),
              ],
            ),
            const SizedBox(height: 12),

            // Status
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _corStatus(_statusAtual),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusAtual,
                  style: TextStyle(
                    color: _corStatus(_statusAtual),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (d.timestamp != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    _formatarData(d.timestamp!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Foto (se houver)
            if (d.fotoUrl != null && d.fotoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  d.fotoUrl!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: const Color(0xFF2E2E2E),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: const Color(0xFF2E2E2E),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFDEFF9A),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Descrição
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                d.descricao.isNotEmpty ? d.descricao : 'Sem descrição.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Coordenadas
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF9E9E9E),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${d.latitude.toStringAsFixed(5)}, ${d.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botão atualizar status (apenas logados)
            if (widget.isLoggedIn)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _mostrarOpcaoStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2E2E),
                    foregroundColor: const Color(0xFFDEFF9A),
                    disabledBackgroundColor: const Color(0xFF242424),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                        color: Color(0xFFDEFF9A),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                  ),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDEFF9A),
                          ),
                        )
                      : const Icon(Icons.update_rounded, size: 20),
                  label: Text(
                    _isUpdating ? 'Atualizando…' : 'ATUALIZAR STATUS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  'Faça login para atualizar o status',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'resolvido':
        return const Color(0xFF4CAF50);
      case 'em andamento':
        return const Color(0xFFFFC107);
      case 'pendente':
      default:
        return const Color(0xFFF44336);
    }
  }

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _GravidadeBadge extends StatelessWidget {
  final String gravidade;

  const _GravidadeBadge({required this.gravidade});

  @override
  Widget build(BuildContext context) {
    Color cor;
    IconData icone;
    switch (gravidade.toLowerCase()) {
      case 'alta':
        cor = const Color(0xFFF44336);
        icone = Icons.keyboard_double_arrow_up_rounded;
        break;
      case 'média':
        cor = const Color(0xFFFFC107);
        icone = Icons.remove_rounded;
        break;
      case 'baixa':
      default:
        cor = const Color(0xFF4CAF50);
        icone = Icons.keyboard_double_arrow_down_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 14),
          const SizedBox(width: 4),
          Text(
            gravidade,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
