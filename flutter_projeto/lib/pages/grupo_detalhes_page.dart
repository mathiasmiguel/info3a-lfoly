// lib/pages/grupo_detalhes_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/comentario_model.dart';
import '../models/grupo_model.dart';
import '../models/material_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class GrupoDetalhesPage extends StatefulWidget {
  final GrupoModel grupo;
  const GrupoDetalhesPage({super.key, required this.grupo});

  @override
  State<GrupoDetalhesPage> createState() => _GrupoDetalhesPageState();
}

class _GrupoDetalhesPageState extends State<GrupoDetalhesPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  final _githubController = TextEditingController();
  late int _upvotes;
  late List<String> _votosUsuarios;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.grupo.upvotes;
    _votosUsuarios = List<String>.from(widget.grupo.votosUsuarios);
  }

  Future<void> _votar() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final votou = await _dbService.votarGrupo(widget.grupo.id, userId);
    if (!mounted) return;
    setState(() {
      if (votou) {
        _votosUsuarios.add(userId);
        _upvotes++;
      } else {
        _votosUsuarios.remove(userId);
        _upvotes--;
      }
    });
  }

  Future<void> _abrirGithub() async {
    final url = widget.grupo.githubUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o link do GitHub.')),
      );
    }
  }

  Future<bool> _votarMaterial(MaterialModel material) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return false;
    return _dbService.votarMaterial(widget.grupo.id, material.id, userId);
  }

  Future<void> _abrirGithubUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o link do GitHub.')),
      );
    }
  }

  Future<void> _adicionarComentario(
      MaterialModel material, String texto) async {
    final user = _authService.currentUser;
    final comentario = texto.trim();
    if (user == null || comentario.isEmpty) return;

    await _dbService.adicionarComentario(
      widget.grupo.id,
      material.id,
      ComentarioModel(
        id: '',
        texto: comentario,
        autorEmail: user.email ?? 'Anónimo',
        autorId: user.uid,
        dataPostagem: DateTime.now(),
      ),
    );
  }

  Future<void> _mostrarMaterial(MaterialModel material) async {
    final userId = _authService.currentUser?.uid;
    final comentarioController = TextEditingController();
    var upvotes = material.upvotes;
    var votosUsuarios = List<String>.from(material.votosUsuarios);

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final votou = userId != null && votosUsuarios.contains(userId);
            final data = MaterialLocalizations.of(context)
                .formatMediumDate(material.dataPostagem);
            final hora = MaterialLocalizations.of(context).formatTimeOfDay(
              TimeOfDay.fromDateTime(material.dataPostagem),
            );
            final larguraDialogo = (MediaQuery.sizeOf(context).width - 48)
                .clamp(280.0, 500.0)
                .toDouble();

            return AlertDialog(
              title: Text(material.titulo),
              content: SizedBox(
                width: larguraDialogo,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Por: ${material.autorEmail}'),
                      const SizedBox(height: 4),
                      Text('$data às $hora',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      Text(material.conteudo),
                      if (material.githubUrl != null) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => _abrirGithubUrl(material.githubUrl!),
                          icon: const Icon(Icons.code),
                          label: const Text('Abrir repositório no GitHub'),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text('Comentários',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<ComentarioModel>>(
                        stream: _dbService.getComentariosDoMaterial(
                            widget.grupo.id, material.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text(
                                'Não foi possível carregar os comentários.');
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final comentarios = snapshot.data!;
                          if (comentarios.isEmpty) {
                            return const Text('Seja o primeiro a comentar.');
                          }
                          return SizedBox(
                            height: 180,
                            child: ListView.separated(
                              itemCount: comentarios.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final comentario = comentarios[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comentario.autorEmail,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(comentario.texto),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                      if (userId != null) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: comentarioController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Adicionar comentário',
                            suffixIcon: IconButton(
                              tooltip: 'Publicar comentário',
                              icon: const Icon(Icons.send),
                              onPressed: () async {
                                await _adicionarComentario(
                                    material, comentarioController.text);
                                comentarioController.clear();
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fechar'),
                ),
                FilledButton.icon(
                  onPressed: userId == null
                      ? null
                      : () async {
                          final votouAgora = await _votarMaterial(material);
                          if (!context.mounted) return;
                          setDialogState(() {
                            if (votouAgora) {
                              votosUsuarios.add(userId);
                              upvotes++;
                            } else {
                              votosUsuarios.remove(userId);
                              upvotes--;
                            }
                          });
                        },
                  icon: Icon(
                      votou ? Icons.arrow_upward : Icons.arrow_upward_outlined),
                  label: Text('$upvotes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: votou ? Colors.deepOrange : null,
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      comentarioController.dispose();
    }
  }

  void _adicionarMaterial() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final novoMaterial = MaterialModel(
      id: '',
      titulo: _tituloController.text,
      conteudo: _conteudoController.text,
      autorEmail: user.email ?? 'Anónimo',
      autorId: user.uid,
      dataPostagem: DateTime.now(),
      githubUrl: _githubController.text.trim().isEmpty
          ? null
          : _githubController.text.trim(),
    );

    await _dbService.adicionarMaterial(widget.grupo.id, novoMaterial);
    _tituloController.clear();
    _conteudoController.clear();
    _githubController.clear();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.grupo.nomeGrupo)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Votar neste grupo',
                    icon: Icon(
                      Icons.arrow_upward,
                      color:
                          _votosUsuarios.contains(_authService.currentUser?.uid)
                              ? Colors.deepOrange
                              : null,
                    ),
                    onPressed: _votar,
                  ),
                  Text('$_upvotes votos',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (widget.grupo.githubUrl != null)
                    OutlinedButton.icon(
                      onPressed: _abrirGithub,
                      icon: const Icon(Icons.code),
                      label: const Text('GitHub'),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                    controller: _tituloController,
                    decoration:
                        const InputDecoration(labelText: 'Título do Material')),
                TextField(
                    controller: _conteudoController,
                    decoration: const InputDecoration(labelText: 'Conteúdo')),
                TextField(
                  controller: _githubController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL do GitHub (opcional)',
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
                ElevatedButton(
                    onPressed: _adicionarMaterial,
                    child: const Text('Publicar Material')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<MaterialModel>>(
              // Consome o listener do Firestore específico para a SUBCOLEÇÃO "materiais"
              stream: _dbService.getMateriaisDoGrupo(widget.grupo.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final materiais = snapshot.data!;
                return ListView.builder(
                  itemCount: materiais.length,
                  itemBuilder: (context, index) {
                    final mat = materiais[index];
                    final userId = _authService.currentUser?.uid;
                    final votou =
                        userId != null && mat.votosUsuarios.contains(userId);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _mostrarMaterial(mat),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mat.titulo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Por: ${mat.autorEmail}'),
                                    const SizedBox(height: 4),
                                    Text(mat.conteudo,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Votar neste projeto',
                                        icon: Icon(Icons.arrow_upward,
                                            color: votou
                                                ? Colors.deepOrange
                                                : null),
                                        onPressed: userId == null
                                            ? null
                                            : () async {
                                                await _votarMaterial(mat);
                                              },
                                      ),
                                      Text('${mat.upvotes}'),
                                    ],
                                  ),
                                  if (mat.githubUrl != null)
                                    IconButton(
                                      tooltip: 'Abrir GitHub',
                                      icon: const Icon(Icons.code),
                                      onPressed: () =>
                                          _abrirGithubUrl(mat.githubUrl!),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
