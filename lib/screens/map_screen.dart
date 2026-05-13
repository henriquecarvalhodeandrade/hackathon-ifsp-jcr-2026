import 'dart:async';
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
<<<<<<< HEAD
  // Controller do mapa
  final Completer<GoogleMapController> _mapController = Completer();

  // Posição inicial padrão (Jacareí, SP)
  static const LatLng _defaultPosition = LatLng(-23.3055, -45.9659);

  // [AJUSTE 2] Posição do centro visível do mapa (atualizada pelo onCameraMove).
  // É esta coordenada — não o GPS — que será usada ao reportar.
  LatLng _currentMapCenter = _defaultPosition;

  // Posição GPS do usuário (usada apenas para o botão "minha localização")
=======
  static const LatLng _defaultPosition = LatLng(-23.3055, -45.9659);

  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  LatLng _currentPosition = _defaultPosition;
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
  bool _locationLoaded = false;

  List<Denuncia> _todasDenuncias = [];
  StreamSubscription<List<Denuncia>>? _denunciasSubscription;

<<<<<<< HEAD
  // [AJUSTE 3] Controller da barra de pesquisa
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
=======
  // Filtros
  String? _filtroCategoria;
  String? _filtroGravidade;
  String? _filtroStatus;
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732

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
<<<<<<< HEAD
        _showSnack('Permissão negada permanentemente. Ative nas configurações.');
=======
        _showSnack('Ative a localização nas configurações do dispositivo.');
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
<<<<<<< HEAD

      setState(() {
        _currentMapCenter = latLng;
        _locationLoaded = true;
      });

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15),
        ),
      );
