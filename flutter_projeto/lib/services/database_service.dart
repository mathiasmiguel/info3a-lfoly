// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comentario_model.dart';
import '../models/grupo_model.dart';
import '../models/material_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referência base para a coleção principal "grupos"
  CollectionReference get _gruposRef => _db.collection('grupos');

  // Adiciona um novo grupo como documento na coleção "grupos"
  Future<DocumentReference> criarGrupo(GrupoModel grupo) async {
    return await _gruposRef.add(grupo.toFirestore());
  }

  Future<bool> votarGrupo(String grupoId, String userId) async {
    return _db.runTransaction<bool>((transaction) async {
      final referencia = _gruposRef.doc(grupoId);
      final snapshot = await transaction.get(referencia);
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) {
        throw StateError('Grupo não encontrado.');
      }

      final votos = List<String>.from(data['votosUsuarios'] ?? const []);
      final jaVotou = votos.contains(userId);

      transaction.update(referencia, {
        'upvotes': FieldValue.increment(jaVotou ? -1 : 1),
        'votosUsuarios': jaVotou
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });

      return !jaVotou;
    });
  }

  // Consulta A: Filtra documentos na coleção principal por matéria específica (.where)
  Stream<List<GrupoModel>> getGruposPorMateria(String materia) {
    return _gruposRef.where('materia', isEqualTo: materia).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => GrupoModel.fromFirestore(doc)).toList());
  }

  // Consulta B: Filtra documentos criados pelo utilizador atual (.where)
  Stream<List<GrupoModel>> getMeusGrupos(String userId) {
    return _gruposRef.where('criadoPor', isEqualTo: userId).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => GrupoModel.fromFirestore(doc)).toList());
  }

  // Adiciona um documento na SUBCOLEÇÃO incorporada: "grupos/{grupoId}/materiais"
  Future<DocumentReference> adicionarMaterial(
      String grupoId, MaterialModel material) async {
    return await _gruposRef
        .doc(grupoId)
        .collection('materiais')
        .add(material.toFirestore());
  }

  Future<bool> votarMaterial(
      String grupoId, String materialId, String userId) async {
    return _db.runTransaction<bool>((transaction) async {
      final referencia =
          _gruposRef.doc(grupoId).collection('materiais').doc(materialId);
      final snapshot = await transaction.get(referencia);
      final data = snapshot.data();

      if (data == null) {
        throw StateError('Material não encontrado.');
      }

      final votos = List<String>.from(data['votosUsuarios'] ?? const []);
      final jaVotou = votos.contains(userId);

      transaction.update(referencia, {
        'upvotes': FieldValue.increment(jaVotou ? -1 : 1),
        'votosUsuarios': jaVotou
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      });

      return !jaVotou;
    });
  }

  Future<DocumentReference> adicionarComentario(
      String grupoId, String materialId, ComentarioModel comentario) async {
    return await _gruposRef
        .doc(grupoId)
        .collection('materiais')
        .doc(materialId)
        .collection('comentarios')
        .add(comentario.toFirestore());
  }

  Stream<List<ComentarioModel>> getComentariosDoMaterial(
      String grupoId, String materialId) {
    return _gruposRef
        .doc(grupoId)
        .collection('materiais')
        .doc(materialId)
        .collection('comentarios')
        .orderBy('dataPostagem', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComentarioModel.fromFirestore(doc))
            .toList());
  }

  // Escuta os documentos da SUBCOLEÇÃO "materiais" em tempo real
  Stream<List<MaterialModel>> getMateriaisDoGrupo(String grupoId) {
    return _gruposRef
        .doc(grupoId)
        .collection('materiais')
        .orderBy('dataPostagem', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialModel.fromFirestore(doc))
            .toList());
  }
}
