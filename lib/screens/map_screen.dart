import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/report_modal.dart';
import '../widgets/report_detail_sheet.dart';
import 'login_screen.dart';

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

  // Throttle para onPositionChanged
  Timer? _positionThrottle;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToDenuncias();
  }

  @override
  void dispose() {
    _denunciasSub?.cancel();
    _positionThrottle?.cancel();
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
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _limparFiltros() => setState(() { _filtroCategoria = null; _filtroGravidade = null; _filtroStatus = null; });

  bool get _temFiltroAtivo => _filtroCategoria != null || _filtroGravidade != null || _filtroStatus != null;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final denuncias = _denunciasFiltradas;
    final loggedIn = _authService.isLoggedIn;
    final tc = ThemeController.of(context);
    final isDark = tc.isDark;

    // Theme-adaptive colors
    final accent = isDark ? const Color(0xFFDEFF9A) : const Color(0xFF4A7C1F);
    final surface = isDark ? const Color(0xE6242424) : const Color(0xE6FFFFFF);
    final onSurface = isDark ? Colors.white : const Color(0xFF212121);
    final onSurfaceMuted = isDark ? Colors.white70 : const Color(0xFF616161);
    final chipBg = isDark ? const Color(0xE6242424) : const Color(0xE6FFFFFF);
    final chipBorder = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    final mapBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8);

    return Scaffold(
      body: Stack(children: [
        // Mapa — otimizado para performance móvel
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultPosition,
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 17,
            backgroundColor: mapBg,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (pos, _) {
              // Throttle: atualiza o center no máximo a cada 150ms
              if (pos.center != null) {
                _positionThrottle?.cancel();
                _positionThrottle = Timer(const Duration(milliseconds: 150), () {
                  _currentMapCenter = pos.center!;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.ifsp.zeladoria_digital',
              maxZoom: 17,
              keepBuffer: 3,
              tileSize: 256,
              // Usar nativeZoom para evitar upscaling pesado
              maxNativeZoom: 17,
            ),
            MarkerLayer(markers: [
              if (_locationLoaded)
                Marker(
                  point: _currentPosition, width: 24, height: 24,
                  child: RepaintBoundary(
                    child: Container(decoration: BoxDecoration(color: accent.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  ),
                ),
              for (final d in denuncias)
                Marker(
                  point: LatLng(d.latitude, d.longitude), width: 40, height: 40,
                  child: RepaintBoundary(
                    child: GestureDetector(onTap: () => _abrirDetalhe(d), child: _buildMarker(d)),
                  ),
                ),
            ]),
          ],
        ),

        // Mira central
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_pin, color: accent, size: 40),
          const SizedBox(height: 40),
        ])),

        // Header + Filtros (sem gap)
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(children: [
                    Expanded(child: _buildAppTitleBar(denuncias.length, accent, surface, onSurface)),
                    const SizedBox(width: 8),
                    _buildThemeToggle(isDark, tc, surface, accent),
                    const SizedBox(width: 8),
                    _buildAuthButton(loggedIn, accent, surface, onSurface),
                  ]),
                ),
                _buildFilterBar(accent, chipBg, chipBorder, onSurface, onSurfaceMuted, isDark),
              ],
            ),
          ),
        ),

        // Loading GPS
        if (!_locationLoaded)
          Positioned(top: 130, left: 0, right: 0, child: _buildLocationLoading(accent, surface, onSurfaceMuted)),

        // Legenda + minha localização
        Positioned(
          bottom: 110, left: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildLegend(isDark, onSurfaceMuted),
            const SizedBox(height: 8),
            if (_locationLoaded) _buildMyLocationButton(accent, surface),
          ]),
        ),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalDenuncia,
        icon: Icon(Icons.add, color: isDark ? const Color(0xFF1A1A1A) : Colors.white),
        label: Text('REPORTAR', style: TextStyle(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: accent,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildThemeToggle(bool isDark, ThemeController tc, Color surface, Color accent) {
    return GestureDetector(
      onTap: tc.toggleTheme,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: accent,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildAppTitleBar(int count, Color accent, Color surface, Color onSurface) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Icon(Icons.location_city_rounded, color: accent, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text('JacaMap', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildAuthButton(bool loggedIn, Color accent, Color surface, Color onSurface) {
    if (!loggedIn) {
      // Botão de login estilizado
      return GestureDetector(
        onTap: _irParaLogin,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login_rounded, color: _contrastOn(accent), size: 20),
              const SizedBox(width: 6),
              Text('Entrar', style: TextStyle(color: _contrastOn(accent), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // Avatar do usuário logado
    final email = _authService.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () => _mostrarMenuUsuario(email, accent),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Text(initial, style: TextStyle(color: _contrastOn(accent), fontWeight: FontWeight.bold, fontSize: 20)),
        ),
      ),
    );
  }

  /// Returns white or dark text depending on accent luminance
  Color _contrastOn(Color bg) =>
      bg.computeLuminance() > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;

  void _mostrarMenuUsuario(String email, Color accent) {
    final isDark = ThemeController.of(context).isDark;
    final sheetBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white70 : const Color(0xFF616161);
    final btnBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFFAFAFA);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar grande
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : 'U',
                  style: TextStyle(color: _contrastOn(accent), fontWeight: FontWeight.bold, fontSize: 26),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(email, style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _authService.signOut();
                  setState(() {});
                  _showSnack('Sessão encerrada.');
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnBg,
                  foregroundColor: const Color(0xFFEF5350),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildFilterBar(Color accent, Color chipBg, Color chipBorder, Color onSurface, Color onSurfaceMuted, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: [
        _FilterChip(label: _filtroCategoria ?? 'Categoria', isActive: _filtroCategoria != null, options: FirestoreService.categorias, selected: _filtroCategoria, onSelected: (v) => setState(() => _filtroCategoria = v), onClear: () => setState(() => _filtroCategoria = null), accent: accent, chipBg: chipBg, chipBorder: chipBorder, onSurface: onSurface, onSurfaceMuted: onSurfaceMuted, isDark: isDark),
        const SizedBox(width: 8),
        _FilterChip(label: _filtroGravidade ?? 'Gravidade', isActive: _filtroGravidade != null, options: FirestoreService.gravidades, selected: _filtroGravidade, onSelected: (v) => setState(() => _filtroGravidade = v), onClear: () => setState(() => _filtroGravidade = null), accent: accent, chipBg: chipBg, chipBorder: chipBorder, onSurface: onSurface, onSurfaceMuted: onSurfaceMuted, isDark: isDark),
        const SizedBox(width: 8),
        _FilterChip(label: _filtroStatus ?? 'Status', isActive: _filtroStatus != null, options: FirestoreService.statusList, selected: _filtroStatus, onSelected: (v) => setState(() => _filtroStatus = v), onClear: () => setState(() => _filtroStatus = null), accent: accent, chipBg: chipBg, chipBorder: chipBorder, onSurface: onSurface, onSurfaceMuted: onSurfaceMuted, isDark: isDark),
        if (_temFiltroAtivo) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _limparFiltros,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withOpacity(0.5))),
              child: Row(children: [Icon(Icons.clear_all, color: accent, size: 16), const SizedBox(width: 4), Text('Limpar', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold))]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildLocationLoading(Color accent, Color surface, Color textColor) {
    return Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
        const SizedBox(width: 8),
        Text('Obtendo localização...', style: TextStyle(color: textColor, fontSize: 13)),
      ]),
    ));
  }

  Widget _buildMyLocationButton(Color accent, Color surface) {
    return GestureDetector(
      onTap: () => _mapController.move(_currentPosition, 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Icon(Icons.my_location_rounded, color: accent, size: 20),
      ),
    );
  }

  Widget _buildLegend(bool isDark, Color textColor) {
    final bg = isDark ? const Color(0xCC1A1A1A) : const Color(0xCCFFFFFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _LegendItem(color: const Color(0xFFF44336), label: 'Pendente', textColor: textColor),
        const SizedBox(height: 4),
        _LegendItem(color: const Color(0xFFFFC107), label: 'Em andamento', textColor: textColor),
        const SizedBox(height: 4),
        _LegendItem(color: const Color(0xFF4CAF50), label: 'Resolvido', textColor: textColor),
      ]),
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  const _LegendItem({required this.color, required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: textColor, fontSize: 11)),
    ]);
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onClear;
  final Color accent;
  final Color chipBg;
  final Color chipBorder;
  final Color onSurface;
  final Color onSurfaceMuted;
  final bool isDark;

  const _FilterChip({
    required this.label, required this.isActive, required this.options,
    required this.selected, required this.onSelected, required this.onClear,
    required this.accent, required this.chipBg, required this.chipBorder,
    required this.onSurface, required this.onSurfaceMuted, required this.isDark,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  final GlobalKey _chipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _chipKey,
      onTap: () async {
        // Calculate position directly below the chip
        final RenderBox renderBox = _chipKey.currentContext!.findRenderObject() as RenderBox;
        final Offset offset = renderBox.localToGlobal(Offset.zero);
        final Size size = renderBox.size;

        final menuBg = widget.isDark ? const Color(0xFF2E2E2E) : Colors.white;

        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy + size.height + 4,
            offset.dx + size.width,
            0,
          ),
          color: menuBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: widget.options.map((o) => PopupMenuItem<String>(
            value: o,
            child: Text(o, style: TextStyle(
              color: widget.selected == o ? widget.accent : widget.onSurface,
              fontWeight: widget.selected == o ? FontWeight.bold : FontWeight.normal,
            )),
          )).toList(),
        );
        if (result != null) widget.onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isActive ? widget.accent.withOpacity(0.15) : widget.chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.isActive ? widget.accent : widget.chipBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.label, style: TextStyle(
            color: widget.isActive ? widget.accent : widget.onSurfaceMuted,
            fontSize: 12,
            fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
          )),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down,
            color: widget.isActive ? widget.accent : widget.onSurfaceMuted.withOpacity(0.5),
            size: 18,
          ),
        ]),
      ),
    );
  }
}
