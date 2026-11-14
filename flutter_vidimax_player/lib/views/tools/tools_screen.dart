import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/tools_controller.dart';
import '../../controllers/video_controller.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/video_thumbnail_widget.dart';
import '../vault/vault_screen.dart';

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
          indicatorColor: AppTheme.accent(context),
          labelColor: AppTheme.accent(context),
          unselectedLabelColor: AppTheme.textMuted(context),
          tabs: const [
            Tab(icon: Icon(Icons.music_note_rounded), text: 'Video to MP3'),
            Tab(icon: Icon(Icons.lock_person_rounded), text: 'Secret Vault'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideoToMp3View(),
          const VaultScreen(embedded: true),
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
                colors: [Color(0xFF27272A), Color(0xFF09090B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
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
          Text(
            '1. Select Video',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedVideoForMp3 == null)
            InkWell(
              onTap: () => _pickVideoModal(videoCtrl),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      color: AppTheme.accent(context),
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose video to extract',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to browse device videos with thumbnails',
                            style: TextStyle(
                              color: AppTheme.textMuted(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted(context)),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent(context).withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
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
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
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
                                color: AppTheme.accent(context).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedVideoForMp3!.formattedDuration,
                                style: TextStyle(
                                  color: AppTheme.accent(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedVideoForMp3!.formattedSize,
                              style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
                            ),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: AppTheme.textMuted(context), fontSize: 10)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedVideoForMp3!.folderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
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
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 16, color: AppTheme.textPrimary(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
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
          Text(
            '2. Select Audio Bitrate Quality',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textPrimary(context),
            ),
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
                        color: isSel ? AppTheme.accent(context) : AppTheme.card(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppTheme.accent(context) : AppTheme.border(context),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$bitrate kbps',
                            style: TextStyle(
                              color: isSel ? AppTheme.onAccent(context) : AppTheme.textPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bitrate == 320 ? 'HD Studio' : (bitrate == 192 ? 'Standard' : 'Compact'),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel
                                  ? AppTheme.onAccent(context).withOpacity(0.75)
                                  : AppTheme.textMuted(context),
                            ),
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
              color: AppTheme.accent(context),
              backgroundColor: AppTheme.border(context),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Extracting audio... ${(toolsCtrl.conversionProgress * 100).toInt()}%',
                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
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
                  backgroundColor: AppTheme.accent(context),
                  foregroundColor: AppTheme.onAccent(context),
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
                            const SnackBar(content: Text('Audio extracted and saved to /Music/RoxPlayer/')),
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

    final isDark = AppTheme.isDark(context);
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
          colors: isDark
              ? [AppTheme.cardDark, const Color(0xFF222228)]
              : [Colors.white, const Color(0xFFF4F4F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent(context).withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
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
              Expanded(
                child: Text(
                  'Extracted Audio Ready',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.share_rounded, color: AppTheme.textPrimary(context), size: 22),
                tooltip: 'Share Audio',
                onPressed: () {
                  Share.shareXFiles([XFile(file.path)], text: 'Extracted with Rox Player');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved in /Music/RoxPlayer/ • MP3 Audio',
            style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: () => toolsCtrl.togglePlayExtractedAudio(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent(context),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    toolsCtrl.isPlayingAudio
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppTheme.onAccent(context),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.accent(context),
                        inactiveTrackColor: AppTheme.border(context),
                        thumbColor: AppTheme.accent(context),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 3,
                        overlayColor: AppTheme.accent(context).withOpacity(0.2),
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
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11),
                          ),
                          Text(
                            duration.inMilliseconds > 0 ? formatDuration(duration) : '--:--',
                            style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.stop_rounded, color: AppTheme.textMuted(context), size: 24),
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
      backgroundColor: AppTheme.surface(context),
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
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border(ctx),
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
                          Text(
                            'Select Video to Extract',
                            style: TextStyle(
                              color: AppTheme.textPrimary(ctx),
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${videos.length} videos available on device',
                            style: TextStyle(
                              color: AppTheme.textMuted(ctx),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary(ctx)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(color: AppTheme.border(ctx), height: 1),
                Expanded(
                  child: videos.isEmpty
                      ? Center(
                          child: Text(
                            'No videos found on device',
                            style: TextStyle(color: AppTheme.textMuted(ctx)),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: videos.length,
                          separatorBuilder: (_, __) => Divider(
                            color: AppTheme.border(ctx),
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
                                  color: isSelected ? AppTheme.accent(ctx) : AppTheme.textPrimary(ctx),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${v.formattedSize} • ${v.folderName}',
                                  style: TextStyle(color: AppTheme.textMuted(ctx), fontSize: 11),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle_rounded, color: AppTheme.accent(ctx))
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
}
