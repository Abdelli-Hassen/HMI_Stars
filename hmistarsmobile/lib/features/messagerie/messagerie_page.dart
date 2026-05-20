import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import 'widgets/message_bubble.dart';
import 'widgets/document_type_picker.dart';
import 'widgets/company_info_sheet.dart';
import 'widgets/documents_sheet.dart';
import 'widgets/document_scanner_view.dart';
import 'package:image_picker/image_picker.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({super.key});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

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
    _textController.clear();
    _scrollToBottom();
    try {
      await appState.addMessage(
        Message(
          id: '',
          entrepriseId: entrepriseId,
          contenu: text,
          dateEnvoi: DateTime.now(),
          estEnvoyePar: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'envoyer le message : $e')),
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
      if (pickedFile != null) {
        await _promptDocumentType(
          filename: pickedFile.name,
          path: pickedFile.path,
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
    
    _scrollToBottom();
    try {
      await appState.addMessage(
        Message(
          id: '',
          entrepriseId: entrepriseId,
          contenu: filename,
          dateEnvoi: DateTime.now(),
          estEnvoyePar: true,
          fichierNom: filename,
          fichierUrl: path,
          typeDocument: type,
          estFichier: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'envoi du fichier : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final messages = appState.messages;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // HMI Stars profile photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 80,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HMI Stars',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'En ligne',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.green),
                  ),
                ],
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
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length + (appState.hasMoreMessages ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (idx == messages.length) {
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

                final msg = messages[idx];
                final showDate = idx == messages.length - 1 ||
                    !_isSameDay(messages[idx + 1].dateEnvoi, msg.dateEnvoi);
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
              _formatDate(date),
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
                  hintText: 'Écrire un message...',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return "Aujourd'hui";
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Hier';
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
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
              'Choisir une option',
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
            title: 'Prendre une photo',
            subtitle: 'Envoyer directement la photo',
            value: 'photo',
          ),
          _buildOption(
            context,
            icon: Icons.document_scanner,
            title: 'Scanner un document',
            subtitle: 'Détecter et convertir en PDF (style CamScanner)',
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


