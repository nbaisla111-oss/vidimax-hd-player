import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/tools_controller.dart';
import '../../controllers/video_controller.dart';
import '../../models/status_item_model.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/video_thumbnail_widget.dart';

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
          if (_selectedVideoForMp3 == null)
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
                child: const Row(
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      color: AppTheme.primaryViolet,
                      size: 26,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose video to extract',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to browse device videos with thumbnails',
                            style: TextStyle(
                              color: AppTheme.textMutedDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedDark),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryViolet.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 80,
                      height: 56,
                      child: VideoThumbnailWidget(
                        videoPath: _selectedVideoForMp3!.path,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVideoForMp3!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedVideoForMp3!.formattedDuration,
                                style: const TextStyle(
                                  color: AppTheme.primaryViolet,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedVideoForMp3!.formattedSize,
                              style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 10)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedVideoForMp3!.folderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _pickVideoModal(videoCtrl),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 16, color: AppTheme.secondaryCyan),
                          SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: AppTheme.secondaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
          if (toolsCtrl.lastExtractedAudio != null && !toolsCtrl.isConverting) ...[
            const SizedBox(height: 24),
            _buildExtractedAudioPlayer(toolsCtrl),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedAudioPlayer(ToolsController toolsCtrl) {
    final file = toolsCtrl.lastExtractedAudio;
    if (file == null) return const SizedBox.shrink();

    final fileName = file.path.split(Platform.pathSeparator).last;
    final position = toolsCtrl.audioPosition;
    final duration = toolsCtrl.audioDuration;

    String formatDuration(Duration d) {
      final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$mins:$secs';
    }

    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardDark,
            const Color(0xFF1E1B4B).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.accentEmerald, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Extracted Audio Ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: AppTheme.secondaryCyan, size: 22),
                tooltip: 'Share Audio',
                onPressed: () {
                  Share.shareXFiles([XFile(file.path)], text: 'Extracted with VidiMax HD Player');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saved in /Music/VidiMax/ • MP3 Audio',
            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Audio Player Controls & Slider
          Row(
            children: [
              // Play / Pause Button
              GestureDetector(
                onTap: () => toolsCtrl.togglePlayExtractedAudio(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryViolet, Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryViolet.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    toolsCtrl.isPlayingAudio
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Progress Bar & Timestamps
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryViolet,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 3,
                        overlayColor: AppTheme.primaryViolet.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: currentMs,
                        min: 0.0,
                        max: maxMs,
                        onChanged: (val) {
                          toolsCtrl.seekAudio(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDuration(position),
                            style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
                          ),
                          Text(
                            duration.inMilliseconds > 0 ? formatDuration(duration) : '--:--',
                            style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stop Button
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: AppTheme.textMutedDark, size: 24),
                tooltip: 'Stop',
                onPressed: () => toolsCtrl.stopAudio(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickVideoModal(VideoController videoCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final videos = videoCtrl.videos;
            return Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Video to Extract',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${videos.length} videos available on device',
                            style: const TextStyle(
                              color: AppTheme.textMutedDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.borderDark, height: 1),
                Expanded(
                  child: videos.isEmpty
                      ? const Center(
                          child: Text(
                            'No videos found on device',
                            style: TextStyle(color: AppTheme.textMutedDark),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: videos.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Color(0xFF1E293B),
                            height: 1,
                            indent: 96,
                          ),
                          itemBuilder: (context, idx) {
                            final v = videos[idx];
                            final isSelected = _selectedVideoForMp3?.path == v.path;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: SizedBox(
                                width: 72,
                                height: 48,
                                child: Stack(
                                  children: [
                                    VideoThumbnailWidget(
                                      videoPath: v.path,
                                      width: 72,
                                      height: 48,
                                      borderRadius: BorderRadius.circular(8),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      bottom: 3,
                                      right: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          v.formattedDuration,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                v.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.primaryViolet : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${v.formattedSize} • ${v.folderName}',
                                  style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryViolet)
                                  : null,
                              onTap: () {
                                setState(() => _selectedVideoForMp3 = v);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
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
        // Source Filter: WhatsApp vs WhatsApp Business + Refresh Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryViolet),
                tooltip: 'Refresh Statuses',
                onPressed: () => toolsCtrl.loadStatuses(),
              ),
            ],
          ),
        ),

        // Storage Permission Warning Banner (if Android 11+ manage permission is missing)
        if (!toolsCtrl.hasManagePermission)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.2),
                  const Color(0xFFF59E0B).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_open_rounded, color: Color(0xFFF59E0B), size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Permission Required',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Allow All Files Access to view hidden WhatsApp status files',
                        style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11),
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
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
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
                                color: AppTheme.accentEmerald.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_rounded,
                                size: 48,
                                color: AppTheme.accentEmerald,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No WhatsApp Statuses Found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Open WhatsApp & view your contacts\' statuses\n2. Statuses are cached automatically\n3. Return here and tap "Refresh"',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.textMutedDark, height: 1.5),
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
                              label: const Text('Refresh Statuses'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentEmerald,
                                side: const BorderSide(color: AppTheme.accentEmerald),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => toolsCtrl.loadStatuses(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
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
    final isVideo = status.mediaType == StatusMediaType.video;

    return GestureDetector(
      onTap: () => _showStatusPreviewDialog(status, toolsCtrl),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media Content (Image or Video Thumbnail)
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
                  color: AppTheme.surfaceDark,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppTheme.textMutedDark, size: 36),
                  ),
                ),
              ),

            // Video indicator badge
            if (isVideo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                ),
              ),

            // Action Buttons at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                      tooltip: status.isSaved ? 'Saved to Gallery' : 'Save Status',
                      onPressed: () async {
                        await toolsCtrl.saveStatus(status);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to Gallery (/Pictures/VidiMax_Status/)'),
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
                  child: isVideo
                      ? AspectRatio(
                          aspectRatio: 9 / 16,
                          child: VideoThumbnailWidget(
                            videoPath: status.path,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.file(
                          File(status.path),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      status.isSaved ? Icons.check_circle_rounded : Icons.download_rounded,
                      size: 20,
                    ),
                    label: Text(status.isSaved ? 'Saved' : 'Save to Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
