import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vibration/vibration.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';

// --- 🔑 KEYS (PASTE YOURS HERE) ---
const supabaseUrl = 'https://gqijybzmvanzdhklwvgn.supabase.co'; 
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxaWp5YnptdmFuemRoa2x3dmduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3MTE1NDUsImV4cCI6MjA3OTI4NzU0NX0.JwgXITacKQ2dKWEcuWVrP65J1PwWQPFE3FYa_qrF0A8';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const SolaceVerseApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class SolaceVerseApp extends StatelessWidget {
  const SolaceVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      title: 'SolaceVerse',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFFBB86FC),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'Georgia')),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC),
          secondary: Color(0xFF03DAC6),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; 

  final List<Widget> _screens = [
    const HomeScreen(),   
    const HealScreen(),   
    const ProfileScreen() 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10, width: 0.5))),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: const Color(0xFFBB86FC),
          unselectedItemColor: Colors.white24,
          currentIndex: _currentIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.museum_outlined), label: 'Sanctuary'),
            BottomNavigationBarItem(icon: Icon(Icons.nightlight_round), label: 'Heal'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Vault'),
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _dailyWisdom = "The wound is the place where the Light enters you."; 
  String _searchQuery = "";
  String _selectedType = "All"; 
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSmartWisdom();
  }

  Future<void> _fetchSmartWisdom() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client.from('journal_entries').select('ai_tag').order('created_at', ascending: false).limit(1);
      if (response.isNotEmpty) {
        String tag = response[0]['ai_tag'].toString().toLowerCase();
        setState(() {
          if (tag.contains("sad") || tag.contains("lonely")) { _dailyWisdom = "Grief is just love with no place to go."; }
          else if (tag.contains("anx") || tag.contains("fear")) { _dailyWisdom = "You don't have to control the storm, just the ship."; }
          else if (tag.contains("happy") || tag.contains("hope")) { _dailyWisdom = "Happiness is a direction, not a place."; }
          else { _dailyWisdom = "Your story is not over yet."; }
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client.from('content_library').stream(primaryKey: ['id']);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(heroTag: "gravity", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GravityScreen())), backgroundColor: Colors.deepOrange, icon: const Icon(Icons.public), label: const Text("Weightless")),
          const SizedBox(height: 15),
          FloatingActionButton.extended(heroTag: "void", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VoidScreen())), backgroundColor: Colors.white10, foregroundColor: Colors.white, icon: const Icon(Icons.mic), label: const Text("The Void")),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A0B2E), Colors.black])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "Search feelings, titles...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none, icon: Icon(Icons.search, color: Colors.white38)),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [_buildTypeChip("All"), const SizedBox(width: 10), _buildTypeChip("Poetry"), const SizedBox(width: 10), _buildTypeChip("Short Story"), const SizedBox(width: 10), _buildTypeChip("Visual Art")]),
                  ),
                  const SizedBox(height: 15),
                   Container(padding: const EdgeInsets.all(15), width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: Text('$_dailyWisdom', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70, fontFamily: 'Georgia')))
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white12));
                  final allItems = snapshot.data!;
                  final visibleItems = allItems.where((item) {
                    bool matchesSearch = true;
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      matchesSearch = item['title'].toString().toLowerCase().contains(q) || item['vibe'].toString().toLowerCase().contains(q);
                    }
                    bool matchesType = true;
                    if (_selectedType != "All") {
                      matchesType = item['type'].toString().contains(_selectedType) || (_selectedType == "Poetry" && item['type'] == "Poem"); 
                    }
                    return matchesSearch && matchesType;
                  }).toList();

                  if (visibleItems.isEmpty) return Center(child: Text("No sanctuary found.", style: const TextStyle(color: Colors.white24)));
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal, 
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 50),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      final String? imageLink = item['image'];
                      final bool hasImage = imageLink != null && imageLink.isNotEmpty && imageLink.startsWith("http");

                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoryReaderScreen(item: item))),
                        child: Container(
                          width: 280, 
                          margin: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                            image: hasImage ? DecorationImage(image: NetworkImage(imageLink), fit: BoxFit.cover, opacity: 0.4) : null
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['type'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF03DAC6))), 
                                const SizedBox(height: 10), 
                                Text(item['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), 
                                const SizedBox(height: 10), 
                                Text(
                                  item['content'].toString().contains("http") && !item['content'].toString().contains(" ") ? "Visual Experience" : item['content'], 
                                  style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70, fontFamily: 'Georgia'), 
                                  maxLines: 3, overflow: TextOverflow.ellipsis
                                ), 
                                const SizedBox(height: 20), 
                                const Row(children: [Text("READ NOW", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.arrow_forward, color: Colors.white, size: 14)])
                              ]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label) {
    final isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFBB86FC) : Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

