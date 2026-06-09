import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';
import 'widgets/message_bubble.dart';
import 'widgets/document_type_picker.dart';
import 'widgets/company_info_sheet.dart';
import 'widgets/documents_sheet.dart';
import 'widgets/document_scanner_view.dart';
import 'widgets/photo_enhance_view.dart';
import '../../core/widgets/top_notification_banner.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/translation_extension.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({super.key});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  Widget _buildAvatar(String? url, String initials, {double radius = 24, bool isSelected = false}) {
    if (url != null && url.isNotEmpty && !url.contains('dicebear.com')) {
      final cleanUrl = url.split('?').first;
      final isSvg = cleanUrl.endsWith('.svg') || url.contains('.svg');
      
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: isSvg
              ? SvgPicture.network(
                  url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.person, color: Colors.grey[400]),
                  ),
                )
              : Image.network(
                  url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Text(initials),
                  ),
                ),
        ),
      );
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.tertiary
          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Text(
        initials,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showChat = false;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedPlatformContact;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Dans une ListView reverse, maxScrollExtent est le HAUT de la liste (messages plus anciens)
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !context.read<AppState>().isLoadingMoreMessages) {
      context.read<AppState>().loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final appState = context.read<AppState>();
    final entrepriseId = appState.entrepriseId ?? '';
    final allCompanies = appState.allEntreprises;
    final isClient = allCompanies.length <= 1;
    final activeContactId = isClient
        ? (_selectedPlatformContact?['id'] as String?)
        : appState.currentUserId;

    _textController.clear();
    _scrollToBottom();
    try {
      await appState.addMessage(
        Message(
          id: '',
          entrepriseId: entrepriseId,
          contenu: text,
          dateEnvoi: DateTime.now(),
          estEnvoyePar: isClient,
          contactId: activeContactId,
        ),
      );
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          '${context.trStatic('Impossible d\'envoyer le message', 'Failed to send message')} : $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await fp.FilePicker.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    
    final filenames = result.files.map((f) => f.name).join(',');
    final paths = result.files.map((f) => f.path ?? '').join(',');
    
    await _promptDocumentType(
      filename: filenames,
      path: paths,
    );
  }

  Future<void> _takePhoto() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoOptionsSheet(),
    );

    if (option == 'photo') {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null && mounted) {
        // Route through PhotoEnhanceView so user can apply filters before sending
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoEnhanceView(
              imagePath: pickedFile.path,
              onPhotoConfirmed: (finalPath) async {
                Navigator.pop(context);
                await _promptDocumentType(
                  filename: finalPath.split('/').last,
                  path: finalPath,
                );
              },
            ),
          ),
        );
      }
    } else if (option == 'scan') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentScannerView(
            onScanCompleted: (pdfPath) async {
              final fileName = pdfPath.split('/').last;
              await _promptDocumentType(
                filename: fileName,
                path: pdfPath,
                isPdf: true,
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _promptDocumentType({
    required String filename,
    String? path,
    bool isPdf = false,
  }) async {
    final type = await showModalBottomSheet<TypeDocument>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const DocumentTypePicker(),
    );
    if (type == null || !mounted) return;
    final appState = context.read<AppState>();
    final entrepriseId = appState.entrepriseId ?? '';
    final allCompanies = appState.allEntreprises;
    final isClient = allCompanies.length <= 1;
    final activeContactId = isClient
        ? (_selectedPlatformContact?['id'] as String?)
        : appState.currentUserId;
    
    _scrollToBottom();
    try {
      await appState.addMessage(
        Message(
          id: '',
          entrepriseId: entrepriseId,
          contenu: filename,
          dateEnvoi: DateTime.now(),
          estEnvoyePar: isClient,
          fichierNom: filename,
          fichierUrl: path,
          typeDocument: type,
          estFichier: true,
          contactId: activeContactId,
        ),
      );
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          '${context.trStatic('Échec de l\'envoi du fichier', 'Failed to send file')} : $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final messages = appState.messages;
    final allCompanies = appState.allEntreprises;
    final currentCompany = appState.parametres;

    final isClient = allCompanies.length <= 1;
    final activeContactId = isClient
        ? (_selectedPlatformContact?['id'] as String?)
        : appState.currentUserId;

    final filteredChatMessages = messages.where((msg) {
      if (activeContactId == null) return true;
      return msg.contactId == null || msg.contactId == activeContactId;
    }).toList();

    final shouldShowChat = (isClient && _selectedPlatformContact != null) || (!isClient && _showChat);

    if (!shouldShowChat) {
      // Search results filtering
      final List<dynamic> filteredContacts = isClient
          ? appState.platformContacts.where((u) {
              final nom = u['nom'] as String? ?? '';
              return nom.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList()
          : allCompanies.where((c) {
              return c.raisonSociale.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            isClient
                ? context.tr('Support HMI Stars', 'HMI Stars Support')
                : context.tr('Sélectionner un contact client', 'Select client contact'),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: context.tr('Rechercher un contact...', 'Search contact...'),
                    hintStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            // Contact List
            Expanded(
              child: filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isClient ? Icons.people_outline : Icons.business,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Aucun contact trouvé', 'No contact found'),
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredContacts.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 72,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      itemBuilder: (context, index) {
                        final dynamic item = filteredContacts[index];

                        if (isClient) {
                          // Renders platform contact user (Map<String, dynamic>)
                          final contact = item as Map<String, dynamic>;
                          final nom = contact['nom'] as String? ?? 'Utilisateur';
                          final role = contact['role'] as String? ?? '';
                          final isSelected = _selectedPlatformContact?['id'] == contact['id'];

                          final initials = nom.isNotEmpty
                              ? nom.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
                              : '?';

                          return ListTile(
                            leading: _buildAvatar(
                              contact['avatar_url'] as String?,
                              initials,
                              isSelected: isSelected,
                            ),
                            title: Text(
                              nom,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              role == 'admin'
                                  ? context.tr('Administrateur', 'Administrator')
                                  : context.tr('Secrétaire', 'Secretary'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            onTap: () {
                              setState(() {
                                    _selectedPlatformContact = contact;
                              });
                            },
                          );
                        } else {
                          // Renders Client Company (ClientParametres)
                          final comp = item as ClientParametres;
                          final isSelected = comp.id == currentCompany?.id;

                          final initials = comp.raisonSociale.isNotEmpty
                              ? comp.raisonSociale.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
                              : '?';

                          return ListTile(
                            leading: _buildAvatar(
                              comp.logoUrl,
                              initials,
                              isSelected: isSelected,
                            ),
                            title: Text(
                              comp.raisonSociale,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              comp.nomGerant?.isNotEmpty == true
                                  ? '${context.tr('Gérant', 'Manager')}: ${comp.nomGerant}'
                                  : comp.email ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            onTap: () async {
                              await appState.switchEntreprise(comp);
                              setState(() {
                                    _showChat = true;
                              });
                            },
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            setState(() {
              if (isClient) {
                _selectedPlatformContact = null;
              } else {
                _showChat = false;
              }
            });
          },
        ),
        title: isClient
            ? Row(
                children: [
                  _buildAvatar(
                    _selectedPlatformContact?['avatar_url'] as String?,
                    _selectedPlatformContact?['nom'] != null
                        ? (_selectedPlatformContact!['nom'] as String).trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
                        : 'HMI',
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPlatformContact?['nom'] ?? 'HMI Stars Consulting',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _selectedPlatformContact?['role'] == 'admin'
                              ? context.tr('Administrateur', 'Administrator')
                              : context.tr('Secrétaire', 'Secretary'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  _buildAvatar(
                    currentCompany?.logoUrl,
                    currentCompany?.raisonSociale != null
                        ? currentCompany!.raisonSociale.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
                        : 'HMI',
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentCompany?.raisonSociale ?? 'HMI Stars',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          // Documents button
          IconButton(
            icon: Icon(
              Icons.folder_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const DocumentsSheet(),
            ),
          ),
          // Info button
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const CompanyInfoSheet(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filteredChatMessages.length + (appState.hasMoreMessages ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (idx == filteredChatMessages.length) {
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

                final msg = filteredChatMessages[idx];
                final showDate = idx == filteredChatMessages.length - 1 ||
                    !_isSameDay(filteredChatMessages[idx + 1].dateEnvoi, msg.dateEnvoi);
                return Column(
                  children: [
                    if (showDate) _buildDateSeparator(msg.dateEnvoi),
                    MessageBubble(message: msg),
                  ],
                );
              },
            ),
          ),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(context, date),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // File picker
          _buildIconBtn(Icons.attach_file, _pickFile),
          const SizedBox(width: 4),
          // Camera
          _buildIconBtn(Icons.camera_alt_outlined, _takePhoto),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: context.tr('Écrire un message...', 'Write a message...'),
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _sendTextMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return context.tr("Aujourd'hui", "Today");
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return context.tr('Hier', 'Yesterday');
    final isEn = context.read<AppState>().langue == 'English (EN)';
    final months = isEn
        ? const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : const ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Photo options bottom sheet
class _PhotoOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              context.trStatic('Choisir une option', 'Choose an option'),
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            icon: Icons.photo_camera,
            title: context.trStatic('Prendre une photo', 'Take a photo'),
            subtitle: context.trStatic('Envoyer directement la photo', 'Send photo directly'),
            value: 'photo',
          ),
          _buildOption(
            context,
            icon: Icons.document_scanner,
            title: context.trStatic('Scanner un document', 'Scan a document'),
            subtitle: context.trStatic('Détecter et convertir en PDF (style CamScanner)', 'Detect and convert to PDF (CamScanner style)'),
            value: 'scan',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }
}


