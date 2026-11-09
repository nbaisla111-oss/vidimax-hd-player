import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/tools_controller.dart';
import '../../controllers/video_controller.dart';
import '../../models/status_item_model.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoModel? _selectedVideoForMp3;
  int _selectedBitrate = 192;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ToolsController>(context, listen: false).loadStatuses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Utilities', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryViolet,
          labelColor: AppTheme.primaryViolet,
          unselectedLabelColor: AppTheme.textMutedDark,
          tabs: const [
            Tab(icon: Icon(Icons.music_note_rounded), text: 'Video to MP3'),
            Tab(icon: Icon(Icons.download_for_offline_rounded), text: 'Status Saver'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideoToMp3View(),
          _buildStatusSaverView(),
        ],
      ),
    );
  }

  Widget _buildVideoToMp3View() {
    final toolsCtrl = Provider.of<ToolsController>(context);
    final videoCtrl = Provider.of<VideoController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.audiotrack_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video to MP3 Extractor',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Extract crisp 320kbps MP3 audio tracks directly to your Music folder',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '1. Select Video',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickVideoModal(videoCtrl),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedVideoForMp3 != null ? Icons.check_circle_rounded : Icons.video_file_rounded,
                    color: _selectedVideoForMp3 != null ? AppTheme.accentEmerald : AppTheme.primaryViolet,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedVideoForMp3 != null ? _selectedVideoForMp3!.title : 'Tap to choose video from device',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedVideoForMp3 != null ? Colors.white : AppTheme.textMutedDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '2. Select Audio Bitrate Quality',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [128, 192, 320].map((bitrate) {
              final isSel = _selectedBitrate == bitrate;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedBitrate = bitrate),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primaryViolet.withOpacity(0.2) : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppTheme.primaryViolet : AppTheme.borderDark,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$bitrate kbps',
                            style: TextStyle(
                              color: isSel ? AppTheme.primaryViolet : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bitrate == 320 ? 'HD Studio' : (bitrate == 192 ? 'Standard' : 'Compact'),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMutedDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          if (toolsCtrl.isConverting) ...[
            LinearProgressIndicator(
              value: toolsCtrl.conversionProgress,
              color: AppTheme.primaryViolet,
              backgroundColor: AppTheme.borderDark,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Extracting audio... ${(toolsCtrl.conversionProgress * 100).toInt()}%',
                style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Convert & Extract MP3', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _selectedVideoForMp3 == null
                    ? null
                    : () async {
                        await toolsCtrl.extractAudio(
                          videoPath: _selectedVideoForMp3!.path,
                          outputName: '${_selectedVideoForMp3!.title}_$_selectedBitrate.mp3',
                          bitrate: _selectedBitrate,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio extracted and saved to /Music/VidiMax/')),
                          );
                        }
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _pickVideoModal(VideoController videoCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView.builder(
          itemCount: videoCtrl.videos.length,
          itemBuilder: (context, idx) {
            final v = videoCtrl.videos[idx];
            return ListTile(
              title: Text(v.title, maxLines: 1, style: const TextStyle(color: Colors.white)),
              subtitle: Text(v.formattedSize, style: const TextStyle(color: AppTheme.textMutedDark)),
              onTap: () {
                setState(() => _selectedVideoForMp3 = v);
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusSaverView() {
    final toolsCtrl = Provider.of<ToolsController>(context);

    return Column(
      children: [
        // Source Filter: WhatsApp vs WhatsApp Business
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildSourceChip(
                label: 'WhatsApp',
                isSelected: toolsCtrl.selectedSource == StatusAppSource.whatsapp,
                onTap: () => toolsCtrl.setSelectedStatusSource(StatusAppSource.whatsapp),
              ),
              const SizedBox(width: 8),
              _buildSourceChip(
                label: 'WhatsApp Business',
                isSelected: toolsCtrl.selectedSource == StatusAppSource.whatsappBusiness,
                onTap: () => toolsCtrl.setSelectedStatusSource(StatusAppSource.whatsappBusiness),
              ),
            ],
          ),
        ),
        Expanded(
          child: toolsCtrl.isLoadingStatuses
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
              : toolsCtrl.statuses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.whatsapp_rounded, size: 56, color: AppTheme.accentEmerald.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'No WhatsApp Statuses Found',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Open WhatsApp and view statuses to cache them first',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMutedDark),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const dynamicDelegate(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
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
      ],
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
          color: isSelected ? AppTheme.accentEmerald : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.accentEmerald : AppTheme.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItemCard(StatusItemModel status, ToolsController toolsCtrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media Placeholder or thumbnail
          Container(
            color: AppTheme.surfaceDark,
            child: Icon(
              status.mediaType == StatusMediaType.video ? Icons.movie_rounded : Icons.image_rounded,
              color: AppTheme.textMutedDark,
              size: 44,
            ),
          ),
          // Action Buttons at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
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
                    onPressed: () => toolsCtrl.saveStatus(status),
                  ),
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: () => toolsCtrl.shareStatus(status),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class dynamicDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  const dynamicDelegate({
    required super.crossAxisCount,
    super.mainAxisSpacing,
    super.crossAxisSpacing,
    super.childAspectRatio,
  });
}
