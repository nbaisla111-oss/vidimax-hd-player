import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/music_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../models/music_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/audio_artwork_widget.dart';
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
                style: TextStyle(color: AppTheme.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, folders...',
                  hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary(context)),
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
                      color: AppTheme.accent(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.music_note_rounded, color: AppTheme.onAccent(context), size: 20),
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
          indicatorColor: AppTheme.accent(context),
          labelColor: AppTheme.accent(context),
          unselectedLabelColor: AppTheme.textMuted(context),
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
              color: AppTheme.accent(context).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.folder_open_rounded, size: 18, color: AppTheme.accent(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Folder: ${musicCtrl.selectedFolder}',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => musicCtrl.setSelectedFolder(null),
                    child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary(context)),
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
      return Center(child: CircularProgressIndicator(color: AppTheme.accent(context)));
    }

    final songs = musicCtrl.songs;
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded, size: 64, color: AppTheme.textMuted(context).withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'No audio tracks found',
              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Convert videos to MP3 in Tools or add music to your device',
              style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rescan Storage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent(context),
                foregroundColor: AppTheme.onAccent(context),
              ),
              onPressed: () => musicCtrl.scanMusic(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent(context),
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
                backgroundColor: AppTheme.accent(context),
                foregroundColor: AppTheme.onAccent(context),
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
              foregroundColor: AppTheme.textPrimary(context),
              side: BorderSide(color: AppTheme.border(context)),
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
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.accent(context).withOpacity(isDark ? 0.14 : 0.08)
            : AppTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppTheme.accent(context) : AppTheme.border(context),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: AudioArtworkWidget(
          audioPath: song.path,
          size: 46,
          borderRadius: BorderRadius.circular(10),
          isCurrent: isCurrent,
          isPlaying: musicCtrl.isPlaying,
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${song.artist} • ${song.formattedDuration}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? Colors.redAccent : AppTheme.textMuted(context),
                size: 20,
              ),
              onPressed: () => musicCtrl.toggleFavorite(song),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppTheme.textMuted(context), size: 20),
              color: AppTheme.surface(context),
              onSelected: (val) async {
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
                        const SnackBar(content: Text('Please set up your 4-digit PIN in Tools > Secret Vault first')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: AppTheme.textPrimary(ctx), size: 18),
                      const SizedBox(width: 10),
                      Text('Play Now', style: TextStyle(color: AppTheme.textPrimary(ctx))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'vault',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppTheme.accent(ctx), size: 18),
                      const SizedBox(width: 10),
                      Text('Move to Secret Vault', style: TextStyle(color: AppTheme.textPrimary(ctx))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, color: AppTheme.textPrimary(ctx), size: 18),
                      const SizedBox(width: 10),
                      Text('Share Track', style: TextStyle(color: AppTheme.textPrimary(ctx))),
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
      return Center(
        child: Text(
          'No folders found',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
      );
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
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.folder_rounded, color: AppTheme.accent(context), size: 24),
            ),
            title: Text(
              folder,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context), fontSize: 14),
            ),
            subtitle: Text(
              '$count audio tracks',
              style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted(context)),
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
            Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textMuted(context).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No favorite songs yet',
              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any song to add it here',
              style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
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
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = ['Date Added (Newest)', 'Title (A-Z)', 'Duration (Longest)', 'Artist'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sort Tracks By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(ctx)),
                ),
              ),
              ...List.generate(options.length, (idx) {
                final isSelected = musicCtrl.sortOption == idx;
                return ListTile(
                  title: Text(
                    options[idx],
                    style: TextStyle(
                      color: isSelected ? AppTheme.accent(ctx) : AppTheme.textPrimary(ctx),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: AppTheme.accent(ctx))
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
