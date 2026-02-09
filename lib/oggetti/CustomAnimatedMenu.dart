import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mp3/main.dart'; 
import 'package:mp3/localization/AppLocalization.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mp3/services/MusicServices.dart';

typedef OnCreateFolderCallback = void Function();
typedef OnPickMp3Callback = void Function();
typedef OnSortChangeCallback = void Function(SortType sortType);
typedef OnThemeChangeCallback = void Function(ThemeOption option);
typedef OnLanguageChangeCallback = void Function();

class CustomAnimatedMenu extends StatefulWidget {
  final OnCreateFolderCallback onCreateFolder;
  final OnPickMp3Callback onPickMp3;
  final OnSortChangeCallback onSortChange;
  final OnThemeChangeCallback onThemeChange;
  final OnLanguageChangeCallback onLanguageChange;

  const CustomAnimatedMenu({
    super.key,
    required this.onCreateFolder,
    required this.onPickMp3,
    required this.onSortChange,
    required this.onThemeChange,
    required this.onLanguageChange,
  });

  @override
  State<CustomAnimatedMenu> createState() => _CustomAnimatedMenuState();
}

class _CustomAnimatedMenuState extends State<CustomAnimatedMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  final List<String> _languages = ['Italiano', 'English', 'Español', 'Deutsch', 'Français', '日本語'];
  final List<String> _languageCodes = ['it', 'en', 'es', 'de', 'fr', 'ja'];
  
  int _selectedLanguageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showMenu() {
    if (_isMenuOpen) {
      _dismissMenu();
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissMenu,
                child: Container(color: Colors.transparent),
              ),
            ),

            Positioned(
              right: MediaQuery.of(context).size.width - (position.dx + size.width),
              top: position.dy + size.height + 8,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 250, 
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2), 
                        width: 1.5
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return ValueListenableBuilder<ThemeMode>(
                          valueListenable: MusicService.themeNotifier,
                          builder: (context, currentThemeMode, child) {
                            return _buildMainMenu(currentThemeMode);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
      _controller.forward();
      setState(() {
        _isMenuOpen = true;
      });
    }
  }

  void _dismissMenu() {
    if (!_isMenuOpen) return;
    _controller.reverse().then((_) {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _handleThemeToggle(ThemeMode currentMode) {
    final newMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    MusicService.updateTheme(newMode);
  }

  void _openSortSheet() {
    _dismissMenu(); 
    
    showCupertinoModalPopup(
      context: context, 
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          AppLocalization.of(context).translate("sort_title"), 
          style: TextStyle(color: Theme.of(context).colorScheme.secondary)
        ),
        actions: SortType.values.map((type) {
           String labelKey = "";
           switch(type) {
             case SortType.dataInserimento: labelKey = "sort_date"; break;
             case SortType.alfabetico: labelKey = "sort_az"; break;
             case SortType.alfabeticoInverso: labelKey = "sort_za"; break;
             case SortType.casuale: labelKey = "sort_random"; break;
           }
           return CupertinoActionSheetAction(
             child: Text(
               AppLocalization.of(context).translate(labelKey), 
               style: const TextStyle(color: CupertinoColors.activeBlue)
             ),
             onPressed: () {
               Navigator.pop(ctx);
               widget.onSortChange(type);
             },
           );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: Text(
            AppLocalization.of(context).translate("common_cancel"), 
            style: const TextStyle(color: Colors.redAccent)
          ),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _openLanguagePicker() {
    _dismissMenu();

    final currentCode = localeNotifier.value.languageCode;
    final int initialIndex = _languageCodes.indexOf(currentCode);
    _selectedLanguageIndex = initialIndex != -1 ? initialIndex : 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Material(
        color: Colors.transparent,
        child: Container(
          height: 250, 
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(
                          AppLocalization.of(context).translate("common_cancel"), 
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16)
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        AppLocalization.of(context).translate("menu_language"),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.secondary, 
                          decoration: TextDecoration.none,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(
                          AppLocalization.of(context).translate("common_confirm"), 
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                        onPressed: () async {
                          final newCode = _languageCodes[_selectedLanguageIndex];
                          localeNotifier.value = Locale(newCode);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('language_code', newCode);
                          widget.onLanguageChange();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 32.0,
                    scrollController: FixedExtentScrollController(initialItem: _selectedLanguageIndex),
                    backgroundColor: Colors.transparent,
                    onSelectedItemChanged: (int selectedItem) {
                      _selectedLanguageIndex = selectedItem;
                    },
                    children: List<Widget>.generate(_languages.length, (int index) {
                      return Center(
                        child: Text(
                          _languages[index],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary, 
                            fontSize: 20,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(ThemeMode currentMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCustomMenuItem(
          icon: CupertinoIcons.folder_badge_plus,
          title: AppLocalization.of(context).translate("menu_new_folder"),
          onTap: () {
            _dismissMenu();
            widget.onCreateFolder();
          },
        ),
        
        _buildCustomMenuItem(
          icon: CupertinoIcons.sort_down,
          title: AppLocalization.of(context).translate("menu_sort"),
          onTap: _openSortSheet, 
        ),

        _buildCustomMenuItem(
          icon: currentMode == ThemeMode.light
              ? CupertinoIcons.sun_max
              : CupertinoIcons.moon,
          title: currentMode == ThemeMode.dark
              ? AppLocalization.of(context).translate("menu_theme_dark")
              : AppLocalization.of(context).translate("menu_theme_light"),
          trailing: SizedBox(
            height: 24,
            width: 44,
            child: Switch.adaptive(
              value: currentMode == ThemeMode.dark,
              onChanged: (bool isDark) {
                _handleThemeToggle(currentMode);
              },
              inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
              inactiveTrackColor: const Color.fromARGB(115, 119, 122, 149),
              activeThumbColor: const Color.fromARGB(255, 255, 255, 255),
              activeTrackColor: const Color.fromARGB(255, 28, 234, 124),
            ),
          ),
          onTap: () => _handleThemeToggle(currentMode),
        ),
        
        _buildCustomMenuItem(
          icon: CupertinoIcons.globe,
          title: AppLocalization.of(context).translate("menu_language"),
          onTap: _openLanguagePicker, 
        ),
      ],
    );
  }

  Widget _buildCustomMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showMenu,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          size: 34,
          CupertinoIcons.ellipsis,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}