import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore_service.dart';
import '../widgets/report_modal.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controller do mapa
  final Completer<GoogleMapController> _mapController = Completer();

  // Posição inicial padrão (Jacareí, SP)
  static const LatLng _defaultPosition = LatLng(-23.3055, -45.9659);

  // [AJUSTE 2] Posição do centro visível do mapa (atualizada pelo onCameraMove).
  // É esta coordenada — não o GPS — que será usada ao reportar.
  LatLng _currentMapCenter = _defaultPosition;

  // Posição GPS do usuário (usada apenas para o botão "minha localização")
  bool _locationLoaded = false;

  // Conjunto de marcadores renderizados no mapa
  final Set<Marker> _markers = {};

  // Serviço Firestore
  final FirestoreService _firestoreService = FirestoreService();

  // Subscription do stream de denúncias
  StreamSubscription<List<Denuncia>>? _denunciasSubscription;

  // [AJUSTE 3] Controller da barra de pesquisa
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
        _showSnack('Permissão negada permanentemente. Ative nas configurações.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

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
      _updateMarkers(denuncias);
    }, onError: (e) {
      _showSnack('Erro ao carregar denúncias: $e');
    });
  }

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
    }

    return BitmapDescriptor.hueViolet;        // Outros → Roxo
  }

  // ── Modal de denúncia ─────────────────────────────────────────────────────

  void _abrirModalDenuncia() {
    // [AJUSTE 2] Passa a posição CENTRAL do mapa (pin), não o GPS
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportModal(
        // O usuário pode ter navegado pelo mapa; usamos onde a câmera está
        currentPosition: _currentMapCenter,
        firestoreService: _firestoreService,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
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
          Positioned(
            bottom: 110,
            left: 16,
            child: _buildLegend(),
          ),
        ],
      ),

      // ── Botão REPORTAR (usa posição da mira) ──────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalDenuncia,
        icon: const Icon(Icons.add, color: Color(0xFF1A1A1A)),
        label: const Text(
          'REPORTAR',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFFDEFF9A),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

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
      ),
    );
  }

  // ── Legenda de categorias ─────────────────────────────────────────────────

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
          _LegendItem(color: Colors.red,    label: 'Buraco na Via'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.amber,  label: 'Iluminação Pública'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.orange, label: 'Acúmulo de Lixo'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.blue,   label: 'Enchente/Drenagem'),
        ],
      ),
    );
  }
}

// ── Widget auxiliar de legenda ────────────────────────────────────────────────

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
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

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