// --- STORY READER ---
class StoryReaderScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const StoryReaderScreen({required this.item, super.key});
  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() { super.initState(); _checkIfLiked(); }

  Future<void> _checkIfLiked() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Only check likes for content library items
    if (widget.item['id'] is! int) return; 
    
    try {
      final response = await Supabase.instance.client.from('user_likes').select().eq('user_id', user.id).eq('content_id', widget.item['id']);
      if (mounted && response.isNotEmpty) setState(() => _isLiked = true);
    } catch (e) {}
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔒 Login to save favorites!"))); return; }
    setState(() => _isLoading = true);
    try {
      if (_isLiked) {
        await Supabase.instance.client.from('user_likes').delete().eq('user_id', user.id).eq('content_id', widget.item['id']);
        setState(() => _isLiked = false);
      } else {
        await Supabase.instance.client.from('user_likes').insert({'user_id': user.id, 'content_id': widget.item['id']});
        setState(() => _isLiked = true);
      }
    } catch (e) {} finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isVisual = widget.item['content'].toString().contains("http") && !widget.item['content'].toString().contains(" ");
    final image = widget.item['image'];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white), onPressed: _isLoading ? null : _toggleLike)]),
      body: isVisual 
        ? Center(child: Image.network(widget.item['content'])) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (image != null && image.toString().isNotEmpty && image.toString().startsWith("http")) ...[ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(image, width: double.infinity, height: 250, fit: BoxFit.cover)), const SizedBox(height: 30)],
              Text(widget.item['title'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text(widget.item['vibe'] ?? "Emotional", style: const TextStyle(color: Color(0xFFBB86FC), letterSpacing: 2, fontSize: 12)),
              const SizedBox(height: 30), const Divider(color: Colors.white24), const SizedBox(height: 30),
              Text(widget.item['content'], style: const TextStyle(fontSize: 20, height: 1.8, fontFamily: 'Georgia', color: Colors.white70)),
              const SizedBox(height: 100),
            ]),
          ),
    );
  }
}

// --- LIKED CONTENT SCREEN ---
class LikedContentScreen extends StatefulWidget {
  const LikedContentScreen({super.key});
  @override
  State<LikedContentScreen> createState() => _LikedContentScreenState();
}

class _LikedContentScreenState extends State<LikedContentScreen> {
  List<Map<String, dynamic>> _likedItems = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _fetchLikedItems(); }

  Future<void> _fetchLikedItems() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final likes = await Supabase.instance.client.from('user_likes').select('content_id').eq('user_id', user.id);
      List<dynamic> ids = likes.map((e) => e['content_id']).toList();
      if (ids.isEmpty) { setState(() { _isLoading = false; _likedItems = []; }); return; }
      final content = await Supabase.instance.client.from('content_library').select().filter('id', 'in', ids);
      if (mounted) { setState(() { _likedItems = List<Map<String, dynamic>>.from(content); _isLoading = false; }); }
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Collection", style: TextStyle(fontSize: 16, letterSpacing: 2)), backgroundColor: Colors.transparent, elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC)))
        : _likedItems.isEmpty 
          ? const Center(child: Text("Your heart is empty.\nGo to Sanctuary to collect.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24)))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75),
              itemCount: _likedItems.length,
              itemBuilder: (context, index) {
                final item = _likedItems[index];
                final image = item['image'];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoryReaderScreen(item: item))),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), image: (image != null && image.toString().startsWith("http")) ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover, opacity: 0.6) : null, border: Border.all(color: Colors.white10)),
                    child: Padding(padding: const EdgeInsets.all(15), child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), Text(item['type'], style: const TextStyle(fontSize: 10, color: Color(0xFF03DAC6)))]))),
                );
              },
            ),
    );
  }
}

// --- TAB 2: HEAL SCREEN ---
class HealScreen extends StatefulWidget {
  const HealScreen({super.key});
  @override
  State<HealScreen> createState() => _HealScreenState();
}

