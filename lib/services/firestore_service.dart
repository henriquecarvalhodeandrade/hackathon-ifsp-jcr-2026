import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados de uma denúncia.
class Denuncia {
  final String id;
  final String categoria;
  final String descricao;
  final double latitude;
  final double longitude;
  final String status;
  final String gravidade;
  final String? fotoUrl;
  final String? userId;
  final DateTime? timestamp;

  Denuncia({
    required this.id,
    required this.categoria,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.gravidade,
    this.fotoUrl,
    this.userId,
    this.timestamp,
  });

  factory Denuncia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Denuncia(
      id: doc.id,
      categoria: data['categoria'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Pendente',
      gravidade: data['gravidade'] as String? ?? 'Média',
      fotoUrl: data['fotoUrl'] as String?,
      userId: data['userId'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

/// Serviço responsável por toda interação com o Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'denuncias';

  static const List<String> categorias = [
    'Buraco na Via',
    'Iluminação Pública',
    'Acúmulo de Lixo',
    'Enchente/Drenagem',
    'Calçada Danificada',
    'Sinalização',
    'Outros',
  ];

  static const List<String> gravidades = ['Baixa', 'Média', 'Alta'];

  static const List<String> statusList = [
    'Pendente',
    'Em andamento',
    'Resolvido',
  ];

  Future<String> salvarDenuncia({
    required String categoria,
    required String descricao,
    required double latitude,
    required double longitude,
    required String gravidade,
    String? fotoUrl,
    String? userId,
  }) async {
    final docRef = await _db.collection(_collection).add({
      'categoria': categoria,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'Pendente',
      'gravidade': gravidade,
      'fotoUrl': fotoUrl,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> atualizarStatus(String id, String novoStatus) async {
    await _db.collection(_collection).doc(id).update({'status': novoStatus});
  }

  Stream<List<Denuncia>> streamDenuncias() {
    return _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Denuncia.fromFirestore(doc)).toList(),
        );
  }
}
