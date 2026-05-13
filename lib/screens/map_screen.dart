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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultPosition = LatLng(-23.3055, -45.9659);

  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  LatLng _currentPosition = _defaultPosition;
  LatLng _currentMapCenter = _defaultPosition;
  bool _locationLoaded = false;

  List<Denuncia> _todasDenuncias = [];
  StreamSubscription<List<Denuncia>>? _denunciasSubscription;

  // Filtros
  String? _filtroCategoria;
  String? _filtroGravidade;
  String? _filtroStatus;

  // Busca
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToDenuncias();
  }

  @override
  void dispose() {
    _denunciasSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Localização GPS ───────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Serviço de localização desativado.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Permissão de localização negada.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('Ative a localização nas configurações do dispositivo.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = latLng;
          _currentMapCenter = latLng;
          _locationLoaded = true;
        });
        _mapController.move(latLng, 15);
      }
    } catch (e) {
      _showSnack('Erro ao obter localização: $e');
    }
  }

  // ── Busca de endereço ──────────────────────────────────────────

  Future<void> _buscarEndereco(String endereco) async {
    if (endereco.trim().isEmpty) return;

    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus();

    try {
      // Placeholder para busca de endereços
      _showSnack('Adicione o pacote "geocoding" para busca real de endereços.');
    } catch (e) {
      _showSnack('Endereço não encontrado: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── Stream de denúncias ───────────────────────────────────────────────────

  void _listenToDenuncias() {
    _denunciasSubscription =
        _firestoreService.streamDenuncias().listen((denuncias) {
      if (mounted) setState(() => _todasDenuncias = denuncias);
    }, onError: (e) {
      _showSnack('Erro ao carregar denúncias: $e');
    });
  }

  List<Denuncia> get _denunciasFiltradas {
    return _todasDenuncias.where((d) {
      if (_filtroCategoria != null && d.categoria != _filtroCategoria) {
        return false;
      }
      if (_filtroGravidade != null && d.gravidade != _filtroGravidade) {
        return false;
      }
      if (_filtroStatus != null && d.status != _filtroStatus) return false;
      return true;
    }).toList();
  }

  // ── Cores por status e gravidade ─────────────────────────────────────────

  Color _corParaStatus(String status) {
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

  IconData _iconeParaCategoria(String categoria) {
    switch (categoria) {
      case 'Buraco na Via':
        return Icons.warning_rounded;
      case 'Iluminação Pública':
        return Icons.lightbulb_outline;
      case 'Acúmulo de Lixo':
        return Icons.delete_outline;
      case 'Enchente/Drenagem':
        return Icons.water_damage_outlined;
      case 'Calçada Danificada':
        return Icons.construction_outlined;
      case 'Sinalização':
        return Icons.traffic_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  // ── Navegação ────────────────────────────────────────────────────────────

  void _abrirModalDenuncia() {
    if (!_authService.isLoggedIn) {
      _showSnack('Faça login para registrar uma denúncia.');
      _irParaLogin();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ReportModal(
            currentPosition: _currentMapCenter, // Usa a posição da MIRA
            firestoreService: _firestoreService,
            userId: _authService.currentUser?.uid,
          ),
    );
  }

  void _abrirDetalhe(Denuncia d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ReportDetailSheet(
            denuncia: d,
            firestoreService: _firestoreService,
            isLoggedIn: _authService.isLoggedIn,
          ),
    );
  }

  Future<void> _irParaLogin() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Login',
      barrierColor: Colors.black.withOpacity(0.5), // Escurece o mapa
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const LoginScreen(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * anim1.value,
            sigmaY: 5 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
    setState(() {});
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2E2E2E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _limparFiltros() {
    setState(() {
      _filtroCategoria = null;
      _filtroGravidade = null;
      _filtroStatus = null;
    });
  }

  bool get _temFiltroAtivo =>
      _filtroCategoria != null ||
      _filtroGravidade != null ||
      _filtroStatus != null;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final denuncias = _denunciasFiltradas;
    final isLoggedIn = _authService.isLoggedIn;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa OpenStreetMap ────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultPosition,
              initialZoom: 14,
              backgroundColor: const Color(0xFF1A1A1A),
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentMapCenter = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ifsp.zeladoria_digital',
                tileBuilder: _darkTileBuilder,
              ),
              MarkerLayer(
                markers: [
                  // Marcador de posição atual (GPS)
                  if (_locationLoaded)
                    Marker(
                      point: _currentPosition,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEFF9A).withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),

                  // Marcadores de denúncias
                  for (final d in denuncias)
                    Marker(
                      point: LatLng(d.latitude, d.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _abrirDetalhe(d),
                        child: _buildMarker(d),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Mira central (pin fixo no centro) ──────────────────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: Color(0xFFDEFF9A), size: 40),
                SizedBox(height: 40), // Ajuste para a ponta do pin ficar no centro
              ],
            ),
          ),

          // ── Header + Busca ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildAppTitleBar(denuncias.length)),
                        const SizedBox(width: 8),
                        _buildAuthButton(isLoggedIn),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
          ),

          // ── Barra de filtros ──────────────────────────────────────────────
          Positioned(
            top: 140, // Ajustado para ficar abaixo da busca
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildFilterBar(),
            ),
          ),

          // ── Indicador de carregamento de localização ──────────────────────
          if (!_locationLoaded)
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: _buildLocationLoadingIndicator(),
            ),

          // ── Legenda + botão de minha localização ─────────────────────────
          Positioned(
            bottom: 110,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(),
                const SizedBox(height: 8),
                if (_locationLoaded) _buildMyLocationButton(),
              ],
            ),
          ),
        ],
      ),

      // ── FAB de reportar ───────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalDenuncia,
        icon: Icon(
          Icons.add,
          color: isLoggedIn ? const Color(0xFF1A1A1A) : Colors.black54,
        ),
        label: Text(
          'REPORTAR',
          style: TextStyle(
            color: isLoggedIn ? const Color(0xFF1A1A1A) : Colors.black54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: isLoggedIn
            ? const Color(0xFFDEFF9A)
            : const Color(0xFF9EAF6A),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Widgets da UI ────────────────────────────────────────────────────────

  Widget _buildAppTitleBar(int count) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xE6242424),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_city_rounded, color: Color(0xFFDEFF9A), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Zeladoria Digital',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_todasDenuncias.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count/${_todasDenuncias.length}',
                style: const TextStyle(color: Color(0xFFDEFF9A), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthButton(bool isLoggedIn) {
    return GestureDetector(
      onTap: isLoggedIn
          ? () async {
              await _authService.signOut();
              setState(() {});
              _showSnack('Sessão encerrada.');
            }
          : _irParaLogin,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xE6242424),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(
          isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
          color: isLoggedIn ? const Color(0xFFDEFF9A) : Colors.white54,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xE6242424),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onSubmitted: _buscarEndereco,
        decoration: InputDecoration(
          hintText: 'Pesquisar endereço...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDEFF9A)),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMarker(Denuncia d) {
    final color = _corParaStatus(d.status);
    final icone = _iconeParaCategoria(d.categoria);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Icon(icone, color: Colors.white, size: 20),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: _filtroCategoria ?? 'Categoria',
            isActive: _filtroCategoria != null,
            options: FirestoreService.categorias,
            selected: _filtroCategoria,
            onSelected: (v) => setState(() => _filtroCategoria = v),
            onClear: () => setState(() => _filtroCategoria = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _filtroGravidade ?? 'Gravidade',
            isActive: _filtroGravidade != null,
            options: FirestoreService.gravidades,
            selected: _filtroGravidade,
            onSelected: (v) => setState(() => _filtroGravidade = v),
            onClear: () => setState(() => _filtroGravidade = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _filtroStatus ?? 'Status',
            isActive: _filtroStatus != null,
            options: FirestoreService.statusList,
            selected: _filtroStatus,
            onSelected: (v) => setState(() => _filtroStatus = v),
            onClear: () => setState(() => _filtroStatus = null),
          ),
          if (_temFiltroAtivo) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _limparFiltros,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF9A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDEFF9A).withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.clear_all, color: Color(0xFFDEFF9A), size: 16),
                    SizedBox(width: 4),
                    Text('Limpar', style: TextStyle(color: Color(0xFFDEFF9A), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE6242424),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDEFF9A))),
            SizedBox(width: 8),
            Text('Obtendo localização...', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: () {
        _mapController.move(_currentPosition, 16);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xE6242424),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.my_location_rounded, color: Color(0xFFDEFF9A), size: 20),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(color: Color(0xFFF44336), label: 'Pendente'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFFFFC107), label: 'Em andamento'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFF4CAF50), label: 'Resolvido'),
        ],
      ),
    );
  }
}

// ── Dark tile builder ──────────────────

Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      -0.2126, -0.7152, -0.0722, 0, 255,
      -0.2126, -0.7152, -0.0722, 0, 255,
      -0.2126, -0.7152, -0.0722, 0, 255,
      0,        0,        0,       1, 0,
    ]),
    child: tileWidget,
  );
}

// ── Legend Item ──────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ── Chip de filtro ──────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onClear;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(100, 200, 100, 0),
          color: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: options
              .map((o) => PopupMenuItem<String>(
                    value: o,
                    child: Text(
                      o,
                      style: TextStyle(
                        color: selected == o ? const Color(0xFFDEFF9A) : Colors.white,
                        fontWeight: selected == o ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ))
              .toList(),
        );
        if (result != null) onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDEFF9A).withOpacity(0.15) : const Color(0xE6242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFFDEFF9A) : Colors.white.withOpacity(0.15)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isActive ? const Color(0xFFDEFF9A) : Colors.white70, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: isActive ? const Color(0xFFDEFF9A) : Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