class _HealScreenState extends State<HealScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _reflectionController = TextEditingController();
  late AnimationController _burnController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _sparkleOpacityAnimation;
  bool _isNightShift = false; 
  String _tag = ""; String _contentBody = ""; String _imageUrl = ""; String _nightStory = "";
  bool _isLoading = false; bool _isSaving = false; bool _isBurning = false; String _textBeforeBurn = ""; 

  @override
  void initState() {
    super.initState();
    _controller.addListener(() { setState(() {}); });
    _burnController = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _colorAnimation = TweenSequence<Color?>([TweenSequenceItem(tween: ColorTween(begin: Colors.white, end: Colors.deepOrange), weight: 50), TweenSequenceItem(tween: ColorTween(begin: Colors.deepOrange, end: Colors.grey), weight: 50)]).animate(CurvedAnimation(parent: _burnController, curve: const Interval(0.0, 0.2)));
    _sparkleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _burnController, curve: const Interval(0.9, 1.0, curve: Curves.easeIn)));
    _burnController.addListener(() {
      if (_isBurning) {
        double eatStart = 0.2; double eatEnd = 0.9;
        if (_burnController.value >= eatStart && _burnController.value <= eatEnd) {
          double progress = (_burnController.value - eatStart) / (eatEnd - eatStart);
          int totalChars = _textBeforeBurn.length;
          int charsToRemove = (totalChars * progress).toInt();
          int currentLength = totalChars - charsToRemove;
          if (currentLength >= 0) { _controller.text = _textBeforeBurn.substring(0, currentLength); _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length)); }
        }
      }
      setState(() {});
    });
    _burnController.addStatusListener((status) { if (status == AnimationStatus.completed) _resetPyre(); });
  }

  void _resetPyre() {
    setState(() { _controller.clear(); _reflectionController.clear(); _tag = ""; _nightStory = ""; _contentBody = ""; _imageUrl = ""; _isBurning = false; });
    _burnController.reset();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [Icon(Icons.auto_awesome, color: Colors.black, size: 20), SizedBox(width: 15), Text("Released. The weight is gone.", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))]), backgroundColor: Color(0xFF03DAC6), behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() { _burnController.dispose(); _controller.dispose(); super.dispose(); }

  Future<void> _processInput() async {
    if (_controller.text.isEmpty) return;
    setState(() { _isLoading = true; _tag = ""; _nightStory = ""; _contentBody = ""; _imageUrl = ""; });
    final baseUrl = 'http://192.168.137.1:8000'; 
    try {
      if (_isNightShift) {
        final url = Uri.parse('$baseUrl/night-shift?text=${_controller.text}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() { _nightStory = data['story']; _imageUrl = data['image'] ?? "https://via.placeholder.com/400"; });
        }
      } else {
        final url = Uri.parse('$baseUrl/mood?text=${_controller.text}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() { _tag = data['ai_nuanced_tag']; if (data['content'] != null) { _imageUrl = data['content']['image'] ?? ""; _contentBody = data['content']['content'] ?? ""; } });
        }
      }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Brain disconnected."))); } finally { setState(() { _isLoading = false; }); }
  }

  void _burnJournal() {
    if (_controller.text.isEmpty) return;
    setState(() { _isBurning = true; _textBeforeBurn = _controller.text; });
    _burnController.forward();
  }

  Future<void> _saveJournal() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔒 Login to Vault first!"))); return; }
    setState(() { _isSaving = true; });
    final savedMood = _isNightShift ? "Night Shift: ${_controller.text}" : _controller.text;
    final savedTag = _isNightShift ? "Bedtime Story" : _tag;
    final savedReflect = _isNightShift ? _nightStory : _reflectionController.text; 
    final url = Uri.parse('http://192.168.137.1:8000/save-journal');
    try {
      await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"mood": savedMood, "reflection": savedReflect, "ai_tag": savedTag, "image_url": _imageUrl}));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ Memory Sealed Forever"))); _reflectionController.clear();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save."))); } finally { setState(() { _isSaving = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNightShift ? const Color(0xFF05050F) : const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.air, color: Color(0xFF03DAC6)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BioSyncScreen())))), Row(children: [Text("NIGHT SHIFT", style: TextStyle(fontSize: 10, letterSpacing: 1, color: _isNightShift ? const Color(0xFFBB86FC) : Colors.white24)), Switch(value: _isNightShift, activeColor: const Color(0xFFBB86FC), inactiveThumbColor: Colors.grey, onChanged: (val) => setState(() => _isNightShift = val))])]),
            const SizedBox(height: 40),
            Opacity(opacity: _isBurning ? (1.0 - _burnController.value) : 1.0, child: Column(children: [Icon(_isBurning ? Icons.local_fire_department : (_isNightShift ? Icons.auto_stories : Icons.psychology), size: 40, color: _isBurning ? Colors.deepOrangeAccent : Colors.white), const SizedBox(height: 20), Text(_isBurning ? "Letting go..." : (_isNightShift ? "Tell me a worry..." : "How is your heart?"), style: const TextStyle(fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.w200))])),
            const SizedBox(height: 30),
            Stack(alignment: Alignment.center, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: _isNightShift ? const Color(0xFF1A1A2E) : Colors.transparent, borderRadius: BorderRadius.circular(30), border: Border.all(color: _isBurning ? (_colorAnimation.value ?? Colors.grey).withOpacity(1.0 - _burnController.value) : (_isNightShift ? const Color(0xFFBB86FC).withOpacity(0.3) : Colors.white24), width: 0.5)), child: TextField(controller: _controller, style: TextStyle(color: _isBurning ? _colorAnimation.value : Colors.white, fontSize: 18, fontWeight: FontWeight.w300, decoration: _isBurning ? TextDecoration.lineThrough : TextDecoration.none), textAlign: TextAlign.center, maxLines: 5, minLines: 1, decoration: InputDecoration(hintText: _isNightShift ? "I will turn it into a story..." : "Pour your feelings here...", hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none))), if (_isBurning && _burnController.value > 0.8) SparkleBurst(animation: _sparkleOpacityAnimation)]),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [OutlinedButton(onPressed: _isLoading || _isBurning ? null : _processInput, style: OutlinedButton.styleFrom(foregroundColor: _isNightShift ? const Color(0xFFBB86FC) : Colors.white, side: BorderSide(color: _isNightShift ? const Color(0xFFBB86FC) : Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)), child: _isLoading ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white)) : Text(_isNightShift ? "WEAVE STORY" : "ANALYZE", style: const TextStyle(letterSpacing: 2, fontSize: 12))), if (_controller.text.isNotEmpty && !_isBurning) ...[const SizedBox(width: 20), IconButton(icon: const Icon(Icons.local_fire_department, color: Colors.deepOrange), tooltip: "Burn (Delete Forever)", onPressed: _burnJournal)]]),
            if (!_isBurning && (_tag.isNotEmpty || _nightStory.isNotEmpty)) ...[const SizedBox(height: 50), if (!_isNightShift) Text(_tag, style: const TextStyle(color: Color(0xFF03DAC6), fontSize: 16, letterSpacing: 1)), const SizedBox(height: 30), if (_imageUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(_imageUrl)), const SizedBox(height: 20), if (_isNightShift) Text(_nightStory, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.8, fontFamily: 'Georgia', color: Color(0xFFFFD700))) else Text(_contentBody, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.8, fontFamily: 'Georgia')), const SizedBox(height: 40), if (!_isNightShift) ...[const Divider(color: Colors.white10), TextField(controller: _reflectionController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Reflect & Release...", border: InputBorder.none)), Align(alignment: Alignment.centerRight, child: IconButton(onPressed: _isSaving ? null : _saveJournal, icon: const Icon(Icons.save_alt, color: Colors.white38)))]],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// --- TAB 3: THE GLASS VAULT ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; bool _isLoginMode = true; int _totalResonance = 0; final Set<int> _flippedCards = {}; String _selectedFilter = "All"; 
  User? get _user => Supabase.instance.client.auth.currentUser;

  @override
  void initState() { super.initState(); if (_user != null) _fetchGlobalResonance(); }
  Future<void> _fetchGlobalResonance() async { final response = await Supabase.instance.client.from('journal_entries').select('id'); if (mounted) setState(() => _totalResonance = response.length); }
  Future<void> _authenticate() async { setState(() => _isLoading = true); try { if (_isLoginMode) { await Supabase.instance.client.auth.signInWithPassword(email: _emailController.text, password: _passwordController.text); } else { await Supabase.instance.client.auth.signUp(email: _emailController.text, password: _passwordController.text); } _fetchGlobalResonance(); setState(() {}); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); } finally { if (mounted) setState(() => _isLoading = false); } }
  Future<void> _deleteEntry(int id) async { try { await Supabase.instance.client.from('journal_entries').delete().eq('id', id); _fetchGlobalResonance(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memory Deleted."))); } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not delete."))); } }
  String _formatDate(String dateString) { try { final date = DateTime.parse(dateString); final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]; return "${months[date.month - 1]} ${date.day} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}"; } catch (e) { return ""; } }

  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      final journalStream = Supabase.instance.client.from('journal_entries').stream(primaryKey: ['id']).order('created_at', ascending: false);
      return Scaffold(
        // --- CHANGED: MULTI-FAB (Map + Quill) ---
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(heroTag: "map", backgroundColor: const Color(0xFF03DAC6), child: const Icon(Icons.map, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TemporalMapScreen()))),
            const SizedBox(height: 15),
            FloatingActionButton(heroTag: "quill", backgroundColor: const Color(0xFFBB86FC), child: const Icon(Icons.edit, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CoPilotJournalScreen()))),
          ],
        ),
        body: Stack(children: [Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A0B2E), Color(0xFF000000), Color(0xFF0D1B2A)]))), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 60), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("ECHO ARCHIVE", style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white.withOpacity(0.5))), const SizedBox(height: 5), Text(_user!.email!.split('@')[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w200, letterSpacing: 1, color: Colors.white))]), Row(children: [
          IconButton(icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 30), tooltip: "Collection", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LikedContentScreen()))),
          const SizedBox(width: 10),
          StreamBuilder<List<Map<String, dynamic>>>(stream: journalStream, builder: (context, snapshot) { if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(); return IconButton(icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30), tooltip: "Time Travel", onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => TimeTravelScreen(entries: snapshot.data!))); }); }), const SizedBox(width: 10), Container(height: 40, width: 40, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFBB86FC), Color(0xFF03DAC6)])), child: IconButton(icon: const Icon(Icons.logout, size: 15, color: Colors.black), onPressed: () async { await Supabase.instance.client.auth.signOut(); setState(() {}); }))])]), const SizedBox(height: 25), Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [const Icon(Icons.graphic_eq, color: Color(0xFF03DAC6), size: 20), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("GLOBAL RESONANCE", style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5), letterSpacing: 1)), const SizedBox(height: 2), Text("$_totalResonance souls healing.", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70))])])), 
          const SizedBox(height: 20), const Text("PAST 7 DAYS", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white24)), const SizedBox(height: 10), 
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) { bool active = Random().nextBool(); Color boxColor = active ? [Colors.cyanAccent, Colors.purpleAccent, Colors.amberAccent, Colors.greenAccent][Random().nextInt(4)] : Colors.white10; return Container(width: 35, height: 35, decoration: BoxDecoration(color: boxColor.withOpacity(0.7), borderRadius: BorderRadius.circular(8), boxShadow: active ? [BoxShadow(color: boxColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)] : [])); })), 
          const SizedBox(height: 20), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildFilterChip("All", Icons.grid_view), const SizedBox(width: 10), _buildFilterChip("Analysis", Icons.nightlight_round), const SizedBox(width: 10), _buildFilterChip("Journal", Icons.edit_note)])), const SizedBox(height: 20), Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(stream: journalStream, builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white10)); final allEntries = snapshot.data!; final visibleEntries = allEntries.where((entry) { if (_selectedFilter == "All") return true; if (_selectedFilter == "Journal") return entry['ai_tag'] == "Co-Pilot"; if (_selectedFilter == "Analysis") return entry['ai_tag'] != "Co-Pilot"; return true; }).toList(); if (visibleEntries.isEmpty) return Center(child: Text("No $_selectedFilter entries yet.", style: const TextStyle(color: Colors.white12))); return GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85), padding: const EdgeInsets.only(bottom: 120), itemCount: visibleEntries.length, itemBuilder: (context, index) { final entry = visibleEntries[index]; final entryId = entry['id'] as int; final isFlipped = _flippedCards.contains(entryId); final imageLink = entry['image_url']; final dateStr = _formatDate(entry['created_at']); bool isLocked = entry['ai_tag'].toString().startsWith("LOCKED"); if (isLocked && !isFlipped) { return GestureDetector(onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔓 Time Capsule Unlocked"))); setState(() => _flippedCards.add(entryId)); }, child: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12), image: const DecorationImage(image: NetworkImage("https://images.pexels.com/photos/1142950/pexels-photo-1142950.jpeg"), fit: BoxFit.cover, opacity: 0.6)), child: const Center(child: Icon(Icons.lock, color: Colors.white, size: 40)))); } return GestureDetector(onTap: () => setState(() => isFlipped ? _flippedCards.remove(entryId) : _flippedCards.add(entryId)), child: AnimatedContainer(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut, decoration: BoxDecoration(color: isFlipped ? Colors.white : const Color(0xFF1E1E1E).withOpacity(0.6), borderRadius: BorderRadius.circular(20), image: (!isFlipped && imageLink != null && imageLink.toString().isNotEmpty) ? DecorationImage(image: NetworkImage(imageLink), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)) : null, border: Border.all(color: Colors.white.withOpacity(0.05))), child: Padding(padding: const EdgeInsets.all(15), child: isFlipped ? Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.edit_note, color: Colors.black, size: 24), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteEntry(entryId))]), const SizedBox(height: 5), Text(entry['reflection'] ?? "No reflection.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.5))]))) : Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 10)), const SizedBox(height: 5), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)), child: Text(entry['ai_tag'] ?? "Emotion", style: const TextStyle(color: Color(0xFFBB86FC), fontSize: 10, fontWeight: FontWeight.bold))), const SizedBox(height: 10), Text('"${entry['mood']}"', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic))])))); }); }))]))]));
    } else {
      return Scaffold(body: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isLoginMode ? "Welcome Back" : "Begin Journey", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300)), const SizedBox(height: 40), TextField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())), const SizedBox(height: 20), TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())), const SizedBox(height: 30), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _authenticate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBB86FC), foregroundColor: Colors.black), child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : Text(_isLoginMode ? "OPEN VAULT" : "CREATE KEY"))), const SizedBox(height: 20), TextButton(onPressed: () => setState(() => _isLoginMode = !_isLoginMode), child: Text(_isLoginMode ? "First time? Create an account" : "Have a key? Log in", style: const TextStyle(color: Colors.white54)))])));
    }
  }
  Widget _buildFilterChip(String label, IconData icon) { final isSelected = _selectedFilter == label; return GestureDetector(onTap: () => setState(() => _selectedFilter = label), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isSelected ? const Color(0xFFBB86FC) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: isSelected ? const Color(0xFFBB86FC) : Colors.white12)), child: Row(children: [Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white54), const SizedBox(width: 8), Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12))]))); }
}

