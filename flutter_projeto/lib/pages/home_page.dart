import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/grupo_model.dart';
import 'auth_page.dart';
import 'grupo_detalhes_page.dart';
import 'criar_grupo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  String _filtroMateria = 'Programacao';
  bool _mostrarApenasMeus = false;

  IconData _iconeMateria(String materia) {
    switch (materia) {
      case 'Matematica':
        return Icons.calculate_outlined;
      case 'BancoDeDados':
        return Icons.storage_outlined;
      default:
        return Icons.code_outlined;
    }
  }

  Future<void> _abrirGithub(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir o link do GitHub.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyHub - Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: _filtroMateria,
                items: const [
                  DropdownMenuItem(
                      value: 'Programacao', child: Text('Programação')),
                  DropdownMenuItem(
                      value: 'Matematica', child: Text('Matemática')),
                  DropdownMenuItem(
                      value: 'BancoDeDados', child: Text('Banco de Dados')),
                ],
                onChanged: (val) => setState(() {
                  _filtroMateria = val!;
                  _mostrarApenasMeus = false;
                }),
              ),
              FilterChip(
                label: const Text('Meus Grupos'),
                selected: _mostrarApenasMeus,
                onSelected: (selected) =>
                    setState(() => _mostrarApenasMeus = selected),
              )
            ],
          ),
          Expanded(
            child: StreamBuilder<List<GrupoModel>>(
              stream: _mostrarApenasMeus
                  ? _dbService.getMeusGrupos(currentUserId)
                  : _dbService.getGruposPorMateria(_filtroMateria),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final grupos = snapshot.data!;
                return ListView.builder(
                  itemCount: grupos.length,
                  itemBuilder: (context, index) {
                    final grupo = grupos[index];
                    final votou = grupo.votosUsuarios.contains(currentUserId);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Icon(_iconeMateria(grupo.materia)),
                          ),
                          title: Text(grupo.nomeGrupo,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('${grupo.materia} - ${grupo.descricao}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Votar neste grupo',
                                icon: Icon(Icons.arrow_upward,
                                    color: votou ? Colors.deepOrange : null),
                                onPressed: currentUserId.isEmpty
                                    ? null
                                    : () async {
                                        await _dbService.votarGrupo(
                                            grupo.id, currentUserId);
                                      },
                              ),
                              Text('${grupo.upvotes}'),
                              if (grupo.githubUrl != null)
                                IconButton(
                                  tooltip: 'Abrir GitHub',
                                  icon: const Icon(Icons.code),
                                  onPressed: () =>
                                      _abrirGithub(grupo.githubUrl!),
                                ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    GrupoDetalhesPage(grupo: grupo)),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CriarGrupoPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
