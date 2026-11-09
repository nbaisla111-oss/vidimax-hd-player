import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/video_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../models/video_model.dart';
import '../../models/folder_model.dart';
import '../../utils/app_theme.dart';
import '../player/custom_video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showFolders = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoCtrl = Provider.of<VideoController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryViolet, AppTheme.secondaryCyan],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              videoCtrl.selectedFolder ?? 'VidiMax HD',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          if (videoCtrl.selectedFolder != null)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => videoCtrl.selectFolder(null),
              tooltip: 'Clear folder filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => videoCtrl.loadVideos(),
            tooltip: 'Rescan storage',
          ),
          PopupMenuButton<VideoSortMode>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            onSelected: (mode) => videoCtrl.setSortMode(mode),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: VideoSortMode.dateDesc,
                child: Text('Date (Newest First)'),
              ),
              const PopupMenuItem(
                value: VideoSortMode.nameAsc,
                child: Text('Name (A to Z)'),
              ),
              const PopupMenuItem(
                value: VideoSortMode.sizeDesc,
                child: Text('Size (Largest First)'),
              ),
              const PopupMenuItem(
                value: VideoSortMode.durationDesc,
                child: Text('Duration (Longest First)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (q) => videoCtrl.setSearchQuery(q),
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search offline videos...',
                      hintStyle: TextStyle(
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondaryLight,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondaryLight,
                        size: 20,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                videoCtrl.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Toggle All Videos vs Folders
                Row(
                  children: [
                    _buildFilterChip(
                      label: 'All Videos (${videoCtrl.videos.length})',
                      isSelected: !_showFolders,
                      onTap: () {
                        setState(() => _showFolders = false);
                        videoCtrl.selectFolder(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Folders (${videoCtrl.folders.length})',
                      isSelected: _showFolders,
                      onTap: () => setState(() => _showFolders = true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: videoCtrl.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
                : _showFolders && videoCtrl.selectedFolder == null
                    ? _buildFoldersGrid(videoCtrl)
                    : _buildVideosList(videoCtrl),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryViolet : AppTheme.borderDark,
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

  Widget _buildFoldersGrid(VideoController videoCtrl) {
    if (videoCtrl.folders.isEmpty) {
      return const Center(child: Text('No folders with videos found'));
    }

    final folderList = videoCtrl.folders.values.toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const dynamicDelegate(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: folderList.length,
      itemBuilder: (context, index) {
        final folder = folderList[index];
        return InkWell(
          onTap: () {
            setState(() => _showFolders = false);
            videoCtrl.selectFolder(folder.name);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppTheme.primaryViolet,
                    size: 28,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${folder.count} videos · ${folder.formattedTotalSize}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosList(VideoController videoCtrl) {
    if (videoCtrl.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: AppTheme.textMutedDark),
            const SizedBox(height: 16),
            const Text(
              'No videos found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap refresh to scan storage or check folder permissions',
              style: TextStyle(fontSize: 12, color: AppTheme.textMutedDark),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: videoCtrl.videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final video = videoCtrl.videos[index];
        return _buildVideoCard(video, videoCtrl);
      },
    );
  }

  Widget _buildVideoCard(VideoModel video, VideoController videoCtrl) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomVideoPlayerScreen(video: video),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          children: [
            // Thumbnail preview with duration badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 110,
                    height: 72,
                    color: AppTheme.surfaceDark,
                    child: video.thumbnailPath != null
                        ? Image.file(
                            File(video.thumbnailPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.movie_rounded, color: AppTheme.textMutedDark),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.play_circle_fill_rounded, color: AppTheme.primaryViolet, size: 32),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.formattedDuration,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${video.formattedSize} · ${video.folderName} · ${video.resolution}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
            // Context Action Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMutedDark, size: 20),
              onSelected: (action) {
                if (action == 'vault') {
                  final vaultCtrl = Provider.of<VaultController>(context, listen: false);
                  if (vaultCtrl.isUnlocked) {
                    vaultCtrl.hideVideo(video);
                    videoCtrl.removeVideoLocally(video.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video securely moved to Private Vault')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please unlock Private Vault first in the Vault tab')),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Play Video'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'vault',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.primaryViolet),
                      SizedBox(width: 8),
                      Text('Move to Secret Vault'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Video Properties'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