// --- CO-PILOT JOURNAL SCREEN ---
class CoPilotJournalScreen extends StatefulWidget {
  final DateTime? backdate;
  final String? initialPrompt;
  const CoPilotJournalScreen({this.backdate, this.initialPrompt, super.key});
  @override
  State<CoPilotJournalScreen> createState() => _CoPilotJournalScreenState();
}

class _CoPilotJournalScreenState extends State<CoPilotJournalScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Color _backgroundColor = const Color(0xFF121212); String _nudge = ""; bool _isThinking = false; bool _isSaving = false; bool _isTimeCapsule = false; 

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) _nudge = widget.initialPrompt!;
  }

  void _onTextChanged(String text) { setState(() => _nudge = ""); if (_debounce?.isActive ?? false) _debounce!.cancel(); _debounce = Timer(const Duration(seconds: 3), () { _triggerCopilot(text); }); }
  Future<void> _triggerCopilot(String text) async { if (text.length < 10) return; setState(() => _isThinking = true); try { final url = Uri.parse('http://192.168.137.1:8000/copilot'); final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"text": text})); if (response.statusCode == 200) { final data = jsonDecode(response.body); setState(() { String hex = data['color'].toString().replaceAll("0x", ""); _backgroundColor = Color(int.parse(hex, radix: 16)); _nudge = data['nudge']; }); } } catch (e) {} finally { setState(() => _isThinking = false); } }
  Future<void> _saveDeepJournal() async { if (_controller.text.isEmpty) return; final user = Supabase.instance.client.auth.currentUser; if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔒 Login to Vault first!"))); return; } setState(() => _isSaving = true); try { final url = Uri.parse('http://192.168.137.1:8000/save-journal'); String dateStr = widget.backdate != null ? DateFormat('yyyy-MM-dd').format(widget.backdate!) : ""; await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"mood": _isTimeCapsule ? "Letter to Future" : "Deep Journaling", "reflection": _controller.text, "ai_tag": _isTimeCapsule ? "LOCKED: Open Later" : "Co-Pilot", "image_url": "https://images.pexels.com/photos/1762851/pexels-photo-1762851.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1", "date": dateStr})); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isTimeCapsule ? "🔒 Capsule Locked." : "✨ Journal Saved"))); Navigator.pop(context); } } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save."))); } finally { setState(() => _isSaving = false); } }
  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return AnimatedContainer(duration: const Duration(seconds: 2), curve: Curves.easeInOut, color: _backgroundColor, child: Scaffold(backgroundColor: Colors.transparent, appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(widget.backdate != null ? "Repairing Past..." : "Deep Journal", style: const TextStyle(color: Colors.white38, fontSize: 14)), leading: IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF03DAC6))) : const Icon(Icons.check, color: Color(0xFF03DAC6)), onPressed: _isSaving ? null : _saveDeepJournal)]), body: Column(children: [if (widget.backdate == null) Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isTimeCapsule ? Icons.lock : Icons.lock_open, color: Colors.white24, size: 14), const SizedBox(width: 10), Text("Time Capsule Mode", style: TextStyle(color: _isTimeCapsule ? const Color(0xFFBB86FC) : Colors.white24, fontSize: 12)), Switch(value: _isTimeCapsule, activeColor: const Color(0xFFBB86FC), onChanged: (val) => setState(() => _isTimeCapsule = val), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)]), Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: TextField(controller: _controller, onChanged: _onTextChanged, style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.white, fontFamily: 'Georgia'), maxLines: null, expands: true, cursorColor: const Color(0xFFBB86FC), decoration: const InputDecoration(hintText: "Start writing...", hintStyle: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic), border: InputBorder.none)))), AnimatedSize(duration: const Duration(milliseconds: 500), curve: Curves.easeOut, child: Container(width: double.infinity, height: (_nudge.isNotEmpty || _isThinking) ? null : 0, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), border: const Border(top: BorderSide(color: Colors.white10))), child: Row(children: [_isThinking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBB86FC))) : const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFBB86FC)), const SizedBox(width: 15), Expanded(child: Text(_isThinking ? "Listening..." : _nudge, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)))])))]))); }
}

