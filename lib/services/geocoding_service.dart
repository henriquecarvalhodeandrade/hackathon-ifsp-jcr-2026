import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serviço de geocodificação reversa usando Nominatim (OpenStreetMap).
/// Gratuito, sem necessidade de API key.
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Resolve coordenadas para um endereço legível.
  /// Retorna string formatada ou null se falhar.
  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&format=json&addressdetails=1&accept-language=pt-BR',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'JacaMap/1.0 (zeladoria_digital)',
      });

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      if (address == null) {
        return data['display_name'] as String?;
      }

      // Monta endereço resumido e legível
      final parts = <String>[];

      final road = address['road'] ?? address['pedestrian'] ?? address['footway'];
      if (road != null) parts.add(road as String);

      final houseNumber = address['house_number'];
      if (houseNumber != null && parts.isNotEmpty) {
        parts[parts.length - 1] = '${parts.last}, $houseNumber';
      }

      final neighbourhood = address['neighbourhood'] ?? address['suburb'];
      if (neighbourhood != null) parts.add(neighbourhood as String);

      final city = address['city'] ?? address['town'] ?? address['village'];
      if (city != null) parts.add(city as String);

      if (parts.isEmpty) {
        return data['display_name'] as String?;
      }

      return parts.join(' – ');
    } catch (e) {
      debugPrint('GeocodingService error: $e');
      return null;
    }
  }
}
