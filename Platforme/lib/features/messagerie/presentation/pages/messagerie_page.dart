import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/services/platform_data_service.dart';
import '../../../../features/entreprises/domain/models/document_entreprise.dart';
import '../providers/messagerie_provider.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';
import '../../../entreprises/domain/models/entreprise.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../../core/utils/toast_utils.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({super.key});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _initialise = false;
  String _activeFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !context.read<MessagerieProvider>().isLoadingMore) {
      context.read<MessagerieProvider>().chargerPlusDeMessages();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialise) {
      _initialise = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final entreprises = context.read<EntrepriseProvider>().entreprises;
        context.read<MessagerieProvider>().chargerConversations(entreprises);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _envoyer() async {
    final texte = _textController.text.trim();
    if (texte.isEmpty) return;
    _textController.clear();
    await context.read<MessagerieProvider>().envoyerMessage(texte);
    _scrollToBottom();
    _focusNode.requestFocus();
  }

  Future<void> _selectionnerEtEnvoyerFichier(bool seulementImages) async {
    final provider = context.read<MessagerieProvider>();

    try {
      final result = await FilePicker.pickFiles(
        type: seulementImages ? FileType.image : FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) {
          ToastUtils.show(
            context,
            'Aucun fichier sélectionné ou sélection annulée.',
            isError: false,
          );
        }
        return;
      }

      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null) {
        try {
          bytes = await file.xFile.readAsBytes();
        } catch (e) {
          debugPrint('[MessageriePage] Erreur lecture bytes via xFile : $e');
        }
      }
      if (!kIsWeb && bytes == null && file.path != null) {
        final f = io.File(file.path!);
        if (f.existsSync()) {
          bytes = f.readAsBytesSync();
        }
      }
      if (bytes == null) {
        debugPrint('[MessageriePage] Aucun octet de fichier récupéré');
        if (mounted) {
          ToastUtils.show(
            context,
            'Impossible de lire le contenu du fichier sélectionné.',
            isError: true,
          );
        }
        return;
      }

      if (mounted) {
        ToastUtils.show(
          context,
          'Téléversement de ${file.name}...',
          isError: false,
        );
      }

      await provider.envoyerMessageAvecFichier(
        nomFichier: file.name,
        octets: bytes,
        contenu: '',
      );

      if (mounted) {
        _scrollToBottom();
        ToastUtils.show(
          context,
          'Fichier ${file.name} envoyé avec succès !',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('[MessageriePage] Erreur sélection fichier : $e');
      if (mounted) {
        ToastUtils.show(
          context,
          'Erreur lors du téléversement : $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.messagerie,
      title: 'HMI Stars - Messagerie',
      body: Consumer2<MessagerieProvider, EntrepriseProvider>(
        builder: (context, messagerie, entreprises, _) {
          final doitCharger = entreprises.status == LoadStatus.loaded && 
                             messagerie.conversations.length != entreprises.entreprises.length &&
                             !messagerie.chargement;

          if (doitCharger) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              messagerie.chargerConversations(entreprises.entreprises);
            });
          }

          final liveEntreprise = messagerie.entrepriseSelectionneeId == null
              ? null
              : entreprises.entreprises.firstWhere(
                  (e) => e.id == messagerie.entrepriseSelectionneeId,
                  orElse: () => messagerie.conversationSelectionnee!.entreprise,
                );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSidebar(messagerie, entreprises),

              if (messagerie.entrepriseSelectionneeId == null)
                _buildPlaceholder()
              else
                Expanded(
                  flex: 2,
                  child: _buildZoneChat(messagerie, liveEntreprise!),
                ),

              if (messagerie.conversationSelectionnee != null)
                _buildPanneauInfo(messagerie, liveEntreprise!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(MessagerieProvider messagerie, EntrepriseProvider entreprises) {
    final list = messagerie.conversations.where((conv) {
      final matchesFilter = _activeFilter == 'Favoris'
          ? messagerie.estFavori(conv.entreprise.id)
          : true;
      if (!matchesFilter) return false;
      
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final ent = entreprises.entreprises.firstWhere(
          (e) => e.id == conv.entreprise.id,
          orElse: () => conv.entreprise,
        );
        return ent.nom.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Text(
              context.tr('Messagerie', 'Messaging'),
              style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
            ),
          ),
          // Search input on messages sidebar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr('Rechercher...', 'Search...'),
                  hintStyle: AppTextStyles.bodySmall.copyWith(color: cs.outline),
                  prefixIcon: Icon(Icons.search, size: 16, color: cs.outline),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
                style: AppTextStyles.bodySmall.copyWith(color: cs.onSurface),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      label: context.tr('Tous', 'All'),
                      isSelected: _activeFilter == 'Tous',
                      onTap: () => setState(() => _activeFilter = 'Tous'),
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      label: context.tr('Favoris', 'Favorites'),
                      isSelected: _activeFilter == 'Favoris',
                      onTap: () => setState(() => _activeFilter = 'Favoris'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _activeFilter == 'Favoris'
                  ? context.tr('ENTREPRISES FAVORITES', 'FAVORITE COMPANIES')
                  : context.tr('ENTREPRISES CLIENTES', 'CLIENT COMPANIES'),
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 1.1,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: messagerie.chargement
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : list.isEmpty
                    ? Center(
                        child: Text(
                          _activeFilter == 'Favoris'
                              ? context.tr('Aucun favori', 'No favorites')
                              : context.tr('Aucune entreprise', 'No companies'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final conv = list[i];
                          final selected = conv.entreprise.id == messagerie.entrepriseSelectionneeId;
                          final ent = entreprises.entreprises.firstWhere(
                            (e) => e.id == conv.entreprise.id,
                            orElse: () => conv.entreprise,
                          );
                          return _EntrepriseContactItem(
                            raisonSociale: ent.nom,
                            logoUrl: ent.logoUrl,
                            dernierMessage: conv.dernierMessage,
                            dateEnvoi: conv.dateEnvoi,
                            estEnvoyeParUser: conv.estEnvoyeParUser,
                            aDesNonLus: conv.aDesMessagesNonLus,
                            selected: selected,
                            onTap: () {
                              messagerie.selectionnerEntreprise(conv.entreprise.id);
                              _focusNode.requestFocus();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? cs.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Expanded(
      flex: 2,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              context.tr('Sélectionnez une entreprise', 'Select a company'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('pour consulter et envoyer des messages', 'to view and send messages'),
              style: TextStyle(color: cs.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneChat(MessagerieProvider messagerie, Entreprise liveEntreprise) {
    final conv = messagerie.conversationSelectionnee!;
    final messages = messagerie.messagesActuels;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primaryContainer,
                backgroundImage: (liveEntreprise.logoUrl != null && liveEntreprise.logoUrl!.isNotEmpty)
                    ? NetworkImage(liveEntreprise.logoUrl!)
                    : null,
                child: (liveEntreprise.logoUrl == null || liveEntreprise.logoUrl!.isEmpty)
                    ? Text(
                        liveEntreprise.nom.isNotEmpty
                            ? liveEntreprise.nom[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                liveEntreprise.nom,
                style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
              ),
              const Spacer(),
              Tooltip(
                message: context.tr('Voir les détails de l\'entreprise', 'View company details'),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.entrepriseDetails,
                      arguments: conv.entreprise.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('Détails', 'Details'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: cs.surface,
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      context.tr('Aucun message — commencez la conversation', 'No messages — start the conversation'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: cs.outline,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length + (messagerie.hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final msg = messages[i];
                      final showDate = i == messages.length - 1 ||
                          !_memJour(
                            messages[i + 1].dateEnvoi,
                            msg.dateEnvoi,
                          );
                      return Column(
                        children: [
                          if (showDate)
                            _buildSeparateurDate(msg.dateEnvoi),
                          _BubbleMessage(
                            message: msg,
                            estMoi: !msg.estEnvoyeParUser,
                            heure: _formatHeure(msg.dateEnvoi),
                            entrepriseLogoUrl: liveEntreprise.logoUrl,
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
          ),
        ),

        _buildZoneSaisie(messagerie),
      ],
    );
  }

  Widget _buildSeparateurDate(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDate(date),
                style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSaisie(MessagerieProvider messagerie) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: cs.outline),
            tooltip: context.tr('Joindre un fichier', 'Attach a file'),
            onPressed: () => _selectionnerEtEnvoyerFichier(false),
          ),
          IconButton(
            icon: Icon(Icons.image_outlined, color: cs.outline),
            tooltip: context.tr('Joindre une image', 'Attach an image'),
            onPressed: () => _selectionnerEtEnvoyerFichier(true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: context.tr('Écrire un message...', 'Write a message...'),
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: cs.outline,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _envoyer(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: messagerie.envoi ? null : _envoyer,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: messagerie.envoi
                    ? cs.outlineVariant
                    : cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: messagerie.envoi
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanneauInfo(MessagerieProvider messagerie, Entreprise liveEntreprise) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: cs.primaryContainer,
              backgroundImage: (liveEntreprise.logoUrl != null && liveEntreprise.logoUrl!.isNotEmpty)
                  ? NetworkImage(liveEntreprise.logoUrl!)
                  : null,
              child: (liveEntreprise.logoUrl == null || liveEntreprise.logoUrl!.isEmpty)
                  ? Text(
                      liveEntreprise.nom.isNotEmpty
                          ? liveEntreprise.nom[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    liveEntreprise.nom,
                    style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    messagerie.estFavori(liveEntreprise.id) ? Icons.star : Icons.star_border,
                    color: messagerie.estFavori(liveEntreprise.id) ? Colors.amber : cs.outline,
                  ),
                  tooltip: messagerie.estFavori(liveEntreprise.id)
                      ? context.tr('Retirer des favoris', 'Remove from favorites')
                      : context.tr('Ajouter aux favoris', 'Add to favorites'),
                  onPressed: () => messagerie.toggleFavori(liveEntreprise.id),
                ),
              ],
            ),
            if (liveEntreprise.nomGerant.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                liveEntreprise.nomGerant,
                style: AppTextStyles.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _infoLigne(Icons.email_outlined, liveEntreprise.email),
            if (liveEntreprise.telephone.isNotEmpty)
              _infoLigne(Icons.phone_outlined, liveEntreprise.telephone),
            if (liveEntreprise.adressePhysique.isNotEmpty)
              _infoLigne(Icons.location_on_outlined, liveEntreprise.adressePhysique),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _couleurStatut(liveEntreprise.statut).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  context.tr(
                    liveEntreprise.statut,
                    liveEntreprise.statut == 'EN COURS'
                        ? 'IN PROGRESS'
                        : liveEntreprise.statut == 'ATTENTE DOCS'
                            ? 'AWAITING DOCS'
                            : liveEntreprise.statut == 'COMPLET'
                                ? 'COMPLETE'
                                : liveEntreprise.statut,
                  ),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _couleurStatut(liveEntreprise.statut),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('FICHIERS RÉCENTS', 'RECENT FILES'),
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 1.1,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildFichiersRecents(messagerie, liveEntreprise),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFichiersRecents(MessagerieProvider messagerie, Entreprise liveEntreprise) {
    final fichiers = messagerie.messagesActuels.where((m) => m.estFichier && m.fichierUrl != null).toList();
    if (fichiers.isEmpty) {
      return [
        Text(
          context.tr('Aucun fichier partagé', 'No shared files'),
          style: AppTextStyles.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    final displayedFichiers = fichiers.take(5).toList();
    final List<Widget> list = displayedFichiers.map<Widget>((msg) {
      final nom = msg.fichierNom ?? 'Fichier';
      final url = msg.fichierUrl!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    list.add(
      Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _ouvrirPopupFichiers(
              context,
              liveEntreprise.id,
              liveEntreprise.nom,
            ),
            icon: Icon(Icons.grid_view_rounded, size: 16, color: cs.primary),
            label: Text(
              context.tr('Afficher tous les fichiers', 'Show all files'),
              style: AppTextStyles.labelMedium.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              backgroundColor: cs.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );

    return list;
  }

  void _ouvrirPopupFichiers(BuildContext context, String entrepriseId, String entrepriseNom) {
    showDialog(
      context: context,
      builder: (context) => _FichiersListeDialog(
        entrepriseId: entrepriseId,
        entrepriseNom: entrepriseNom,
      ),
    );
  }

  Widget _infoLigne(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'EN COURS':
        return cs.primary;
      case 'ATTENTE DOCS':
        return AppColors.tertiary;
      case 'COMPLET':
        return AppColors.success;
      default:
        return cs.outline;
    }
  }

  bool _memJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (_memJour(d, now)) return context.tr("Aujourd'hui", "Today");
    if (_memJour(d, now.subtract(const Duration(days: 1)))) return context.tr('Hier', 'Yesterday');
    
    final isEn = context.tr('FR', 'EN') == 'EN';
    final moisFr = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    final moisEn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = isEn ? moisEn[d.month - 1] : moisFr[d.month - 1];
    
    return isEn ? '$m ${d.day}, ${d.year}' : '${d.day} $m ${d.year}';
  }

  String _formatHeure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _EntrepriseContactItem extends StatelessWidget {
  final String raisonSociale;
  final String? logoUrl;
  final String? dernierMessage;
  final DateTime? dateEnvoi;
  final bool estEnvoyeParUser;
  final bool aDesNonLus;
  final bool selected;
  final VoidCallback onTap;

  const _EntrepriseContactItem({
    required this.raisonSociale,
    this.logoUrl,
    this.dernierMessage,
    this.dateEnvoi,
    this.estEnvoyeParUser = true,
    required this.aDesNonLus,
    required this.selected,
    required this.onTap,
  });

  String _formatageTemps(DateTime? d, BuildContext context) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return context.tr('Hier', 'Yesterday');
    if (diff.inDays < 7) return context.tr('Il y a ${diff.inDays}j', '${diff.inDays}d ago');
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          border: selected
              ? Border(
                  left: BorderSide(color: cs.primary, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: selected
                  ? cs.primary
                  : cs.surfaceContainerHighest,
              backgroundImage: (logoUrl != null && logoUrl!.isNotEmpty)
                  ? NetworkImage(logoUrl!)
                  : null,
              child: (logoUrl == null || logoUrl!.isEmpty)
                  ? Text(
                      raisonSociale.isNotEmpty
                          ? raisonSociale[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : cs.onSurfaceVariant,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raisonSociale,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: (selected || aDesNonLus) ? FontWeight.w800 : FontWeight.w600,
                      fontSize: aDesNonLus ? 14 : 13,
                      color: selected
                          ? cs.primary
                          : (aDesNonLus ? cs.onSurface : cs.onSurface),
                    ),
                  ),
                  if (dernierMessage != null)
                    Text(
                      '${estEnvoyeParUser ? "" : context.tr("Vous : ", "You: ")}$dernierMessage',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: selected 
                            ? cs.primary.withValues(alpha: 0.8) 
                            : (aDesNonLus ? cs.onSurface : cs.onSurfaceVariant),
                        fontWeight: (aDesNonLus || (estEnvoyeParUser && !selected))
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    )
                  else
                    Text(
                      context.tr('Aucun message', 'No messages'),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: cs.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            if (dateEnvoi != null)
              Text(
                _formatageTemps(dateEnvoi, context),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _BubbleMessage extends StatelessWidget {
  final MessagePlateforme message;
  final bool estMoi;
  final String heure;
  final String? entrepriseLogoUrl;

  const _BubbleMessage({
    required this.message,
    required this.estMoi,
    required this.heure,
    this.entrepriseLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFile = message.estFichier && message.fichierUrl != null;
    final List<String> fileUrls = hasFile ? message.fichierUrl!.split(',') : [];
    final List<String> fileNames = hasFile ? (message.fichierNom?.split(',') ?? []) : [];

    final urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    final hasUrl = urlRegExp.hasMatch(message.contenu);
    final String? firstUrl = hasUrl ? urlRegExp.firstMatch(message.contenu)?.group(0) : null;

    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.surfaceContainer,
              backgroundImage: (entrepriseLogoUrl != null && entrepriseLogoUrl!.isNotEmpty)
                  ? NetworkImage(entrepriseLogoUrl!)
                  : null,
              child: (entrepriseLogoUrl == null || entrepriseLogoUrl!.isEmpty)
                  ? Icon(
                      Icons.business,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                estMoi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: estMoi ? cs.primaryGradient : null,
                  color: estMoi
                      ? null
                      : cs.surfaceContainerLowest,
                  border: estMoi
                      ? null
                      : Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                          width: 1,
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(estMoi ? 20 : 4),
                    bottomRight: Radius.circular(estMoi ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasFile) ...[
                      ...List.generate(fileUrls.length, (index) {
                        final url = fileUrls[index];
                        final nom = index < fileNames.length ? fileNames[index] : 'Fichier';
                        final uLower = url.toLowerCase();
                        final nLower = nom.toLowerCase();
                        final currentIsImage = uLower.contains('.png') ||
                            uLower.contains('.jpg') ||
                            uLower.contains('.jpeg') ||
                            uLower.contains('.webp') ||
                            uLower.contains('.gif') ||
                            nLower.endsWith('.png') ||
                            nLower.endsWith('.jpg') ||
                            nLower.endsWith('.jpeg') ||
                            nLower.endsWith('.webp') ||
                            nLower.endsWith('.gif');

                        return Padding(
                          padding: EdgeInsets.only(bottom: index < fileUrls.length - 1 ? 8.0 : 0),
                          child: currentIsImage
                              ? GestureDetector(
                                  onTap: () => afficherGrandApercuImage(
                                    context,
                                    url,
                                    nom,
                                  ),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                          maxWidth: 380,
                                        ),
                                        child: Hero(
                                          tag: url,
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: cs.surfaceContainerHigh,
                                              padding: const EdgeInsets.all(16),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.broken_image, color: AppColors.error),
                                                  SizedBox(width: 8),
                                                  Text('Image non disponible'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => _ouvrirUrl(url),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: estMoi
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : cs.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.insert_drive_file,
                                            color: estMoi ? Colors.white : cs.primary,
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  nom,
                                                  style: AppTextStyles.bodyMedium.copyWith(
                                                    color: estMoi ? Colors.white : cs.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Télécharger le fichier',
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    color: estMoi ? Colors.white70 : cs.onSurfaceVariant,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],

                    if (message.contenu.isNotEmpty)
                      Text(
                        message.contenu,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: estMoi ? Colors.white : cs.onSurface,
                          height: 1.4,
                        ),
                      ),

                    if (firstUrl != null) ...[
                      const SizedBox(height: 8),
                      _LinkPreviewCard(url: firstUrl, estMoi: estMoi),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    heure,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  if (estMoi) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: message.estLu ? Colors.blue : cs.outline,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (estMoi) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Icon(
                Icons.support_agent,
                size: 14,
                color: cs.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkPreviewCard extends StatelessWidget {
  final String url;
  final bool estMoi;

  const _LinkPreviewCard({required this.url, required this.estMoi});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uri = Uri.tryParse(url);
    final domain = uri?.host ?? 'Lien externe';
    
    final title = domain.contains('github') 
        ? 'GitHub: Where the world builds software' 
        : domain.contains('supabase') 
            ? 'Supabase | The Open Source Firebase Alternative'
            : domain.contains('google')
                ? 'Google'
                : 'Aperçu du lien';
                
    final description = domain.contains('github')
        ? 'GitHub helps development teams collaborate, configure, and secure code.'
        : domain.contains('supabase')
            ? 'Create a backend in less than 2 minutes. Start for free.'
            : 'Cliquez pour ouvrir le lien dans un nouvel onglet.';

    return GestureDetector(
      onTap: () => _ouvrirUrl(url),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 320,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: estMoi ? Colors.white.withValues(alpha: 0.1) : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estMoi ? Colors.white30 : cs.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: estMoi ? Colors.white.withValues(alpha: 0.05) : cs.surfaceContainerHigh,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 14,
                      color: estMoi ? Colors.white70 : cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        domain,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: estMoi ? Colors.white70 : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: estMoi ? Colors.white : cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: estMoi ? Colors.white70 : cs.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _ouvrirUrl(String urlString) async {
  final uri = Uri.tryParse(urlString);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void afficherGrandApercuImage(BuildContext context, String imageUrl, String fileName) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (context) {
      return GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 4.0,
                minScale: 0.5,
                child: Center(
                  child: Hero(
                    tag: imageUrl,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text(
                            'Impossible de charger l\'image',
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _FichiersListeDialog extends StatefulWidget {
  final String entrepriseId;
  final String entrepriseNom;

  const _FichiersListeDialog({
    required this.entrepriseId,
    required this.entrepriseNom,
  });

  @override
  State<_FichiersListeDialog> createState() => _FichiersListeDialogState();
}

class _FichiersListeDialogState extends State<_FichiersListeDialog> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  final _dataService = PlatformDataService();
  final _scrollController = ScrollController();
  final List<DocumentEntreprise> _files = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _limit = 30;

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreFiles();
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newFiles = await _dataService.fetchDocumentsForEntreprisePaginated(
        widget.entrepriseId,
        0,
        _limit,
      );
      setState(() {
        _files.clear();
        _files.addAll(newFiles);
        _hasMore = newFiles.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastUtils.show(
          context,
          'Erreur lors du chargement des fichiers : $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadMoreFiles() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newFiles = await _dataService.fetchDocumentsForEntreprisePaginated(
        widget.entrepriseId,
        _files.length,
        _limit,
      );
      setState(() {
        _files.addAll(newFiles);
        _hasMore = newFiles.length == _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case '.pdf':
        return Colors.red.shade700;
      case '.xls':
      case '.xlsx':
        return Colors.green.shade700;
      case '.doc':
      case '.docx':
        return Colors.blue.shade700;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Colors.purple.shade700;
      default:
        return cs.primary;
    }
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart_outlined;
      case '.doc':
      case '.docx':
        return Icons.description_outlined;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatDateAjout(DateTime d) {
    final isEn = context.tr('FR', 'EN') == 'EN';
    final moisFr = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    final moisEn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = isEn ? moisEn[d.month - 1] : moisFr[d.month - 1];
    
    final String timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return isEn 
        ? '$m ${d.day}, ${d.year} at $timeStr' 
        : '${d.day} $m ${d.year} à $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 550,
          height: 600,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.folder_shared_outlined,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Fichiers de ${widget.entrepriseNom}', 'Files of ${widget.entrepriseNom}'),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            context.tr('Tous les documents partagés dans cette conversation', 'All documents shared in this conversation'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        hoverColor: cs.surfaceContainerHigh,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Files list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _files.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 48,
                                  color: cs.outline.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('Aucun fichier partagé dans ce salon', 'No files shared in this chat'),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              itemCount: _files.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                final cs = Theme.of(context).colorScheme;
                                if (index == _files.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final doc = _files[index];
                                final formatColor = _getFormatColor(doc.format);
                                final formatIcon = _getFormatIcon(doc.format);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: formatColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          formatIcon,
                                          color: formatColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        doc.nom,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        _formatDateAjout(doc.dateAjout),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 18,
                                        ),
                                        tooltip: context.tr('Ouvrir le document', 'Open document'),
                                        onPressed: () async {
                                          if (doc.url != null) {
                                            final uri = Uri.parse(doc.url!);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