// --- NEW: THE TEMPORAL MAP (With Clickable Entries) ---
class TemporalMapScreen extends StatefulWidget {
  const TemporalMapScreen({super.key});
  @override
  State<TemporalMapScreen> createState() => _TemporalMapScreenState();
}

class _TemporalMapScreenState extends State<TemporalMapScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() { super.initState(); _fetchEvents(); }

  Future<void> _fetchEvents() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client.from('journal_entries').select();
    Map<DateTime, List<dynamic>> loadedEvents = {};
    for (var item in response) {
      DateTime date = DateTime.parse(item['created_at']);
      DateTime cleanDate = DateTime(date.year, date.month, date.day);
      if (loadedEvents[cleanDate] == null) loadedEvents[cleanDate] = [];
      loadedEvents[cleanDate]!.add(item);
    }
    setState(() => _events = loadedEvents);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
    DateTime cleanDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    
    if (_events[cleanDate] != null && _events[cleanDate]!.isNotEmpty) {
      _showDayEntries(_events[cleanDate]!);
    } else {
      _repairDay(selectedDay);
    }
  }

  void _showDayEntries(List<dynamic> entries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Memories from ${DateFormat('MMMM d').format(_selectedDay!)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      onTap: () {
                        final mappedItem = {
                          'id': entry['id'], 
                          'title': entry['mood'], 
                          'content': entry['reflection'] ?? "No reflection recorded.",
                          'image': entry['image_url'],
                          'vibe': entry['ai_tag'],
                          'type': 'Memory'
                        };
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StoryReaderScreen(item: mappedItem)));
                      },
                      leading: const Icon(Icons.history_edu, color: Color(0xFFBB86FC)),
                      title: Text(entry['mood'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(entry['ai_tag'] ?? "Entry", style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                    );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Future<void> _repairDay(DateTime date) async {
    // 1. SETUP DEFAULTS (The Safety Net - Don't delete!)
    double lat = 40.7128; 
    double long = -74.0060; 

    // 2. TRY TO GET REAL GPS (The Upgrade)
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // If granted, get real position
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(); 
        lat = pos.latitude; 
        long = pos.longitude;
      }
    } catch (e) {
       debugPrint("GPS Error (Using Default): $e");
    }

    // 3. FETCH CONTEXT (Using whatever lat/long we have)
    String weatherPrompt = "What happened this day?";
    try {
      final url = Uri.parse('http://192.168.137.1:8000/temporal-context'); // UPDATE IP HERE IF ON PHONE
      final response = await http.post(
        url, 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({
          "latitude": lat, 
          "longitude": long, 
          "date": DateFormat('yyyy-MM-dd').format(date)
        })
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        weatherPrompt = "${data['weather']}... ${data['prompt']}";
      }
    } catch (e) {}
    Navigator.push(context, MaterialPageRoute(builder: (context) => CoPilotJournalScreen(backdate: date, initialPrompt: weatherPrompt)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Temporal Map", style: TextStyle(letterSpacing: 3, fontSize: 16)), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            eventLoader: (day) => _events[DateTime(day.year, day.month, day.day)] ?? [],
            calendarStyle: const CalendarStyle(defaultTextStyle: TextStyle(color: Colors.white54), todayDecoration: BoxDecoration(color: Color(0xFFBB86FC), shape: BoxShape.circle), selectedDecoration: BoxDecoration(color: Color(0xFF03DAC6), shape: BoxShape.circle), markerDecoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 30),
          if (_selectedDay != null) Padding(padding: const EdgeInsets.all(20.0), child: Text("Touching ${DateFormat('MMMM d').format(_selectedDay!)}...", style: const TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)))
        ],
      ),
    );
  }
}

