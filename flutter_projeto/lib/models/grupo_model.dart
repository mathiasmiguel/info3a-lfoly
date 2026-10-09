// lib/models/grupo_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GrupoModel {
  final String id;
  final String nomeGrupo;
  final String materia;
  final String descricao;
  final String criadoPor;
  final DateTime dataCriacao;
  final bool ativo;
  final int upvotes;
  final List<String> votosUsuarios;
  final String? githubUrl;

  GrupoModel({
    required this.id,
    required this.nomeGrupo,
    required this.materia,
    required this.descricao,
    required this.criadoPor,
    required this.dataCriacao,
    required this.ativo,
    this.upvotes = 0,
    this.votosUsuarios = const [],
    this.githubUrl,
  });

  // Mapeia o DocumentSnapshot do Firestore para a entidade local
  factory GrupoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GrupoModel(
      id: doc.id,
      nomeGrupo: data['nomeGrupo'] ?? '',
      materia: data['materia'] ?? '',
      descricao: data['descricao'] ?? '',
      criadoPor: data['criadoPor'] ?? '',
      dataCriacao:
          (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ativo: data['ativo'] ?? true,
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      votosUsuarios: List<String>.from(data['votosUsuarios'] ?? const []),
      githubUrl: data['githubUrl'] as String?,
    );
  }

  // Converte os dados da classe para o formato serializável exigido pelo Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nomeGrupo': nomeGrupo,
      'materia': materia,
      'descricao': descricao,
      'criadoPor': criadoPor,
      'dataCriacao': FieldValue
          .serverTimestamp(), // Garante a hora correta do servidor do Firebase
      'ativo': ativo,
      'upvotes': upvotes,
      'votosUsuarios': votosUsuarios,
      'githubUrl': githubUrl,
    };
  }
}
