import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/tools_controller.dart';
import '../../models/status_item_model.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/video_thumbnail_widget.dart';
import '../player/custom_video_player_screen.dart';

class StatusSaverScreen extends StatefulWidget {
  const StatusSaverScreen({super.key});

  @override
  State<StatusSaverScreen> createState() => _StatusSaverScreenState();
}

class _StatusSaverScreenState extends State<StatusSaverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsController>(context, listen: false).loadStatuses();
    });
  }

  void _playStatusVideo(StatusItemModel status) {
    final videoModel = VideoModel(
      id: status.id,
      title: status.title,
      path: status.path,
      folderName: status.source == StatusAppSource.whatsappBusiness
          ? 'WA Business Status'
          : 'WhatsApp Status',
      durationMs: 30000,
      sizeBytes: status.size,
      dateModified: status.modifiedDate.millisecondsSinceEpoch,
      resolution: 'Status Video HD',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomVideoPlayerScreen(video: videoModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolsCtrl = Provider.of<ToolsController>(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Saver',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Text(
                  'WhatsApp & WA Business Media',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentEmerald,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentEmerald),
            tooltip: 'Refresh Statuses',
            onPressed: () => toolsCtrl.loadStatuses(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Clear Informative Header Card (No trademarked logo assets)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B).withOpacity(0.55), const Color(0xFF0F172A)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentEmerald.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentEmerald,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.downloading_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save Photo & Video Statuses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View any WhatsApp / WA Business status once, then tap here to watch or save in HD.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Source Filter: WhatsApp vs WhatsApp Business
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                _buildSourceChip(
                  label: 'WhatsApp',
                  isSelected: toolsCtrl.selectedSource == StatusAppSource.whatsapp,
                  onTap: () => toolsCtrl.setSelectedStatusSource(StatusAppSource.whatsapp),
                ),
                const SizedBox(width: 10),
                _buildSourceChip(
                  label: 'WA Business',
                  isSelected: toolsCtrl.selectedSource == StatusAppSource.whatsappBusiness,
                  onTap: () => toolsCtrl.setSelectedStatusSource(StatusAppSource.whatsappBusiness),
                ),
                const Spacer(),
                Text(
                  '${toolsCtrl.statuses.length} found',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),

          // Storage Permission Warning Banner (if Android 11+ manage permission is missing)
          if (!toolsCtrl.hasManagePermission)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryViolet.withOpacity(isDark ? 0.2 : 0.1),
                    const Color(0xFFF59E0B).withOpacity(isDark ? 0.15 : 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_open_rounded, color: Color(0xFFF59E0B), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Permission Required',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Allow All Files Access to view cached WhatsApp status files',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => toolsCtrl.requestManagePermissionAndReload(),
                    child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: toolsCtrl.isLoadingStatuses
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentEmerald))
                : toolsCtrl.statuses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentEmerald.withOpacity(0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppTheme.accentEmerald,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Statuses Found Yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. Open WhatsApp & view your contacts\' statuses\n2. Statuses are cached automatically on your phone\n3. Return here and tap "Refresh"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary(context),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!toolsCtrl.hasManagePermission)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.security_update_good_rounded, size: 18),
                                    label: const Text('Grant Storage Permission', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryViolet,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () => toolsCtrl.requestManagePermissionAndReload(),
                                  ),
                                ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Refresh Statuses', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accentEmerald,
                                  side: const BorderSide(color: AppTheme.accentEmerald, width: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => toolsCtrl.loadStatuses(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.accentEmerald,
                        onRefresh: () => toolsCtrl.loadStatuses(),
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: toolsCtrl.statuses.length,
                          itemBuilder: (context, index) {
                            final status = toolsCtrl.statuses[index];
                            return _buildStatusItemCard(status, toolsCtrl);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentEmerald : AppTheme.card(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.accentEmerald : AppTheme.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItemCard(StatusItemModel status, ToolsController toolsCtrl) {
    final isVideo = status.mediaType == StatusMediaType.video;

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          _playStatusVideo(status);
        } else {
          _showStatusPreviewDialog(status, toolsCtrl);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              VideoThumbnailWidget(
                videoPath: status.path,
                fit: BoxFit.cover,
              )
            else
              Image.file(
                File(status.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surface(context),
                  child: Center(
                    child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted(context), size: 36),
                  ),
                ),
              ),

            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ),

            if (isVideo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded, color: AppTheme.secondaryCyan, size: 14),
                      SizedBox(width: 4),
                      Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      iconSize: 20,
                      icon: Icon(
                        status.isSaved ? Icons.check_circle_rounded : Icons.file_download_rounded,
                        color: status.isSaved ? AppTheme.accentEmerald : Colors.white,
                      ),
                      tooltip: status.isSaved ? 'Saved to Gallery' : 'Save Status',
                      onPressed: () async {
                        await toolsCtrl.saveStatus(status);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to Gallery (/Pictures/RoxPlayer_Status/)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      iconSize: 20,
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      tooltip: 'Share',
                      onPressed: () => toolsCtrl.shareStatus(status),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPreviewDialog(StatusItemModel status, ToolsController toolsCtrl) {
    final isVideo = status.mediaType == StatusMediaType.video;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: double.infinity,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isVideo)
                        AspectRatio(
                          aspectRatio: 9 / 16,
                          child: VideoThumbnailWidget(
                            videoPath: status.path,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        Image.file(
                          File(status.path),
                          fit: BoxFit.contain,
                        ),
                      if (isVideo)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _playStatusVideo(status);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVideo) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Play Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _playStatusVideo(status);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    icon: Icon(
                      status.isSaved ? Icons.check_circle_rounded : Icons.download_rounded,
                      size: 20,
                    ),
                    label: Text(status.isSaved ? 'Saved' : 'Save to Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await toolsCtrl.saveStatus(status);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to Gallery!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      toolsCtrl.shareStatus(status);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