// --- FEATURE: TIME TRAVEL (Visuals Only) ---
class TimeTravelScreen extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  const TimeTravelScreen({required this.entries, super.key});
  @override
  State<TimeTravelScreen> createState() => _TimeTravelScreenState();
}

class _TimeTravelScreenState extends State<TimeTravelScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _showText = false;

  @override
  void initState() { super.initState(); _startSlideshow(); }
  
  void _startSlideshow() { 
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) { 
      if (_currentIndex < widget.entries.length - 1) { 
        setState(() { _currentIndex++; _showText = false; }); 
        _handleSlideTransition(); 
      } else { 
        timer.cancel(); Navigator.pop(context); 
      } 
    }); 
    _handleSlideTransition(); 
  }
  
  void _handleSlideTransition() async { 
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(pattern: [0, 50, 100, 50]); 
    Future.delayed(const Duration(milliseconds: 800), () { 
      if (mounted) setState(() => _showText = true); 
    }); 
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entries[_currentIndex];
    final imageLink = entry['image_url'];
    final dateStr = entry['created_at'].toString().split('T')[0]; 
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand, 
        children: [
          // Background Image
          AnimatedSwitcher(
            duration: const Duration(seconds: 2), 
            child: imageLink != null && imageLink.toString().isNotEmpty 
              ? TweenAnimationBuilder(
                  key: ValueKey(imageLink), 
                  tween: Tween<double>(begin: 1.0, end: 1.1), 
                  duration: const Duration(seconds: 10), 
                  builder: (context, double scale, child) { 
                    return Transform.scale(scale: scale, child: Image.network(imageLink, fit: BoxFit.cover, height: double.infinity, width: double.infinity, color: Colors.black.withOpacity(0.7), colorBlendMode: BlendMode.darken)); 
                  }
                ) 
              : Container(color: const Color(0xFF121212))
          ),
          
          // --- FIXED: OVERLAY TEXT (SCROLLABLE TO PREVENT OVERFLOW) ---
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0), // Padding to avoid bars
              child: Center(
                child: SingleChildScrollView(
                  child: AnimatedOpacity(
                    opacity: _showText ? 1.0 : 0.0, 
                    duration: const Duration(seconds: 1), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // HERO TEXT
                        Text(
                          entry['reflection'] != null && entry['reflection'].toString().length > 5 ? entry['reflection'] : '"${entry['mood']}"', 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(fontFamily: 'Georgia', fontSize: 22, color: Colors.white, height: 1.6, shadows: [Shadow(color: Colors.black, blurRadius: 10)])
                        ), 
                        const SizedBox(height: 40), 
                        // METADATA
                        Text("$dateStr • ${entry['ai_tag']}", style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2))
                      ]
                    )
                  ),
                ),
              ),
            ),
          ),
          
          // Progress & Close
          Positioned(bottom: 50, left: 40, right: 40, child: LinearProgressIndicator(value: (_currentIndex + 1) / widget.entries.length, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF03DAC6)))), 
          Positioned(top: 50, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)))
        ]
      ),
    );
  }
}

