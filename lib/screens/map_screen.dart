import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/report_modal.dart';
import '../widgets/report_detail_sheet.dart';
import 'login_screen.dart';

const _accent = Color(0xFFDEFF9A);
const _surface = Color(0xE6242424);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _defaultPosition = LatLng(-23.3055, -45.9659);

  final _mapController = MapController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  LatLng _currentPosition = _defaultPosition;
  LatLng _currentMapCenter = _defaultPosition;
  bool _locationLoaded = false;

  List<Denuncia> _todasDenuncias = [];
  StreamSubscription<List<Denuncia>>? _denunciasSub;

  String? _filtroCategoria;
  String? _filtroGravidade;
  String? _filtroStatus;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToDenuncias();
  }

  @override
  void dispose() {
    _denunciasSub?.cancel();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnack('Serviço de localização desativado.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showSnack('Permissão de localização negada.');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Ative a localização nas configurações do dispositivo.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final ll = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() { _currentPosition = ll; _currentMapCenter = ll; _locationLoaded = true; });
        _mapController.move(ll, 15);
      }
    } catch (e) {
      _showSnack('Erro ao obter localização: $e');
    }
  }

  // ── Firestore stream ──────────────────────────────────────────────────────

  void _listenToDenuncias() {
    _denunciasSub = _firestoreService.streamDenuncias().listen(
      (list) { if (mounted) setState(() => _todasDenuncias = list); },
      onError: (e) => _showSnack('Erro ao carregar denúncias: $e'),
    );
  }

  List<Denuncia> get _denunciasFiltradas => _todasDenuncias.where((d) {
    if (_filtroCategoria != null && d.categoria != _filtroCategoria) return false;
    if (_filtroGravidade != null && d.gravidade != _filtroGravidade) return false;
    if (_filtroStatus != null && d.status != _filtroStatus) return false;
    return true;
  }).toList();

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _corParaStatus(String s) => switch (s.toLowerCase()) {
    'resolvido' => const Color(0xFF4CAF50),
    'em andamento' => const Color(0xFFFFC107),
    _ => const Color(0xFFF44336),
  };

  IconData _iconeParaCategoria(String c) => switch (c) {
    'Buraco na Via' => Icons.warning_rounded,
    'Iluminação Pública' => Icons.lightbulb_outline,
    'Acúmulo de Lixo' => Icons.delete_outline,
    'Enchente/Drenagem' => Icons.water_damage_outlined,
    'Calçada Danificada' => Icons.construction_outlined,
    'Sinalização' => Icons.traffic_outlined,
    _ => Icons.report_problem_outlined,
  };

  void _abrirModalDenuncia() {
    if (!_authService.isLoggedIn) {
      _showSnack('Faça login para registrar uma denúncia.');
      _irParaLogin();
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ReportModal(currentPosition: _currentMapCenter, firestoreService: _firestoreService, userId: _authService.currentUser?.uid),
    );
  }

  void _abrirDetalhe(Denuncia d) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ReportDetailSheet(denuncia: d, firestoreService: _firestoreService, isLoggedIn: _authService.isLoggedIn),
    );
  }

  Future<void> _irParaLogin() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Login',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const LoginScreen(),
      transitionBuilder: (_, anim, __, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim.value, sigmaY: 5 * anim.value),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
    setState(() {});
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF2E2E2E), behavior: SnackBarBehavior.floating),
    );
  }

  void _limparFiltros() => setState(() { _filtroCategoria = null; _filtroGravidade = null; _filtroStatus = null; });

  bool get _temFiltroAtivo => _filtroCategoria != null || _filtroGravidade != null || _filtroStatus != null;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final denuncias = _denunciasFiltradas;
    final loggedIn = _authService.isLoggedIn;

    return Scaffold(
      body: Stack(children: [
        // Mapa — usa tiles dark do CartoDB para evitar o ColorFilter pesado
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultPosition,
            initialZoom: 14,
            backgroundColor: const Color(0xFF1A1A1A),
            onPositionChanged: (pos, _) { if (pos.center != null) _currentMapCenter = pos.center!; },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.ifsp.zeladoria_digital',
              maxZoom: 19,
            ),
            MarkerLayer(markers: [
              if (_locationLoaded)
                Marker(
                  point: _currentPosition, width: 24, height: 24,
                  child: Container(decoration: BoxDecoration(color: _accent.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                ),
              for (final d in denuncias)
                Marker(
                  point: LatLng(d.latitude, d.longitude), width: 40, height: 40,
                  child: GestureDetector(onTap: () => _abrirDetalhe(d), child: _buildMarker(d)),
                ),
            ]),
          ],
        ),

        // Mira central
        const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_pin, color: _accent, size: 40),
          SizedBox(height: 40),
        ])),

        // Header
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              Expanded(child: _buildAppTitleBar(denuncias.length)),
              const SizedBox(width: 8),
              _buildAuthButton(loggedIn),
            ]),
          )),
        ),

        // Filtros
        Positioned(
          top: 100, left: 0, right: 0,
          child: SafeArea(child: _buildFilterBar()),
        ),

        // Loading GPS
        if (!_locationLoaded)
          Positioned(top: 160, left: 0, right: 0, child: _buildLocationLoading()),

        // Legenda + minha localização
        Positioned(
          bottom: 110, left: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLegend(),
            const SizedBox(height: 8),
            if (_locationLoaded) _buildMyLocationButton(),
          ]),
        ),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalDenuncia,
        icon: Icon(Icons.add, color: loggedIn ? const Color(0xFF1A1A1A) : Colors.black54),
        label: Text('REPORTAR', style: TextStyle(color: loggedIn ? const Color(0xFF1A1A1A) : Colors.black54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: loggedIn ? _accent : const Color(0xFF9EAF6A),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildAppTitleBar(int count) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))]),
      child: Row(children: [
        const Icon(Icons.location_city_rounded, color: _accent, size: 22),
        const SizedBox(width: 8),
        const Expanded(child: Text('JacaMap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
        if (_todasDenuncias.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF2E2E2E), borderRadius: BorderRadius.circular(10)),
            // child: Text('$count/${_todasDenuncias.length}', style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _buildAuthButton(bool loggedIn) {
    return GestureDetector(
      onTap: loggedIn ? () async { await _authService.signOut(); setState(() {}); _showSnack('Sessão encerrada.'); } : _irParaLogin,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))]),
        child: Icon(loggedIn ? Icons.logout_rounded : Icons.login_rounded, color: loggedIn ? _accent : Colors.white54, size: 22),
      ),
    );
  }

  Widget _buildMarker(Denuncia d) {
    final color = _corParaStatus(d.status);
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))]),
      child: Icon(_iconeParaCategoria(d.categoria), color: Colors.white, size: 20),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        _FilterChip(label: _filtroCategoria ?? 'Categoria', isActive: _filtroCategoria != null, options: FirestoreService.categorias, selected: _filtroCategoria, onSelected: (v) => setState(() => _filtroCategoria = v), onClear: () => setState(() => _filtroCategoria = null)),
        const SizedBox(width: 8),
        _FilterChip(label: _filtroGravidade ?? 'Gravidade', isActive: _filtroGravidade != null, options: FirestoreService.gravidades, selected: _filtroGravidade, onSelected: (v) => setState(() => _filtroGravidade = v), onClear: () => setState(() => _filtroGravidade = null)),
        const SizedBox(width: 8),
        _FilterChip(label: _filtroStatus ?? 'Status', isActive: _filtroStatus != null, options: FirestoreService.statusList, selected: _filtroStatus, onSelected: (v) => setState(() => _filtroStatus = v), onClear: () => setState(() => _filtroStatus = null)),
        if (_temFiltroAtivo) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _limparFiltros,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _accent.withOpacity(0.5))),
              child: const Row(children: [Icon(Icons.clear_all, color: _accent, size: 16), SizedBox(width: 4), Text('Limpar', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.bold))]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildLocationLoading() {
    return Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
        SizedBox(width: 8),
        Text('Obtendo localização...', style: TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    ));
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: () => _mapController.move(_currentPosition, 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))]),
        child: const Icon(Icons.my_location_rounded, color: _accent, size: 20),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xCC1A1A1A), borderRadius: BorderRadius.circular(12)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _LegendItem(color: Color(0xFFF44336), label: 'Pendente'),
        SizedBox(height: 4),
        _LegendItem(color: Color(0xFFFFC107), label: 'Em andamento'),
        SizedBox(height: 4),
        _LegendItem(color: Color(0xFF4CAF50), label: 'Resolvido'),
      ]),
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onClear;

  const _FilterChip({required this.label, required this.isActive, required this.options, required this.selected, required this.onSelected, required this.onClear});

  @override
  Widget build(BuildContext context) {
    const accent = _accent;
    return GestureDetector(
      onTap: () async {
        final result = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(100, 200, 100, 0),
          color: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: options.map((o) => PopupMenuItem<String>(value: o, child: Text(o, style: TextStyle(color: selected == o ? accent : Colors.white, fontWeight: selected == o ? FontWeight.bold : FontWeight.normal)))).toList(),
        );
        if (result != null) onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accent.withOpacity(0.15) : const Color(0xE6242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? accent : Colors.white.withOpacity(0.15)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(color: isActive ? accent : Colors.white70, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, color: isActive ? accent : Colors.white38, size: 18),
        ]),
      ),
    );
  }
}