=======
      if (mounted) {
        setState(() {
          _currentPosition = latLng;
          _locationLoaded = true;
        });
        _mapController.move(latLng, 15);
      }
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
    } catch (e) {
      _showSnack('Erro ao obter localização: $e');
    }
  }

  // ── [AJUSTE 3] Busca de endereço ──────────────────────────────────────────

  Future<void> _buscarEndereco(String endereco) async {
    if (endereco.trim().isEmpty) return;

    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus();

    try {
      /*
       * GEOCODING — Para ativar a busca real de endereços:
       * 1. Adicione ao pubspec.yaml:  geocoding: ^3.0.0
       * 2. Descomente o bloco abaixo e remova o _showSnack de placeholder.
       *
       * import 'package:geocoding/geocoding.dart';
       *
       * final locations = await locationFromAddress(endereco);
       * if (locations.isNotEmpty) {
       *   final loc = locations.first;
       *   final latLng = LatLng(loc.latitude, loc.longitude);
       *   final controller = await _mapController.future;
       *   controller.animateCamera(
       *     CameraUpdate.newCameraPosition(
       *       CameraPosition(target: latLng, zoom: 16),
       *     ),
       *   );
       * }
       */

      // Placeholder para o Hackathon — substitua pelo bloco acima quando tiver
      // a dependência de geocoding instalada.
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

<<<<<<< HEAD
  void _updateMarkers(List<Denuncia> denuncias) {
    final Set<Marker> novosMarkers = {};

    for (final d in denuncias) {
      // [AJUSTE 4] Cor do marcador baseada na CATEGORIA (não no status)
      final hue = _hueParaCategoria(d.categoria);

      novosMarkers.add(
        Marker(
          markerId: MarkerId(d.id),
          position: LatLng(d.latitude, d.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: d.categoria,
            snippet: '${d.status} • ${d.descricao}',
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(novosMarkers);
    });
  }

  // [AJUSTE 4] Mapeamento categoria → cor do marcador
  double _hueParaCategoria(String categoria) {
    final cat = categoria.toLowerCase();

    if (cat.contains('buraco')) {
      return BitmapDescriptor.hueRed;         // Buraco na Via → Vermelho
    } else if (cat.contains('ilumina')) {
      return BitmapDescriptor.hueYellow;      // Iluminação Pública → Amarelo
    } else if (cat.contains('lixo')) {
      return BitmapDescriptor.hueOrange;      // Acúmulo de Lixo → Laranja
    } else if (cat.contains('enchente') || cat.contains('drenagem')) {
      return BitmapDescriptor.hueAzure;       // Enchente/Drenagem → Azul
=======
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
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
    }

    return BitmapDescriptor.hueViolet;        // Outros → Roxo
  }

<<<<<<< HEAD
  // ── Modal de denúncia ─────────────────────────────────────────────────────

  void _abrirModalDenuncia() {
    // [AJUSTE 2] Passa a posição CENTRAL do mapa (pin), não o GPS
=======
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
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
<<<<<<< HEAD
      builder: (_) => ReportModal(
        // O usuário pode ter navegado pelo mapa; usamos onde a câmera está
        currentPosition: _currentMapCenter,
        firestoreService: _firestoreService,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
=======
      builder:
          (_) => ReportModal(
            currentPosition: _currentPosition,
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    setState(() {});
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732

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

<<<<<<< HEAD
  // ── Build ─────────────────────────────────────────────────────────────────
=======
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
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732

  @override
  Widget build(BuildContext context) {
    final denuncias = _denunciasFiltradas;
    final isLoggedIn = _authService.isLoggedIn;

    return Scaffold(
      body: Stack(
        children: [
<<<<<<< HEAD
          // ── Mapa em tela cheia ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultPosition,
              zoom: 14,
            ),
            myLocationEnabled: _locationLoaded,
            myLocationButtonEnabled: false, // usamos botão customizado
            markers: _markers,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController.complete(controller);
              controller.setMapStyle(_darkMapStyle);
            },
            // [AJUSTE 2] Atualiza o centro do mapa sempre que a câmera mover
            onCameraMove: (CameraPosition position) {
              _currentMapCenter = position.target;
            },
          ),

          // ── [AJUSTE 2] Mira central (pin fixo no centro) ───────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: Color(0xFFDEFF9A), size: 40),
                // Desloca 20px para cima para que a ponta da mira fique
                // exatamente no centro da tela
                SizedBox(height: 20),
              ],
            ),
          ),

          // ── [AJUSTE 3] Barra de pesquisa no topo ──────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // ── Indicador de localização carregando ────────────────────────
          if (!_locationLoaded)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
=======
          // ── Mapa OpenStreetMap ────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultPosition,
              initialZoom: 14,
              backgroundColor: const Color(0xFF1A1A1A),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ifsp.zeladoria_digital',
                tileBuilder: _darkTileBuilder,
              ),
              MarkerLayer(
                markers: [
                  // Marcador de posição atual
                  if (_locationLoaded)
                    Marker(
                      point: _currentPosition,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEFF9A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
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

          // ── AppBar flutuante ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xE6242424),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_city_rounded,
                              color: Color(0xFFDEFF9A),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Zeladoria Digital',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_todasDenuncias.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E2E2E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${denuncias.length}/${_todasDenuncias.length}',
                                  style: const TextStyle(
                                    color: Color(0xFFDEFF9A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão de autenticação
                    GestureDetector(
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
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isLoggedIn
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                          color: isLoggedIn
                              ? const Color(0xFFDEFF9A)
                              : Colors.white54,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Barra de filtros ──────────────────────────────────────────────
          Positioned(
            top: 72,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildFilterBar(),
            ),
          ),

          // ── Indicador de carregamento de localização ──────────────────────
          if (!_locationLoaded)
            Positioned(
              top: 130,
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
              left: 0,
              right: 0,
              child: Center(
                child: Container(
<<<<<<< HEAD
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
=======
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
                  decoration: BoxDecoration(
                    color: const Color(0xE6242424),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFDEFF9A),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Obtendo localização…',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

<<<<<<< HEAD
          // ── Botão "Minha localização" customizado ──────────────────────
          if (_locationLoaded)
            Positioned(
              right: 12,
              bottom: 120,
              child: FloatingActionButton.small(
                heroTag: 'btn_minha_loc',
                onPressed: _initLocation,
                backgroundColor: const Color(0xFF242424),
                child: const Icon(Icons.my_location, color: Color(0xFFDEFF9A)),
              ),
            ),

          // ── Legenda de categorias ──────────────────────────────────────
=======
          // ── Legenda + botão de minha localização ─────────────────────────
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
          Positioned(
            bottom: 110,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(),
                const SizedBox(height: 8),
                if (_locationLoaded)
                  GestureDetector(
                    onTap: () => _mapController.move(_currentPosition, 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xE6242424),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFFDEFF9A),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

<<<<<<< HEAD
      // ── Botão REPORTAR (usa posição da mira) ──────────────────────────
=======
      // ── FAB de reportar ───────────────────────────────────────────────────
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
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

<<<<<<< HEAD
  // ── [AJUSTE 3] Widget da barra de pesquisa ────────────────────────────────

  Widget _buildSearchBar() {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textInputAction: TextInputAction.search,
          onSubmitted: _buscarEndereco,
          decoration: InputDecoration(
            hintText: 'Pesquisar endereço…',
            hintStyle: const TextStyle(color: Color(0xFF616161), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDEFF9A),
                      ),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF9E9E9E), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFDEFF9A), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
=======
  // ── Widgets auxiliares ───────────────────────────────────────────────────

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
          // Filtro categoria
          _FilterChip(
            label: _filtroCategoria ?? 'Categoria',
            isActive: _filtroCategoria != null,
            options: FirestoreService.categorias,
            selected: _filtroCategoria,
            onSelected: (v) => setState(() => _filtroCategoria = v),
            onClear: () => setState(() => _filtroCategoria = null),
          ),
          const SizedBox(width: 8),
          // Filtro gravidade
          _FilterChip(
            label: _filtroGravidade ?? 'Gravidade',
            isActive: _filtroGravidade != null,
            options: FirestoreService.gravidades,
            selected: _filtroGravidade,
            onSelected: (v) => setState(() => _filtroGravidade = v),
            onClear: () => setState(() => _filtroGravidade = null),
          ),
          const SizedBox(width: 8),
          // Filtro status
          _FilterChip(
            label: _filtroStatus ?? 'Status',
            isActive: _filtroStatus != null,
            options: FirestoreService.statusList,
            selected: _filtroStatus,
            onSelected: (v) => setState(() => _filtroStatus = v),
            onClear: () => setState(() => _filtroStatus = null),
          ),
          // Botão limpar todos os filtros
          if (_temFiltroAtivo) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _limparFiltros,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEFF9A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDEFF9A).withOpacity(0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all, color: Color(0xFFDEFF9A), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Limpar',
                      style: TextStyle(
                        color: Color(0xFFDEFF9A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
      ),
    );
  }

<<<<<<< HEAD
  // ── Legenda de categorias ─────────────────────────────────────────────────

=======
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
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
<<<<<<< HEAD
          _LegendItem(color: Colors.red,    label: 'Buraco na Via'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.amber,  label: 'Iluminação Pública'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.orange, label: 'Acúmulo de Lixo'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.blue,   label: 'Enchente/Drenagem'),
=======
          _LegendItem(color: Color(0xFFF44336), label: 'Pendente'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFFFFC107), label: 'Em andamento'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFF4CAF50), label: 'Resolvido'),
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
        ],
      ),
    );
  }
}

<<<<<<< HEAD
// ── Widget auxiliar de legenda ────────────────────────────────────────────────
=======
// ── Dark tile builder (aplica tint escuro sobre o mapa OSM) ──────────────────

Widget _darkTileBuilder(
  BuildContext context,
  Widget tileWidget,
  TileImage tile,
) {
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

// ── Legenda ───────────────────────────────────────────────────────────────────
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732

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
<<<<<<< HEAD
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
=======
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
      ],
    );
  }
}

<<<<<<< HEAD
// ── Estilo Dark para o Google Maps ───────────────────────────────────────────
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
=======
// ── Chip de filtro ────────────────────────────────────────────────────────────

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
          position: RelativeRect.fromLTRB(
            MediaQuery.of(context).size.width / 2,
            130,
            0,
            0,
          ),
          color: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          items: options
              .map(
                (o) => PopupMenuItem<String>(
                  value: o,
                  child: Text(
                    o,
                    style: TextStyle(
                      color: selected == o
                          ? const Color(0xFFDEFF9A)
                          : Colors.white,
                      fontWeight: selected == o
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              )
              .toList(),
        );
        if (result != null) onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFDEFF9A).withOpacity(0.15)
              : const Color(0xE6242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFFDEFF9A)
                : Colors.white.withOpacity(0.15),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFDEFF9A) : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.arrow_drop_down : Icons.arrow_drop_down,
              color: isActive ? const Color(0xFFDEFF9A) : Colors.white38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
>>>>>>> 2d99e4a9773148b5216b6cb290d3065820ae5732