// --- BIO-SYNC & GRAVITY & VOID & SPARKLE WIDGETS ---
class BioSyncScreen extends StatefulWidget { const BioSyncScreen({super.key}); @override State<BioSyncScreen> createState() => _BioSyncScreenState(); }
class _BioSyncScreenState extends State<BioSyncScreen> with SingleTickerProviderStateMixin { late AnimationController _controller; String _instruction = "Inhale"; @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 19)); _startBreathingCycle(); } void _startBreathingCycle() async { bool canVibrate = await Vibration.hasVibrator() ?? false; while (mounted) { setState(() => _instruction = "Inhale"); _controller.animateTo(1.0, duration: const Duration(seconds: 4), curve: Curves.easeOut); if (canVibrate) Vibration.vibrate(duration: 100); await Future.delayed(const Duration(seconds: 4)); if (!mounted) break; setState(() => _instruction = "Hold"); if (canVibrate) Vibration.vibrate(duration: 50); await Future.delayed(const Duration(seconds: 7)); if (!mounted) break; setState(() => _instruction = "Exhale"); _controller.animateTo(0.2, duration: const Duration(seconds: 8), curve: Curves.easeIn); if (canVibrate) Vibration.vibrate(duration: 1000); await Future.delayed(const Duration(seconds: 8)); } } @override void dispose() { _controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, body: Stack(children: [Positioned(top: 50, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context))), Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [AnimatedBuilder(animation: _controller, builder: (context, child) { Color glowColor = _instruction == "Inhale" ? Colors.blue : _instruction == "Hold" ? const Color(0xFFBB86FC) : const Color(0xFF03DAC6); return Container(height: 50 + (250 * _controller.value), width: 50 + (250 * _controller.value), decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [glowColor.withOpacity(0.6), Colors.transparent], stops: const [0.2, 1.0]), boxShadow: [BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 60, spreadRadius: 10)]), child: Center(child: Text(_instruction.toUpperCase(), style: const TextStyle(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white70)))); }), const SizedBox(height: 100), const Text("Bio-Sync Active", style: TextStyle(color: Colors.white24, letterSpacing: 2))]))])); } }
class GravityScreen extends StatefulWidget { const GravityScreen({super.key}); @override State<GravityScreen> createState() => _GravityScreenState(); }
class _GravityScreenState extends State<GravityScreen> { final _worryController = TextEditingController(); List<WorryRock> rocks = []; StreamSubscription? _streamSubscription; Timer? _gameLoop; double _gravityX = 0; double _gravityY = 20.0; double _simulatedTilt = 0.0; bool _simulatedUpsideDown = false; @override void initState() { super.initState(); _startPhysics(); _listenToSensors(); } void _listenToSensors() { try { _streamSubscription = accelerometerEvents.listen((AccelerometerEvent event) { if (mounted) { setState(() { _gravityX = -event.x * 5.0; _gravityY = event.y * 5.0; }); } }, onError: (e) => debugPrint("Sensor error (Simulating): $e"), cancelOnError: true); } catch (e) { debugPrint("Sensor Init Error: $e"); } } void _startPhysics() { _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) { if (!mounted) return; _updateRocks(); }); } void _addRock() { if (_worryController.text.isEmpty) return; setState(() { rocks.add(WorryRock(id: DateTime.now().millisecondsSinceEpoch, text: _worryController.text, x: MediaQuery.of(context).size.width / 2 - 40, y: 100, color: Colors.primaries[Random().nextInt(Colors.primaries.length)])); _worryController.clear(); }); } void _updateRocks() { setState(() { double width = MediaQuery.of(context).size.width; double height = MediaQuery.of(context).size.height; double rockSize = 80.0; if (_simulatedTilt != 0.0) _gravityX = _simulatedTilt * 20; if (_simulatedUpsideDown) _gravityY = -20.0; else if (_simulatedTilt != 0.0) _gravityY = 20.0; for (var rock in rocks) { rock.vx += _gravityX * 0.02; rock.vy += _gravityY * 0.02; rock.x += rock.vx; rock.y += rock.vy; rock.vx *= 0.95; rock.vy *= 0.95; if (rock.x < 0) { rock.x = 0; rock.vx *= -0.6; } if (rock.x > width - rockSize) { rock.x = width - rockSize; rock.vx *= -0.6; } if (rock.y > height - rockSize) { rock.y = height - rockSize; rock.vy *= -0.6; rock.vx *= 0.90; } if (rock.y < -150) rock.isFalling = true; } rocks.removeWhere((rock) => rock.isFalling); }); } @override void dispose() { _streamSubscription?.cancel(); _gameLoop?.cancel(); super.dispose(); } @override Widget build(BuildContext context) { return Scaffold(backgroundColor: const Color(0xFF1E1E24), body: Stack(children: [Center(child: Opacity(opacity: 0.1, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.screen_rotation, size: 100, color: Colors.white), SizedBox(height: 20), Text("TILT PHONE UPSIDE DOWN\nTO DUMP WORRIES", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))]))), ...rocks.map((rock) => Positioned(left: rock.x, top: rock.y, child: Container(width: 80, height: 80, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: rock.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(5,5))], border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)), child: Center(child: Text(rock.text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis))))).toList(), Positioned(top: 60, left: 20, right: 20, child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)), child: TextField(controller: _worryController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Add a stone...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white38)), onSubmitted: (_) => _addRock()))), const SizedBox(width: 10), FloatingActionButton(mini: true, backgroundColor: const Color(0xFFBB86FC), onPressed: _addRock, child: const Icon(Icons.add))])), Positioned(bottom: 20, left: 20, right: 20, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("💻 LAPTOP SIMULATOR", style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2)), const SizedBox(height: 10), Row(children: [const Text("Roll:", style: TextStyle(color: Colors.white54)), Expanded(child: Slider(value: _simulatedTilt, min: -1.0, max: 1.0, activeColor: Colors.orange, onChanged: (val) => setState(() => _simulatedTilt = val)))]), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Turn Upside Down:", style: TextStyle(color: Colors.white)), Switch(value: _simulatedUpsideDown, activeColor: Colors.redAccent, onChanged: (val) => setState(() => _simulatedUpsideDown = val))]), const Text("(Use this switch to dump rocks)", style: TextStyle(color: Colors.white24, fontSize: 10))]))) ])); } }
class WorryRock { int id; String text; double x; double y; double vx = 0; double vy = 0; Color color; bool isFalling = false; WorryRock({required this.id, required this.text, required this.x, required this.y, required this.color}); }
class VoidScreen extends StatefulWidget { const VoidScreen({super.key}); @override State<VoidScreen> createState() => _VoidScreenState(); }
class _VoidScreenState extends State<VoidScreen> { bool _isRecording = false; StreamSubscription<NoiseReading>? _noiseSubscription; NoiseMeter? _noiseMeter; double _volume = 0.0; double _circleRadius = 50.0; Color _coreColor = Colors.white; double _simulatedVolume = 0.0; @override void initState() { super.initState(); _checkPermissionsAndStart(); } Future<void> _checkPermissionsAndStart() async { try { _noiseMeter = NoiseMeter(); var status = await Permission.microphone.request(); if (status == PermissionStatus.granted) _startListening(); } catch (e) { debugPrint("⚠️ Mic Init Error: $e"); } } void _startListening() { try { _noiseSubscription = _noiseMeter?.noise.listen((NoiseReading noiseReading) { if (!mounted) return; setState(() { double db = noiseReading.meanDecibel; if (db.isInfinite || db.isNaN) db = 0; _volume = db; _updateVisuals(_volume); }); }, onError: (e) => debugPrint('Mic Error: $e')); } catch (err) { debugPrint('Start Error: $err'); } } void _updateVisuals(double vol) { if (_simulatedVolume > 0) vol = _simulatedVolume; double targetRadius = 50 + (vol * 3); if (targetRadius > 350) targetRadius = 350; _circleRadius = targetRadius; if (vol < 40) _coreColor = Colors.white; else if (vol < 70) _coreColor = const Color(0xFF03DAC6); else _coreColor = Colors.deepOrange; } @override void dispose() { _noiseSubscription?.cancel(); super.dispose(); } @override Widget build(BuildContext context) { if (_simulatedVolume > 0) _updateVisuals(_simulatedVolume); return Scaffold(backgroundColor: Colors.black, body: Stack(children: [Positioned(top: 50, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () => Navigator.pop(context))), Center(child: AnimatedContainer(duration: const Duration(milliseconds: 100), curve: Curves.easeOut, height: _circleRadius, width: _circleRadius, decoration: BoxDecoration(shape: BoxShape.circle, color: _coreColor, boxShadow: [BoxShadow(color: _coreColor.withOpacity(0.6), blurRadius: _circleRadius, spreadRadius: _circleRadius / 2), if (_circleRadius > 200) const BoxShadow(color: Colors.black, blurRadius: 20, spreadRadius: -50)]))), Positioned(bottom: 150, left: 0, right: 0, child: Center(child: Text(_circleRadius > 150 ? "RELEASE IT." : "Speak into the void.", style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 5, fontSize: 12, fontWeight: FontWeight.bold)))), Positioned(bottom: 40, left: 40, right: 40, child: Column(children: [const Text("🎤 Laptop Scream Simulator", style: TextStyle(color: Colors.white12)), Slider(value: _simulatedVolume, min: 0.0, max: 100.0, activeColor: Colors.deepPurple, inactiveColor: Colors.white10, onChanged: (val) => setState(() => _simulatedVolume = val))]))])); } }
class SparkleBurst extends StatelessWidget { final Animation<double> animation; const SparkleBurst({required this.animation, super.key}); @override Widget build(BuildContext context) { return AnimatedBuilder(animation: animation, builder: (context, child) { return Opacity(opacity: animation.value, child: Transform.translate(offset: Offset(0, -50 * animation.value), child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 40))); }); } }