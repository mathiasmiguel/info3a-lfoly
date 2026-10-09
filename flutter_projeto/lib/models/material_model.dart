// lib/models/material_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String id;
  final String titulo;
  final String conteudo;
  final String autorEmail;
  final String autorId;
  final DateTime dataPostagem;
  final int upvotes;
  final List<String> votosUsuarios;
  final String? githubUrl;

  MaterialModel({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.autorEmail,
    required this.autorId,
    required this.dataPostagem,
    this.upvotes = 0,
    this.votosUsuarios = const [],
    this.githubUrl,
  });

  // Mapeia o documento retornado da subcoleção "materiais"
  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaterialModel(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      conteudo: data['conteudo'] ?? '',
      autorEmail: data['autorEmail'] ?? '',
      autorId: data['autorId'] ?? '',
      dataPostagem:
          (data['dataPostagem'] as Timestamp?)?.toDate() ?? DateTime.now(),
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      votosUsuarios: List<String>.from(data['votosUsuarios'] ?? const []),
      githubUrl: data['githubUrl'] as String?,
    );
  }

  // Prepara o objeto para ser gravado dentro da subcoleção no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'conteudo': conteudo,
      'autorEmail': autorEmail,
      'autorId': autorId,
      'dataPostagem': FieldValue.serverTimestamp(),
      'upvotes': upvotes,
      'votosUsuarios': votosUsuarios,
      'githubUrl': githubUrl,
    };
  }
}
