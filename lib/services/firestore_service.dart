import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados de uma denúncia.
class Denuncia {
  final String id;
  final String categoria;
  final String descricao;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime? timestamp;

  Denuncia({
    required this.id,
    required this.categoria,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.timestamp,
  });

  /// Converte um DocumentSnapshot do Firestore em [Denuncia].
  factory Denuncia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Denuncia(
      id: doc.id,
      categoria: data['categoria'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Pendente',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

/// Serviço responsável por toda interação com o Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nome da coleção no Firestore
  static const String _collection = 'denuncias';

  /// Salva uma nova denúncia na coleção [denuncias].
  ///
  /// Retorna o ID do documento criado.
  Future<String> salvarDenuncia({
    required String categoria,
    required String descricao,
    required double latitude,
    required double longitude,
  }) async {
    final docRef = await _db.collection(_collection).add({
      'categoria': categoria,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'Pendente',
      'timestamp': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Retorna um stream em tempo real de todas as denúncias.
  ///
  /// O app escuta mudanças automaticamente via [snapshots()].
  Stream<List<Denuncia>> streamDenuncias() {
    return _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Denuncia.fromFirestore(doc)).toList());
  }
}
