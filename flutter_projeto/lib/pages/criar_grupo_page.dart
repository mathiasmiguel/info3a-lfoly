// lib/pages/criar_grupo_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/grupo_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class CriarGrupoPage extends StatefulWidget {
  const CriarGrupoPage({super.key});

  @override
  State<CriarGrupoPage> createState() => _CriarGrupoPageState();
}

class _CriarGrupoPageState extends State<CriarGrupoPage> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _githubController = TextEditingController();
  String _materiaSelecionada = 'Programacao';
  bool _salvando = false;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  Future<void> _salvarGrupo() async {
    final user = _authService.currentUser;
    final nome = _nomeController.text.trim();

    if (user == null || nome.isEmpty || _salvando) {
      if (user != null && nome.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um nome para o grupo.')),
        );
      }
      return;
    }

    setState(() => _salvando = true);

    try {
      final novoGrupo = GrupoModel(
        id: '',
        nomeGrupo: nome,
        materia: _materiaSelecionada,
        descricao: _descricaoController.text.trim(),
        criadoPor: user.uid,
        dataCriacao: DateTime.now(),
        ativo: true,
        githubUrl: _githubController.text.trim().isEmpty
            ? null
            : _githubController.text.trim(),
      );

      await _dbService
          .criarGrupo(novoGrupo)
          .timeout(const Duration(seconds: 15));
      if (mounted) Navigator.of(context).pop();
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'A gravação demorou. Verifique sua conexão e tente novamente.')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Não foi possível criar o grupo: ${error.message ?? error.code}.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Não foi possível criar o grupo. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Grupo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Grupo')),
            TextField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(
              controller: _githubController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL do GitHub (opcional)',
                prefixIcon: Icon(Icons.code),
              ),
            ),
            DropdownButton<String>(
              value: _materiaSelecionada,
              items: const [
                DropdownMenuItem(
                    value: 'Programacao', child: Text('Programação')),
                DropdownMenuItem(
                    value: 'Matematica', child: Text('Matemática')),
                DropdownMenuItem(
                    value: 'BancoDeDados', child: Text('Banco de Dados')),
              ],
              onChanged: (val) => setState(() => _materiaSelecionada = val!),
            ),
            ElevatedButton(
              onPressed: _salvando ? null : _salvarGrupo,
              child: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar Grupo'),
            ),
          ],
        ),
      ),
    );
  }
}
