import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:rpm/main.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _player.onPlayerStateChanged.listen((state) {
      _broadcastState(state);
    });

    _player.onPositionChanged.listen((position) {
      final oldState = playbackState.value;
      playbackState.add(oldState.copyWith(updatePosition: position));
    });

    _player.onDurationChanged.listen((duration) {
      final oldItem = mediaItem.value;
      if (oldItem != null) {
        mediaItem.add(oldItem.copyWith(duration: duration));
      }
    });

    _player.onPlayerComplete.listen((event) {
      MusicService.handleAutoNext();
    });
  }

  void _broadcastState(PlayerState state) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (state == PlayerState.playing)
            MediaControl.pause
          else
            MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          PlayerState.stopped: AudioProcessingState.idle,
          PlayerState.playing: AudioProcessingState.ready,
          PlayerState.paused: AudioProcessingState.ready,
          PlayerState.completed: AudioProcessingState.completed,
        }[state]!,
        playing: state == PlayerState.playing,
      ),
    );
  }

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    MusicService.next();
  }

  @override
  Future<void> skipToPrevious() async {
    MusicService.previous();
  }

  Future<void> playSongFile(Song song) async {
    if (song.filePath == null) return;

    mediaItem.add(
      MediaItem(
        id: song.id.toString(),
        album: song.folderName,
        title: song.title,
        artist: song.artist ?? "???",
        duration: null,
        artUri: song.imagePath != null
            ? (song.imagePath!.startsWith('http')
                ? Uri.parse(song.imagePath!)
                : Uri.file(song.imagePath!))
            : null,
      ),
    );

    try {
      await _player.stop();
      await _player.play(DeviceFileSource(song.filePath!));
    } catch (e) {
      debugPrint("Errore riproduzione background: $e");
    }
  }
}

class MusicService {
  static final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  static final ValueNotifier<Duration> positionNotifier = ValueNotifier(
    Duration.zero,
  );
  static final ValueNotifier<Duration> durationNotifier = ValueNotifier(
    Duration.zero,
  );
  static final ValueNotifier<LoopMode> loopModeNotifier = ValueNotifier(
    LoopMode.none,
  );
  static final ValueNotifier<bool> isShuffleNotifier = ValueNotifier(false);
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static late MyAudioHandler _audioHandler;

  static List<Song> _currentPlaylist = [];
  static List<Song> _originalPlaylist = [];
  static int _currentIndex = -1;

  static bool _hasCountedCurrentPlay = false;
  static Set<int> favoriteFolderIds = {};

