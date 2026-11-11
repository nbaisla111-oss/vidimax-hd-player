import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../models/music_model.dart';
import '../../utils/app_theme.dart';
import 'mini_music_player.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicCtrl = Provider.of<MusicController>(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, folders...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      _searchCtrl.clear();
                      musicCtrl.setSearchQuery('');
                      setState(() => _showSearch = false);
                    },
                  ),
                ),
                onChanged: (val) => musicCtrl.setSearchQuery(val),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryViolet, AppTheme.secondaryCyan],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Music Player',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ],
              ),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _showSearch = true),
              tooltip: 'Search Songs',
            ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortModal(context, musicCtrl),
            tooltip: 'Sort Options',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => musicCtrl.scanMusic(),
            tooltip: 'Rescan Storage',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryViolet,
          labelColor: AppTheme.primaryViolet,
          unselectedLabelColor: AppTheme.textMutedDark,
          tabs: [
            Tab(text: 'Tracks (${musicCtrl.songs.length})'),
            Tab(text: 'Folders (${musicCtrl.folders.length})'),
            Tab(text: 'Favorites (${musicCtrl.favoriteSongs.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Folder filter badge if active
          if (musicCtrl.selectedFolder != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryViolet.withOpacity(0.12),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Folder: ${musicCtrl.selectedFolder}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => musicCtrl.setSelectedFolder(null),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTracksList(musicCtrl),
                _buildFoldersList(musicCtrl),
                _buildFavoritesList(musicCtrl),
              ],
            ),
          ),

          // Mini Player (Only shown if song is playing or loaded)
          const MiniMusicPlayer(),
        ],
      ),
    );
  }

  Widget _buildTracksList(MusicController musicCtrl) {
    if (musicCtrl.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet));
    }

    final songs = musicCtrl.songs;
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: AppTheme.textMutedDark.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No audio tracks found',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Convert videos to MP3 in Tools or add music to your device',
              style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rescan Storage'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
              onPressed: () => musicCtrl.scanMusic(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryViolet,
      onRefresh: () => musicCtrl.scanMusic(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: songs.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildShuffleHeader(musicCtrl, songs);
          }
          final song = songs[index - 1];
          return _buildSongTile(song, musicCtrl, songs);
        },
      ),
    );
  }

  Widget _buildShuffleHeader(MusicController musicCtrl, List<MusicModel> songs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shuffle_rounded, size: 20),
              label: Text('Shuffle All (${songs.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                if (!musicCtrl.isShuffle) musicCtrl.toggleShuffle();
                musicCtrl.playSong(songs.first, queue: songs);
              },
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Play All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.borderDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              musicCtrl.playSong(songs.first, queue: songs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(MusicModel song, MusicController musicCtrl, List<MusicModel> currentQueue) {
    final isCurrent = musicCtrl.currentSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primaryViolet.withOpacity(0.15) : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryViolet : AppTheme.borderDark,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrent
                  ? [AppTheme.primaryViolet, AppTheme.secondaryCyan]
                  : [const Color(0xFF312E81), const Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isCurrent
                ? (musicCtrl.isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded)
                : Icons.music_note_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? AppTheme.primaryViolet : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${song.artist} • ${song.formattedDuration}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? Colors.redAccent : AppTheme.textMutedDark,
                size: 20,
              ),
              onPressed: () => musicCtrl.toggleFavorite(song),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMutedDark, size: 20),
              color: AppTheme.surfaceDark,
              onSelected: (val) {
                if (val == 'play') {
                  musicCtrl.playSong(song, queue: currentQueue);
                } else if (val == 'share') {
                  if (!song.path.startsWith('http')) {
                    Share.shareXFiles([XFile(song.path)], text: 'Sharing ${song.title}');
                  }
                } else if (val == 'vault') {
                  final vaultCtrl = Provider.of<VaultController>(context, listen: false);
                  if (vaultCtrl.isConfigured) {
                    await vaultCtrl.hideMusic(song);
                    await musicCtrl.scanMusic();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio track moved to Secret Vault')),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please set up your 4-digit PIN in the Vault tab first')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Play Now', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'vault',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppTheme.primaryViolet, size: 18),
                      SizedBox(width: 10),
                      Text('Move to Secret Vault', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Share Track', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          musicCtrl.playSong(song, queue: currentQueue);
        },
      ),
    );
  }

  Widget _buildFoldersList(MusicController musicCtrl) {
    final folders = musicCtrl.folders;
    if (folders.isEmpty) {
      return const Center(child: Text('No folders found', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final count = musicCtrl.songs.where((s) => s.folder == folder).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: AppTheme.primaryViolet, size: 24),
            ),
            title: Text(
              folder,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              '$count audio tracks',
              style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedDark),
            onTap: () {
              musicCtrl.setSelectedFolder(folder);
              _tabController.animateTo(0);
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(MusicController musicCtrl) {
    final favorites = musicCtrl.favoriteSongs;
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textMutedDark.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No favorite songs yet',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart icon on any song to add it here',
              style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        return _buildSongTile(song, musicCtrl, favorites);
      },
    );
  }

  void _showSortModal(BuildContext context, MusicController musicCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = ['Date Added (Newest)', 'Title (A-Z)', 'Duration (Longest)', 'Artist'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sort Tracks By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              ...List.generate(options.length, (idx) {
                final isSelected = musicCtrl.sortOption == idx;
                return ListTile(
                  title: Text(
                    options[idx],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryViolet : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded, color: AppTheme.primaryViolet)
                      : null,
                  onTap: () {
                    musicCtrl.setSortOption(idx);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
