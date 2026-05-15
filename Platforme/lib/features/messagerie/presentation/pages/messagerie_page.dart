import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';
import '../providers/messagerie_provider.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({super.key});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialise = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Dans une ListView reverse, maxScrollExtent est le HAUT de la liste (messages plus anciens)
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
      // Charger les conversations au premier rendu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final entreprises =
            context.read<EntrepriseProvider>().entreprises;
        context.read<MessagerieProvider>().chargerConversations(entreprises);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.messagerie,
      title: 'HMI Stars - Messagerie',
      body: Consumer2<MessagerieProvider, EntrepriseProvider>(
        builder: (context, messagerie, entreprises, _) {
          // Si on n'a pas encore chargé les conversations mais que les entreprises sont là
          final doitCharger = entreprises.status == LoadStatus.loaded && 
                             messagerie.conversations.length != entreprises.entreprises.length &&
                             !messagerie.chargement;

          if (doitCharger) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              messagerie.chargerConversations(entreprises.entreprises);
            });
          }

          return Row(
            children: [
              // ─── Barre latérale : liste des entreprises ───
              _buildSidebar(messagerie),

              // ─── Zone principale ───
              if (messagerie.entrepriseSelectionneeId == null)
                _buildPlaceholder()
              else
                Expanded(
                  flex: 2,
                  child: _buildZoneChat(messagerie),
                ),

              // ─── Panneau info entreprise ───
              if (messagerie.conversationSelectionnee != null)
                _buildPanneauInfo(messagerie),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sidebar
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSidebar(MessagerieProvider messagerie) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          right: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Messagerie', style: AppTextStyles.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ENTREPRISES CLIENTES',
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 1.1,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: messagerie.chargement
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : messagerie.conversations.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune entreprise',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: messagerie.conversations.length,
                        itemBuilder: (_, i) {
                          final conv = messagerie.conversations[i];
                          final selected =
                              conv.entreprise.id ==
                              messagerie.entrepriseSelectionneeId;
                          return _EntrepriseContactItem(
                            raisonSociale: conv.entreprise.nom,
                            dernierMessage: conv.dernierMessage,
                            dateEnvoi: conv.dateEnvoi,
                            estEnvoyeParUser: conv.estEnvoyeParUser,
                            aDesNonLus: conv.aDesMessagesNonLus,
                            selected: selected,
                            onTap: () => messagerie.selectionnerEntreprise(
                              conv.entreprise.id,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Placeholder
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPlaceholder() {
    return const Expanded(
      flex: 2,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.outlineVariant),
            SizedBox(height: 16),
            Text(
              'Sélectionnez une entreprise',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 15),
            ),
            SizedBox(height: 6),
            Text(
              'pour consulter et envoyer des messages',
              style: TextStyle(color: AppColors.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Zone de chat
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildZoneChat(MessagerieProvider messagerie) {
    final conv = messagerie.conversationSelectionnee!;
    final messages = messagerie.messagesActuels;

    // Scroller vers le bas quand de nouveaux messages arrivent
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryFixed,
                child: Text(
                  conv.entreprise.nom.isNotEmpty
                      ? conv.entreprise.nom[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.entreprise.nom,
                    style: AppTextStyles.titleSmall,
                  ),
                  Text(
                    conv.entreprise.email,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _couleurStatut(conv.entreprise.statut).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  conv.entreprise.statut,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _couleurStatut(conv.entreprise.statut),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Aucun message — commencez la conversation',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.outline,
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
                            contenu: msg.contenu,
                            // La plateforme est "moi" (estEnvoyePar = false)
                            estMoi: !msg.estEnvoyeParUser,
                            heure: _formatHeure(msg.dateEnvoi),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
          ),
        ),

        // Zone de saisie
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
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
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
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
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
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.outline,
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
                    ? AppColors.outlineVariant
                    : AppColors.primary,
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

  // ──────────────────────────────────────────────────────────────────────────
  // Panneau info entreprise (droite)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPanneauInfo(MessagerieProvider messagerie) {
    final e = messagerie.conversationSelectionnee!.entreprise;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primaryFixed,
              child: Text(
                e.nom.isNotEmpty
                    ? e.nom[0].toUpperCase()
                    : '?',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(e.nom, style: AppTextStyles.titleSmall),
            if (e.nomGerant.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                e.nomGerant,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _infoLigne(Icons.email_outlined, e.email),
            if (e.telephone.isNotEmpty)
              _infoLigne(Icons.phone_outlined, e.telephone),
            if (e.adressePhysique.isNotEmpty)
              _infoLigne(Icons.location_on_outlined, e.adressePhysique),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _couleurStatut(e.statut).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  e.statut,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _couleurStatut(e.statut),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLigne(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Utilitaires
  // ──────────────────────────────────────────────────────────────────────────

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'EN COURS':
        return AppColors.primary;
      case 'ATTENTE DOCS':
        return AppColors.tertiary;
      case 'COMPLET':
        return AppColors.success;
      default:
        return AppColors.outline;
    }
  }

  bool _memJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (_memJour(d, now)) return "Aujourd'hui";
    if (_memJour(d, now.subtract(const Duration(days: 1)))) return 'Hier';
    const mois = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${d.day} ${mois[d.month - 1]} ${d.year}';
  }

  String _formatHeure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─── Widget : Contact entreprise (sidebar) ────────────────────────────────

class _EntrepriseContactItem extends StatelessWidget {
  final String raisonSociale;
  final String? dernierMessage;
  final DateTime? dateEnvoi;
  final bool estEnvoyeParUser;
  final bool aDesNonLus;
  final bool selected;
  final VoidCallback onTap;

  const _EntrepriseContactItem({
    required this.raisonSociale,
    this.dernierMessage,
    this.dateEnvoi,
    this.estEnvoyeParUser = true,
    required this.aDesNonLus,
    required this.selected,
    required this.onTap,
  });

  String _formatageTemps(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryFixed.withValues(alpha: 0.3)
              : Colors.transparent,
          border: selected
              ? const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: selected
                  ? AppColors.primary
                  : AppColors.surfaceContainerHighest,
              child: Text(
                raisonSociale.isNotEmpty
                    ? raisonSociale[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
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
                          ? AppColors.primary
                          : (aDesNonLus ? AppColors.onSurface : AppColors.onSurface),
                    ),
                  ),
                  if (dernierMessage != null)
                    Text(
                      '${estEnvoyeParUser ? "" : "Vous : "}$dernierMessage',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: selected 
                            ? AppColors.primary.withValues(alpha: 0.8) 
                            : (aDesNonLus ? AppColors.onSurface : AppColors.onSurfaceVariant),
                        fontWeight: (aDesNonLus || (estEnvoyeParUser && !selected))
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    )
                  else
                    Text(
                      'Aucun message',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            if (dateEnvoi != null)
              Text(
                _formatageTemps(dateEnvoi),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget : Bulle de message ────────────────────────────────────────────

class _BubbleMessage extends StatelessWidget {
  final String contenu;
  final bool estMoi; // true = message plateforme (droite), false = client (gauche)
  final String heure;

  const _BubbleMessage({
    required this.contenu,
    required this.estMoi,
    required this.heure,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceContainer,
              child: const Icon(
                Icons.business,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
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
                  gradient: estMoi ? AppColors.primaryGradient : null,
                  color: estMoi
                      ? null
                      : AppColors.surfaceContainerLowest,
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
                child: Text(
                  contenu,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: estMoi ? Colors.white : AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                heure,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
          if (estMoi) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryFixed,
              child: const Icon(
                Icons.support_agent,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