  static Future<void> init() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.stefano.ytp.channel.audio',
        androidNotificationChannelName: 'YTP Playback',
        androidNotificationOngoing: true,
      ),
    );

    _audioHandler.playbackState.listen((state) {
      isPlayingNotifier.value = state.playing;
      positionNotifier.value = state.updatePosition;

      if (state.updatePosition.inSeconds >= 10 && !_hasCountedCurrentPlay) {
        final currentTrack = currentTrackNotifier.value;
        if (currentTrack?.id != null) {
          incrementPlayCount(currentTrack!.id!);
          _hasCountedCurrentPlay = true;
        }
      }
    });

    _audioHandler.mediaItem.listen((item) {
      if (item?.duration != null) {
        durationNotifier.value = item!.duration!;
      }
    });

    await database;
    await loadTheme();
    await getFavoriteFolders();
  }

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mp3_app_prod.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  static Future _createDB(Database db, int version) async {
    await db.execute(
      'CREATE TABLE songs (id INTEGER PRIMARY KEY, title TEXT NOT NULL, artist TEXT, folderName TEXT NOT NULL, filePath TEXT, imagePath TEXT, playCount INTEGER DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE folders (id INTEGER PRIMARY KEY, name TEXT NOT NULL, imagePath TEXT, isSpecial INTEGER, mp3SortType INTEGER, isFavorite INTEGER DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)',
    );
  }

  static Future<void> loadTheme() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['theme'],
    );
    if (maps.isNotEmpty) {
      themeNotifier.value = maps.first['value'] == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
  }

  static Future<void> updateTheme(ThemeMode mode) async {
    final db = await database;
    themeNotifier.value = mode;
    String value = (mode == ThemeMode.dark) ? 'dark' : 'light';
    await db.insert(
      'settings',
      {'key': 'theme', 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> toggleTheme() async {
    final newMode = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await updateTheme(newMode);
  }

  static Future<Map<String, String>?> pickSongFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.single;
        return {
          'title': file.name.replaceAll(RegExp(r'\.(mp3|m4a|wav)$'), ''),
          'artist': '???',
          'filePath': file.path!,
        };
      }
    } catch (e) {
      debugPrint("Errore file: $e");
    }
    return null;
  }

  static Future<String?> pickImageFromDevice() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image?.path;
    } catch (e) {
      debugPrint("Errore immagine: $e");
    }
    return null;
  }

  static Future<List<Song>> getSongsInFolder(String folderName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'folderName = ?',
      whereArgs: [folderName],
    );
    return List.generate(
      maps.length,
      (i) => Song(
        id: maps[i]['id'],
        title: maps[i]['title'],
        artist: maps[i]['artist'],
        folderName: maps[i]['folderName'],
        filePath: maps[i]['filePath'],
        imagePath: maps[i]['imagePath'],
        playCount: maps[i]['playCount'],
      ),
    );
  }

  static Future<void> addSong(
    String title,
    String artist,
    String folderName,
    String filePath,
  ) async {
    final db = await database;
    await db.insert('songs', {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'artist': artist,
      'folderName': folderName,
      'filePath': filePath,
      'playCount': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSongImage(int id, String? imagePath) async {
    final db = await database;
    await db.update(
      'songs',
      {'imagePath': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateSongArtist(int id, String artist) async {
    final db = await database;
    await db.update(
      'songs',
      {'artist': artist},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteSong(int id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> renameSong(int id, String newName) async {
    final db = await database;
    await db.update(
      'songs',
      {'title': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> incrementPlayCount(int songId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE songs SET playCount = playCount + 1 WHERE id = ?',
      [songId],
    );
  }

  static Future<void> resetMonthlyStats() async {
    final db = await database;
    await db.update('songs', {'playCount': 0});
  }

  static Future<List<Song>> getTopSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'playCount > 0',
      orderBy: 'playCount DESC',
      limit: 10,
    );
    return List.generate(
      maps.length,
      (i) => Song(
        id: maps[i]['id'],
        title: maps[i]['title'],
        artist: maps[i]['artist'],
        folderName: maps[i]['folderName'],
        imagePath: maps[i]['imagePath'],
        playCount: maps[i]['playCount'],
      ),
    );
  }

  static Future<List<Folder>> getUserFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(
      maps.length,
      (i) => Folder(
        id: maps[i]['id'],
        name: maps[i]['name'],
        imagePath: maps[i]['imagePath'],
        isSpecial: maps[i]['isSpecial'] == 1,
        mp3SortType: SortType.values[maps[i]['mp3SortType'] ?? 0],
      ),
    );
  }

  static Future<List<Folder>> getFavoriteFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'isFavorite = 1',
    );
    final folders = List.generate(
      maps.length,
      (i) => Folder(
        id: maps[i]['id'],
        name: maps[i]['name'],
        imagePath: maps[i]['imagePath'],
        isSpecial: maps[i]['isSpecial'] == 1,
        mp3SortType: SortType.values[maps[i]['mp3SortType'] ?? 0],
      ),
    );
    favoriteFolderIds = folders.map((f) => f.id).toSet();
    return folders;
  }

  static Future<void> toggleFolderFavorite(int folderId) async {
    final db = await database;
    final isFav = favoriteFolderIds.contains(folderId);
    if (isFav) {
      favoriteFolderIds.remove(folderId);
      await db.update(
        'folders',
        {'isFavorite': 0},
        where: 'id = ?',
        whereArgs: [folderId],
      );
    } else {
      favoriteFolderIds.add(folderId);
      await db.update(
        'folders',
        {'isFavorite': 1},
        where: 'id = ?',
        whereArgs: [folderId],
      );
    }
  }

  static Future<void> addUserFolder(String name) async {
    final db = await database;
    await db.insert('folders', {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': name,
      'isSpecial': 0,
      'mp3SortType': 0,
    });
  }

  static Future<void> deleteUserFolder(int id) async {
    final db = await database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
    favoriteFolderIds.remove(id);
  }

  static Future<void> updateUserFolderImage(int id, String? imagePath) async {
    final db = await database;
    await db.update(
      'folders',
      {'imagePath': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Folder>> getRandomUserFolders(int count) async {
    final folders = await getUserFolders();
    final userOnly = folders.where((f) => !f.isSpecial).toList();
    userOnly.shuffle();
    return userOnly.take(count).toList();
  }

  static Future<Folder?> getRandomFavoriteFolder() async {
    final favs = await getFavoriteFolders();
    return favs.isNotEmpty ? favs[Random().nextInt(favs.length)] : null;
  }

  static void playTrack(Song song, List<Song> contextPlaylist) {
    _originalPlaylist = List.from(contextPlaylist);
    if (isShuffleNotifier.value) {
      _currentPlaylist = List.from(contextPlaylist)..shuffle();
    } else {
      _currentPlaylist = List.from(contextPlaylist);
    }

    _currentIndex = _currentPlaylist.indexWhere((s) => s.id == song.id);
    _loadTrack(song);
  }

  static void _loadTrack(Song song) {
    final track = Track(
      title: song.title,
      folderName: song.folderName,
      artist: song.artist,
      id: song.id,
      imagePath: song.imagePath,
    );
    currentTrackNotifier.value = track;
    _hasCountedCurrentPlay = false;

    _audioHandler.playSongFile(song);
  }

  static void eject() {
    _audioHandler.stop();
    resetPosition();
    _currentPlaylist.clear();
    _originalPlaylist.clear();
    _currentIndex = -1;
    _hasCountedCurrentPlay = false;
    isShuffleNotifier.value = false;
    loopModeNotifier.value = LoopMode.none;
    currentTrackNotifier.value = null;
  }

  static void play() => _audioHandler.play();
  static void pause() => _audioHandler.pause();
  static void togglePlayPause() {
    if (isPlayingNotifier.value)
      _audioHandler.pause();
    else
      _audioHandler.play();
  }

  static void seek(Duration position) {
    _audioHandler.seek(position);
    positionNotifier.value = position;
  }

  static void resetPosition() => positionNotifier.value = Duration.zero;

  static void handleAutoNext() {
    if (loopModeNotifier.value == LoopMode.single) {
      _loadTrack(_currentPlaylist[_currentIndex]);
    } else {
      if (hasNext()) {
        next();
      } else {
        pause();
        seek(Duration.zero);
      }
    }
  }

  static bool hasNext() {
    if (_currentPlaylist.isEmpty) return false;
    if (loopModeNotifier.value == LoopMode.playlist) return true;
    return _currentIndex < _currentPlaylist.length - 1;
  }

  static bool hasPrevious() {
    if (_currentPlaylist.isEmpty) return false;
    return true;
  }

  static void next() {
    if (_currentPlaylist.isEmpty) return;
    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _currentPlaylist.length) {
      if (loopModeNotifier.value == LoopMode.playlist) {
        nextIndex = 0;
      } else {
        seek(Duration.zero);
        pause();
        return;
      }
    }
    _currentIndex = nextIndex;
    _loadTrack(_currentPlaylist[_currentIndex]);
  }

  static void previous() {
    if (_currentPlaylist.isEmpty) return;
    
    bool isLastSong = !hasNext() && loopModeNotifier.value == LoopMode.none && _currentIndex == _currentPlaylist.length - 1;

    if (positionNotifier.value.inSeconds > 2.5 || isLastSong) {
      _loadTrack(_currentPlaylist[_currentIndex]);
      return;
    }
    
    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      if (loopModeNotifier.value == LoopMode.playlist) {
        prevIndex = _currentPlaylist.length - 1;
      } else {
        seek(Duration.zero);
        play();
        return;
      }
    }
    _currentIndex = prevIndex;
    _loadTrack(_currentPlaylist[_currentIndex]);
  }

  static void toggleLoop() {
    switch (loopModeNotifier.value) {
      case LoopMode.none:
        loopModeNotifier.value = LoopMode.playlist;
        break;
      case LoopMode.playlist:
        loopModeNotifier.value = LoopMode.single;
        break;
      case LoopMode.single:
        loopModeNotifier.value = LoopMode.none;
        break;
    }
  }

  static void activateSingleLoop() => loopModeNotifier.value = LoopMode.single;

  static void toggleShuffle() {
    isShuffleNotifier.value = !isShuffleNotifier.value;
    if (_currentPlaylist.isEmpty) return;
    final currentSong = _currentPlaylist[_currentIndex];
    if (isShuffleNotifier.value) {
      _currentPlaylist = List.from(_originalPlaylist)..shuffle();
    } else {
      _currentPlaylist = List.from(_originalPlaylist);
    }
    _currentIndex = _currentPlaylist.indexWhere((s) => s.id == currentSong.id);
  }
}