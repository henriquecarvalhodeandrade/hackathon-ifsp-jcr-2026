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

  // Posição inicial padrão (Jacareí, SP) — substituída pela localização real
  static const LatLng _defaultPosition = LatLng(-23.3055, -45.9659);

  LatLng _currentPosition = _defaultPosition;
  bool _locationLoaded = false;

  // Conjunto de marcadores renderizados no mapa
  final Set<Marker> _markers = {};

  // Serviço Firestore
  final FirestoreService _firestoreService = FirestoreService();

  // Subscription do stream de denúncias
  StreamSubscription<List<Denuncia>>? _denunciasSubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToDenuncias();
  }

  @override
  void dispose() {
    _denunciasSubscription?.cancel();
    super.dispose();
  }

  // ── Localização ──────────────────────────────────────────────────────────

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
        _showSnack('Permissão de localização negada permanentemente. Ative nas configurações.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _locationLoaded = true;
      });

      // Centraliza o mapa na posição atual
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

  // ── Stream de denúncias ──────────────────────────────────────────────────

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
      final hue = _hueParaStatus(d.status);
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

  /// Mapeia o status da denúncia para uma cor de marcador.
  double _hueParaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'resolvido':
        return BitmapDescriptor.hueGreen;
      case 'em andamento':
        return BitmapDescriptor.hueYellow;
      case 'pendente':
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  // ── Modal de denúncia ────────────────────────────────────────────────────

  void _abrirModalDenuncia() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportModal(
        currentPosition: _currentPosition,
        firestoreService: _firestoreService,
      ),
    );
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa em tela cheia
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultPosition,
              zoom: 14,
            ),
            myLocationEnabled: _locationLoaded,
            myLocationButtonEnabled: _locationLoaded,
            markers: _markers,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController.complete(controller);
              // Aplica estilo dark ao mapa
              controller.setMapStyle(_darkMapStyle);
            },
          ),

          // Indicador de carregamento de localização
          if (!_locationLoaded)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Legenda de cores
          Positioned(
            bottom: 110,
            left: 16,
            child: _buildLegend(),
          ),
        ],
      ),

      // Botão de reportar
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
          _LegendItem(color: Colors.red, label: 'Pendente'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.amber, label: 'Em andamento'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.green, label: 'Resolvido'),
        ],
      ),
    );
  }
}

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

// ── Estilo Dark para o Google Maps ─────────────────────────────────────────
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
