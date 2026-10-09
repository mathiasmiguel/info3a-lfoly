import 'package:cloud_firestore/cloud_firestore.dart';

class ComentarioModel {
  final String id;
  final String texto;
  final String autorEmail;
  final String autorId;
  final DateTime dataPostagem;

  ComentarioModel({
    required this.id,
    required this.texto,
    required this.autorEmail,
    required this.autorId,
    required this.dataPostagem,
  });

  factory ComentarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComentarioModel(
      id: doc.id,
      texto: data['texto'] ?? '',
      autorEmail: data['autorEmail'] ?? '',
      autorId: data['autorId'] ?? '',
      dataPostagem:
          (data['dataPostagem'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'texto': texto,
      'autorEmail': autorEmail,
      'autorId': autorId,
      'dataPostagem': FieldValue.serverTimestamp(),
    };
  }
}
