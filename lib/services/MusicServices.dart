import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mp3/main.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MusicService {
  static final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  static final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  static final ValueNotifier<Duration> durationNotifier = ValueNotifier(const Duration(minutes: 3, seconds: 30));

  static final ValueNotifier<LoopMode> loopModeNotifier = ValueNotifier(LoopMode.none);
  static final ValueNotifier<bool> isShuffleNotifier = ValueNotifier(false);

  static List<Song> _currentPlaylist = [];
  static List<Song> _originalPlaylist = [];
  static int _currentIndex = -1;
  static Timer? _playerTimer;
  static bool _hasCountedCurrentPlay = false;

  static Set<int> favoriteFolderIds = {};

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mp3_app_prod.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  static Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE songs (
      id INTEGER PRIMARY KEY,
      title TEXT NOT NULL,
      artist TEXT,
      folderName TEXT NOT NULL,
      filePath TEXT,
      imagePath TEXT,
      playCount INTEGER DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE folders (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      imagePath TEXT,
      isSpecial INTEGER,
      mp3SortType INTEGER,
      isFavorite INTEGER DEFAULT 0
    )
    ''');
  }

  // Selezione file
  static Future<Map<String, String>?> pickSongFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.single;
        return {
          'title': file.name.replaceAll('.mp3', '').replaceAll('.m4a', ''),
          'artist': 'Sconosciuto',
          'filePath': file.path!,
        };
      }
    } catch (e) {
      debugPrint("Errore selezione file: $e");
    }
    return null;
  }

  static Future<String?> pickImageFromDevice() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image?.path;
    } catch (e) {
      debugPrint("Errore selezione immagine: $e");
    }
    return null;
  }

  // Gestione canzoni
  static Future<List<Song>> getSongsInFolder(String folderName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs', where: 'folderName = ?', whereArgs: [folderName]);
    return List.generate(maps.length, (i) => Song(
      id: maps[i]['id'],
      title: maps[i]['title'],
      artist: maps[i]['artist'],
      folderName: maps[i]['folderName'],
      filePath: maps[i]['filePath'],
      imagePath: maps[i]['imagePath'],
      playCount: maps[i]['playCount'],
    ));
  }

  static Future<void> addSong(String title, String artist, String folderName, String filePath) async {
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

  static Future<void> deleteSong(int id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> renameSong(int id, String newName) async {
    final db = await database;
    await db.update('songs', {'title': newName}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> incrementPlayCount(int songId) async {
    final db = await database;
    await db.rawUpdate('UPDATE songs SET playCount = playCount + 1 WHERE id = ?', [songId]);
  }

  static Future<void> resetMonthlyStats() async {
    final db = await database;
    await db.update('songs', {'playCount': 0});
  }

  static Future<List<Song>> getTopSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs', where: 'playCount > 0', orderBy: 'playCount DESC', limit: 10);
    return List.generate(maps.length, (i) => Song(
      id: maps[i]['id'],
      title: maps[i]['title'],
      artist: maps[i]['artist'],
      folderName: maps[i]['folderName'],
      imagePath: maps[i]['imagePath'],
      playCount: maps[i]['playCount'],
    ));
  }

  // Gestione cartelle
  static Future<List<Folder>> getUserFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) => Folder(
      id: maps[i]['id'],
      name: maps[i]['name'],
      imagePath: maps[i]['imagePath'],
      isSpecial: maps[i]['isSpecial'] == 1,
      mp3SortType: SortType.values[maps[i]['mp3SortType'] ?? 0],
    ));
  }

  static Future<List<Folder>> getFavoriteFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders', where: 'isFavorite = 1');

    final folders = List.generate(maps.length, (i) => Folder(
      id: maps[i]['id'],
      name: maps[i]['name'],
      imagePath: maps[i]['imagePath'],
      isSpecial: maps[i]['isSpecial'] == 1,
      mp3SortType: SortType.values[maps[i]['mp3SortType'] ?? 0],
    ));

    favoriteFolderIds = folders.map((f) => f.id).toSet();

    return folders;
  }

  static Future<void> toggleFolderFavorite(int folderId) async {
    final db = await database;
    final isFav = favoriteFolderIds.contains(folderId);

    if (isFav) {
      favoriteFolderIds.remove(folderId);
      await db.update('folders', {'isFavorite': 0}, where: 'id = ?', whereArgs: [folderId]);
    } else {
      favoriteFolderIds.add(folderId);
      await db.update('folders', {'isFavorite': 1}, where: 'id = ?', whereArgs: [folderId]);
    }
  }

  static Future<void> addUserFolder(String name) async {
    final db = await database;
    await db.insert('folders', {'id': DateTime.now().millisecondsSinceEpoch, 'name': name, 'isSpecial': 0, 'mp3SortType': 0});
  }

  static Future<void> deleteUserFolder(int id) async {
    final db = await database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
    favoriteFolderIds.remove(id);
  }

  static Future<void> updateUserFolderImage(int id, String imagePath) async {
    final db = await database;
    await db.update('folders', {'imagePath': imagePath}, where: 'id = ?', whereArgs: [id]);
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

  // Logica player
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
    final track = Track(title: song.title, folderName: song.folderName, artist: song.artist, id: song.id, imagePath: song.imagePath);
    onTrackChange(track);
  }

  static void onTrackChange(Track track) {
    currentTrackNotifier.value = track;
    resetPosition();
    _hasCountedCurrentPlay = false;
    play();
  }

  static void resetPosition() {
    positionNotifier.value = Duration.zero;
  }

  static void eject() {
    pause();
    resetPosition();
    _currentPlaylist.clear();
    _originalPlaylist.clear();
    _currentIndex = -1;
    _hasCountedCurrentPlay = false;
    isShuffleNotifier.value = false;
    loopModeNotifier.value = LoopMode.none;
    currentTrackNotifier.value = null;
  }

  static void play() {
    isPlayingNotifier.value = true;
    _startTimer();
  }

  static void pause() {
    isPlayingNotifier.value = false;
    _playerTimer?.cancel();
  }

  static void togglePlayPause() {
    if (isPlayingNotifier.value) pause(); else play();
  }

  static void seek(Duration position) {
    positionNotifier.value = position;
  }

  static void _startTimer() {
    _playerTimer?.cancel();
    _playerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPlayingNotifier.value) {
        timer.cancel();
        return;
      }
      final current = positionNotifier.value;
      final total = durationNotifier.value;
      if (current.inSeconds < total.inSeconds) {
        final newSeconds = current.inSeconds + 1;
        positionNotifier.value = Duration(seconds: newSeconds);
        if (newSeconds >= 10 && !_hasCountedCurrentPlay) {
          final currentTrack = currentTrackNotifier.value;
          if (currentTrack?.id != null) {
            incrementPlayCount(currentTrack!.id!);
            _hasCountedCurrentPlay = true;
          }
        }
      } else {
        _handleAutoNext();
      }
    });
  }

  static void _handleAutoNext() {
    if (loopModeNotifier.value == LoopMode.single) {
      positionNotifier.value = Duration.zero;
      _hasCountedCurrentPlay = false;
    } else {
      if (hasNext()) next(); else { pause(); positionNotifier.value = Duration.zero; }
    }
  }

  static bool hasNext() {
    if (_currentPlaylist.isEmpty) return false;
    if (loopModeNotifier.value == LoopMode.playlist) return true;
    if (isShuffleNotifier.value) return true;
    return _currentIndex < _currentPlaylist.length - 1;
  }

  static bool hasPrevious() {
    if (_currentPlaylist.isEmpty) return false;
    if (positionNotifier.value.inSeconds > 5) return true;
    if (loopModeNotifier.value == LoopMode.playlist) return true;
    if (isShuffleNotifier.value) return true;
    return _currentIndex > 0;
  }

  static void next() {
    if (_currentPlaylist.isEmpty) return;
    int nextIndex;
    if (isShuffleNotifier.value) {
      nextIndex = Random().nextInt(_currentPlaylist.length);
    } else {
      nextIndex = _currentIndex + 1;
      if (nextIndex >= _currentPlaylist.length) {
        if (loopModeNotifier.value == LoopMode.playlist) nextIndex = 0; else return;
      }
    }
    _currentIndex = nextIndex;
    _loadTrack(_currentPlaylist[_currentIndex]);
  }

  static void previous() {
    if (_currentPlaylist.isEmpty) return;
    if (positionNotifier.value.inSeconds > 5) {
      positionNotifier.value = Duration.zero;
      return;
    }
    int prevIndex;
    if (isShuffleNotifier.value) {
      prevIndex = Random().nextInt(_currentPlaylist.length);
    } else {
      prevIndex = _currentIndex - 1;
      if (prevIndex < 0) {
        if (loopModeNotifier.value == LoopMode.playlist) prevIndex = _currentPlaylist.length - 1; else return;
      }
    }
    _currentIndex = prevIndex;
    _loadTrack(_currentPlaylist[_currentIndex]);
  }

  static void toggleLoop() {
    switch (loopModeNotifier.value) {
      case LoopMode.none: loopModeNotifier.value = LoopMode.playlist; break;
      case LoopMode.playlist: loopModeNotifier.value = LoopMode.single; break;
      case LoopMode.single: loopModeNotifier.value = LoopMode.none; break;
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