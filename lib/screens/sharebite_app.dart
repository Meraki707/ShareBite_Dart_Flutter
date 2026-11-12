import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/sharebite_controller.dart';
import '../data/sharebite_repository.dart';
import '../data/sample_data.dart';
import '../models/sharebite_models.dart';

const _leaf = Color(0xFF91BD42);
const _leafDark = Color(0xFF547A22);
const _leafPale = Color(0xFFEAF1DC);
const _coral = Color(0xFFE98770);
const _ink = Color(0xFF25281F);
const _muted = Color(0xFF777B70);
const _paper = Color(0xFFF7F7F1);
const _line = Color(0xFFE6E8DF);

class ShareBiteApp extends StatelessWidget {
  const ShareBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _leaf,
        primary: _leafDark,
        surface: _paper,
      ),
    );
    return MaterialApp(
      title: 'ShareBite · O bairro compartilha',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.dmSansTextTheme(base.textTheme)
            .apply(bodyColor: _ink, displayColor: _ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _leafDark, width: 1.5),
          ),
        ),
      ),
      home: const ShareBiteHome(),
    );
  }
}

class ShareBiteHome extends StatefulWidget {
  const ShareBiteHome({super.key});

  @override
  State<ShareBiteHome> createState() => _ShareBiteHomeState();
}

class _ShareBiteHomeState extends State<ShareBiteHome> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _profileSearchController = TextEditingController();
  late final ShareBiteController _controller;
  int _tab = 0;
  String _category = 'Tudo';
  String _mode = 'Todos os tipos';
  String _location = 'Pinheiros, São Paulo';
  String _profileStatus = 'Ativos';
  String _profileMode = 'Todos';
  String _chatId = 'horta';

  Set<String> get _saved => _controller.savedListingIds;
  List<Listing> get _listings => _controller.listings;
  List<Conversation> get _conversations => _controller.conversations;
  bool get _isLoading => _controller.isLoading;
  Object? get _databaseError => _controller.error;
  bool get _signedIn => _controller.isSignedIn;
  String get _accountName => _controller.accountName;
  String get _accountEmail => _controller.accountEmail;

  static const _navLabels = [
    'Explorar',
    'Perto de mim',
    'Conversas',
    'Impacto',
    'Perfil',
  ];
  static const _navIcons = [
    Icons.grid_view_rounded,
    Icons.location_on_outlined,
    Icons.chat_bubble_outline,
    Icons.spa_outlined,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    _controller = ShareBiteController(
      repository: SqliteShareBiteRepository(),
    );
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    await _controller.load();
    if (!mounted) return;
    if (!_conversations.any((conversation) => conversation.id == _chatId) &&
        _conversations.isNotEmpty) {
      setState(() => _chatId = _conversations.first.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _profileSearchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
        ),
      );
  }

  Future<void> _toggleSaved(String id) async {
    try {
      await _controller.toggleSaved(id);
    } catch (error) {
      if (mounted)
        _showNotice('Não foi possível salvar essa alteração: $error');
    }
  }

  List<Listing> get _visibleListings {
    final query = _searchController.text.trim().toLowerCase();
    return _listings.where((item) {
      final matchesCategory = _category == 'Tudo' || item.category == _category;
      final matchesMode = _mode == 'Todos os tipos' || item.mode == _mode;
      final text = '${item.title} ${item.category} ${item.place} ${item.owner}'
          .toLowerCase();
      return !item.completed &&
          matchesCategory &&
          matchesMode &&
          (query.isEmpty || text.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading || _databaseError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _databaseError == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Não foi possível carregar os dados locais:\n$_databaseError',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadStoredData,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: _buildAppBar(wide, constraints.maxWidth < 400),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 600 ? 16 : 28,
                ),
                child: _buildPage(wide),
              ),
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (index) =>
                      setState(() => _tab = index),
                  destinations: List.generate(
                    _navLabels.length,
                    (index) => NavigationDestination(
                      icon: Icon(_navIcons[index]),
                      label: _navLabels[index],
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool wide, bool compact) {
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 20,
      title: InkWell(
        onTap: () => setState(() => _tab = 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'image_1790257283284270-removebg-preview.png',
              width: 38,
              height: 38,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.eco, color: _leafDark),
            ),
            const SizedBox(width: 8),
            Text(
              'sharebite',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (wide)
          ...List.generate(
            _navLabels.length,
            (index) => TextButton.icon(
              onPressed: () => setState(() => _tab = index),
              icon: Icon(
                _navIcons[index],
                size: 17,
                color: _tab == index ? _leafDark : _muted,
              ),
              label: Text(
                _navLabels[index],
                style: TextStyle(
                  color: _tab == index ? _leafDark : _muted,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _tab == index ? _leafPale : Colors.transparent,
              ),
            ),
          ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _publish,
          icon: const Icon(Icons.add, size: 18),
          label:
              compact ? const SizedBox.shrink() : const Text('Publicar item'),
          style: FilledButton.styleFrom(
            backgroundColor: _leaf,
            foregroundColor: const Color(0xFF263414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding:
                compact ? const EdgeInsets.symmetric(horizontal: 10) : null,
          ),
        ),
        IconButton(
          tooltip: _signedIn ? 'Minha conta' : 'Entrar',
          onPressed: _account,
          icon: Icon(_signedIn ? Icons.person_outline : Icons.login),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildPage(bool wide) {
    return switch (_tab) {
      0 => _explorePage(wide),
      1 => _nearbyPage(wide),
      2 => _messagesPage(wide),
      3 => _impactPage(wide),
      _ => _profilePage(wide),
    };
  }

  Widget _explorePage(bool wide) {
    final columns = wide ? 3 : 2;
    return ListView(
      padding: const EdgeInsets.only(top: 22, bottom: 30),
      children: [
        _welcomeBanner(wide),
        const SizedBox(height: 30),
        _sectionHeader(
          'Achados perto de você',
          'Coisas boas circulam por aqui.',
          trailing: const _LocationLabel(
            icon: Icons.navigation,
            text: 'Raio de 5 km',
          ),
        ),
        const SizedBox(height: 17),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: wide ? 480 : double.infinity,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: _muted),
                  hintText: 'Buscar alimentos, objetos, lugares...',
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: _mode,
                decoration: const InputDecoration(labelText: 'Modalidade'),
                items: ['Todos os tipos', ...listingModes]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _mode = value ?? 'Todos os tipos'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _tab = 1),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Mapa'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: listingCategories.map((category) {
              final selected = _category == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = category),
                  selectedColor: _leafPale,
                  side: BorderSide(color: selected ? _leaf : _line),
                  labelStyle: TextStyle(
                    color: selected ? _leafDark : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (_visibleListings.isEmpty)
          const Padding(
            padding: EdgeInsets.all(42),
            child: Center(
              child: Text(
                'Não encontramos itens com esses filtros. Tente outra busca.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visibleListings.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 18,
              mainAxisSpacing: 20,
              childAspectRatio: wide ? 0.88 : 0.68,
            ),
            itemBuilder: (context, index) =>
                _listingCard(_visibleListings[index]),
          ),
      ],
    );
  }

  Widget _welcomeBanner(bool wide) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        decoration: const BoxDecoration(color: _leaf),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = MediaQuery.sizeOf(context).width;
            final mobile = viewportWidth <= 680;
            return Stack(
              children: [
                if (mobile)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 66,
                    child: Opacity(
                      opacity: 0.24,
                      child: Image.network(
                        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=1100&q=88',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.1),
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: constraints.maxWidth * (wide ? 0.39 : 0.34),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=1100&q=88',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.06),
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _leaf,
                                Color(0xC991BD42),
                                Color(0x0091BD42),
                              ],
                              stops: [0, 0.2, 0.65],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 18 : 34,
                    vertical: mobile ? 21 : 29,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: mobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth * 0.67).clamp(0, 610),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MENOS EXCESSO. MAIS ENCONTRO.',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF38501E),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'O que sobra pra você pode mudar o dia de alguém.',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: mobile ? 29 : 39,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Compartilhe, troque ou encontre algo bom no seu bairro.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF384827),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 17),
                        Wrap(
                          spacing: 13,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: _publish,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Compartilhar um item'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            _LocationLabel(
                              icon: Icons.location_on_outlined,
                              text: _location,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _listingCard(Listing item) {
    final modeColor = item.mode == 'Troca'
        ? const Color(0xFFEFE4D2)
        : item.mode == 'Venda'
            ? const Color(0xFFF7E5DF)
            : _leafPale;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _showOffer(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _listingImage(item),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _Tag(label: item.mode, color: modeColor),
                  ),
                  Positioned(
                    right: 6,
                    top: 5,
                    child: IconButton.filledTonal(
                      tooltip: _saved.contains(item.id)
                          ? 'Remover dos salvos'
                          : 'Salvar item',
                      onPressed: () => _toggleSaved(item.id),
                      icon: Icon(
                        _saved.contains(item.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _saved.contains(item.id) ? _coral : _ink,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.price,
                          style: const TextStyle(
                            color: _leafDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.owner} · ${item.place}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.distance,
                          style: const TextStyle(fontSize: 10, color: _muted),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            item.category,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: _muted),
                          ),
                        ),
                      ],
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

  Widget _listingImage(Listing item, {double? height}) {
    final image = item.imageBytes != null
        ? Image.memory(item.imageBytes!, fit: BoxFit.cover)
        : Image.network(
            item.image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _leafPale,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: _leafDark,
              ),
            ),
          );
    return SizedBox(height: height, width: double.infinity, child: image);
  }

  Widget _nearbyPage(bool wide) {
    return ListView(
      padding: const EdgeInsets.only(top: 28, bottom: 30),
      children: [
        _sectionHeader(
          'O bairro está compartilhando',
          'Encontre algo bom a poucos passos de casa.',
          trailing: OutlinedButton.icon(
            onPressed: _locate,
            icon: const Icon(Icons.my_location, size: 17),
            label: const Text('Usar minha localização'),
          ),
        ),
        const SizedBox(height: 20),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: SizedBox(height: 420, child: _illustrativeMap()),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: _placePanel()),
            ],
          )
        else ...[
          SizedBox(height: 420, child: _illustrativeMap()),
          const SizedBox(height: 16),
          _placePanel(),
        ],
      ],
    );
  }

  Widget _illustrativeMap() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EBD8),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter())),
          Positioned(
            left: 14,
            top: 14,
            child: Chip(
              avatar: const Icon(Icons.location_on, color: _leafDark, size: 18),
              label: Text(_location, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: _line),
            ),
          ),
          const _MapPin(
            left: 0.18,
            top: 0.36,
            icon: Icons.spa,
            label: 'Horta da Vila',
          ),
          const _MapPin(
            left: 0.61,
            top: 0.25,
            icon: Icons.storefront,
            label: 'Padaria',
          ),
          const _MapPin(
            left: 0.48,
            top: 0.64,
            icon: Icons.volunteer_activism,
            label: 'Doação',
          ),
          const _MapPin(
            left: 0.75,
            top: 0.75,
            icon: Icons.location_on,
            label: 'Você',
          ),
        ],
      ),
    );
  }

  Widget _placePanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pontos de encontro',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 12),
          _placeRow(
            Icons.storefront,
            'Horta da Vila',
            'Alimentos frescos · 800 m',
            '3 itens',
          ),
          _placeRow(
            Icons.coffee_outlined,
            'Pão do Bairro',
            'Comércio parceiro · 1,4 km',
            '2 itens',
          ),
          _placeRow(
            Icons.volunteer_activism,
            'ONG Mesa Aberta',
            'Recebe doações · 2 km',
            'ONG',
          ),
          const SizedBox(height: 14),
          const _InfoNote(
            title: 'Retirada combinada',
            text: 'Converse com quem publicou para combinar local e horário.',
          ),
        ],
      ),
    );
  }

  Widget _messagesPage(bool wide) {
    final selected = _conversations.firstWhere(
      (chat) => chat.id == _chatId,
      orElse: () => _conversations.first,
    );
    return ListView(
      padding: const EdgeInsets.only(top: 26, bottom: 24),
      children: [
        _sectionHeader(
          'Conversas',
          'Combine a troca e a retirada com a comunidade.',
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: wide ? 520 : 570,
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 300, child: _conversationList(selected)),
                    const SizedBox(width: 14),
                    Expanded(child: _chatPanel(selected)),
                  ],
                )
              : _chatPanel(selected, showConversationSelector: true),
        ),
        const SizedBox(height: 20),
        const Text(
          'COMÉRCIOS E ORGANIZAÇÕES',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _placeRow(
          Icons.storefront,
          'Pão do Bairro',
          'Padaria parceira · excedentes diários',
          'Comércio',
        ),
        _placeRow(
          Icons.volunteer_activism,
          'ONG Mesa Aberta',
          'Rede de distribuição comunitária',
          'ONG',
        ),
      ],
    );
  }

  Widget _conversationList(Conversation selected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suas conversas',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: _conversations.map((chat) {
                final active = chat.id == selected.id;
                return ListTile(
                  selected: active,
                  selectedTileColor: _leafPale,
                  leading: CircleAvatar(
                    backgroundColor: _leafPale,
                    foregroundColor: _leafDark,
                    child: Icon(chat.icon, size: 19),
                  ),
                  title: Text(
                    chat.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    chat.messages.isEmpty ? '' : chat.messages.last.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    chat.time,
                    style: const TextStyle(fontSize: 10, color: _muted),
                  ),
                  onTap: () => setState(() => _chatId = chat.id),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatPanel(
    Conversation chat, {
    bool showConversationSelector = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          if (showConversationSelector)
            Padding(
              padding: const EdgeInsets.all(10),
              child: DropdownButtonFormField<String>(
                initialValue: chat.id,
                decoration: const InputDecoration(labelText: 'Suas conversas'),
                items: _conversations
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _chatId = value);
                },
              ),
            ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _leafPale,
              foregroundColor: _leafDark,
              child: Icon(chat.icon),
            ),
            title: Text(
              chat.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(chat.note, style: const TextStyle(fontSize: 11)),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                chat.image,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              chat.listing,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Conversa sobre um item publicado',
              style: TextStyle(fontSize: 10),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: chat.messages
                  .map((message) => _messageBubble(message))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(chat),
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _sendMessage(chat),
                  icon: const Icon(Icons.send, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: _leaf,
                    foregroundColor: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(ChatMessage message) {
    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: message.mine ? _leafPale : const Color(0xFFF1F1EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(Conversation chat) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      await _controller.sendMessage(chat, text, time: _timeNow());
    } catch (error) {
      if (mounted) _showNotice('Não foi possível salvar a mensagem: $error');
      return;
    }
    if (!mounted) return;
    _messageController.clear();
  }

  Widget _impactPage(bool wide) {
    final metrics = [
      ('shopping_basket', '384', 'itens reaproveitados'),
      ('savings', 'R\$ 12,4 mil', 'economizados pela comunidade'),
      ('recycling', '227 kg', 'de resíduos evitados'),
      ('groups', '61%', 'dos itens foram doações'),
    ];
    return ListView(
      padding: const EdgeInsets.only(top: 28, bottom: 30),
      children: [
        _sectionHeader(
          'Pequenos gestos, grande movimento',
          'Prévia demonstrativa do impacto da comunidade.',
          trailing: const _LocationLabel(
            icon: Icons.calendar_month,
            text: 'Este mês',
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: wide ? 1.55 : 1.35,
          children: List.generate(metrics.length, (index) {
            final item = metrics[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _metricIcon(item.$1),
                    color: index == 1 ? _coral : _leafDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.$3,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _impactDistribution()),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: _partnerPanel()),
            ],
          )
        else ...[
          _impactDistribution(),
          const SizedBox(height: 14),
          _partnerPanel(),
        ],
      ],
    );
  }

  IconData _metricIcon(String name) => switch (name) {
        'shopping_basket' => Icons.shopping_basket_outlined,
        'savings' => Icons.savings_outlined,
        'recycling' => Icons.recycling,
        _ => Icons.groups_outlined,
      };

  Widget _impactDistribution() {
    return _panel(
      title: 'Como a comunidade compartilha',
      subtitle: 'Distribuição das publicações neste mês',
      child: Column(
        children: [
          _impactBar('Doação', 61, _leafDark),
          _impactBar('Troca', 25, _coral),
          _impactBar('Venda', 14, const Color(0xFF6C9DB7)),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.asset(
                'image_1790257467990506-removebg-preview.png',
                width: 56,
                height: 56,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco, size: 44, color: _leafDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _InfoNote(
                  title: 'Impacto que chega mais longe',
                  text:
                      'Comércios locais e ONGs podem publicar excedentes e coordenar doações.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _impactBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 9,
                backgroundColor: _line,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '$value%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerPanel() {
    return _panel(
      title: 'Rede de parceiros',
      subtitle: 'Quem faz circular coisas boas no bairro',
      child: Column(
        children: [
          _partnerRow(
            Icons.storefront,
            'Pão do Bairro',
            'Padaria · 12 itens compartilhados',
          ),
          _partnerRow(
            Icons.spa_outlined,
            'Horta da Vila',
            'Horta comunitária · 28 itens',
          ),
          _partnerRow(
            Icons.volunteer_activism,
            'ONG Mesa Aberta',
            'Organização social · 3 pontos de coleta',
          ),
        ],
      ),
    );
  }

  Widget _partnerRow(IconData icon, String name, String note) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _leafPale,
        foregroundColor: _leafDark,
        child: Icon(icon, size: 19),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(note, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _profilePage(bool wide) {
    final mine = _listings.where((item) => item.isMine).toList();
    final active = mine.where((item) => !item.completed).toList();
    final completed = mine.where((item) => item.completed).toList();
    final query = _profileSearchController.text.trim().toLowerCase();
    final filtered = mine.where((item) {
      final matchesStatus =
          _profileStatus == 'Ativos' ? !item.completed : item.completed;
      final matchesMode = _profileMode == 'Todos' || item.mode == _profileMode;
      final searchable =
          '${item.title} ${item.category} ${item.mode} ${item.place} ${item.description}'
              .toLowerCase();
      return matchesStatus &&
          matchesMode &&
          (query.isEmpty || searchable.contains(query));
    }).toList();
    final displayName = _signedIn ? _accountName : 'Minha conta';
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();

    return ListView(
      padding: const EdgeInsets.only(top: 28, bottom: 30),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: _leafPale,
                foregroundColor: _leafDark,
                child: Text(
                  initials,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: wide ? 470 : 230,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _signedIn ? 'SEU ESPAÇO NA COMUNIDADE' : 'SEU ESPAÇO',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: GoogleFonts.dmSerifDisplay(fontSize: 26),
                    ),
                    Text(
                      _accountEmail.isEmpty
                          ? 'Organize seus anúncios e acompanhe as conversas.'
                          : '$_accountEmail · $_location',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _account,
                child: Text(
                  _signedIn ? 'Dados da conta' : 'Entrar ou criar conta',
                ),
              ),
              FilledButton.icon(
                onPressed: _publish,
                icon: const Icon(Icons.add),
                label: const Text('Publicar item'),
                style: FilledButton.styleFrom(
                  backgroundColor: _leaf,
                  foregroundColor: _ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Resumo da sua atividade',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _profileStat(
              Icons.inventory_2_outlined,
              active.length,
              'Ativos',
              () => setState(() {
                _profileStatus = 'Ativos';
                _profileMode = 'Todos';
                _profileSearchController.clear();
              }),
            ),
            _profileStat(
              Icons.archive_outlined,
              completed.length,
              'Concluídos',
              () => setState(() {
                _profileStatus = 'Histórico';
                _profileMode = 'Todos';
                _profileSearchController.clear();
              }),
            ),
            _profileStat(
              Icons.repeat,
              active.where((item) => item.mode == 'Troca').length,
              'Trocas ativas',
              () => setState(() {
                _profileStatus = 'Ativos';
                _profileMode = 'Troca';
                _profileSearchController.clear();
              }),
            ),
            _profileStat(
              Icons.payments_outlined,
              active.where((item) => item.mode == 'Venda').length,
              'Vendas ativas',
              () => setState(() {
                _profileStatus = 'Ativos';
                _profileMode = 'Venda';
                _profileSearchController.clear();
              }),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionHeader(
          'Meus anúncios',
          'Edite os detalhes ou marque como concluído quando já tiver sido combinado.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _profileSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: _muted),
            hintText: 'Buscar nos meus anúncios',
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: () {
                      _profileSearchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _profileChip(
              'Ativos',
              '${active.length}',
              _profileStatus == 'Ativos',
              () => setState(() => _profileStatus = 'Ativos'),
            ),
            _profileChip(
              'Histórico',
              '${completed.length}',
              _profileStatus == 'Histórico',
              () => setState(() => _profileStatus = 'Histórico'),
            ),
            const SizedBox(width: 12),
            for (final mode in ['Todos', 'Troca', 'Venda', 'Doação'])
              ChoiceChip(
                label: Text(_modeLabel(mode)),
                selected: _profileMode == mode,
                onSelected: (_) => setState(() => _profileMode = mode),
                selectedColor: _leafPale,
                side: BorderSide(color: _profileMode == mode ? _leaf : _line),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _panel(
            title: '',
            child: Column(
              children: [
                Text(
                  mine.isEmpty
                      ? 'Você ainda não publicou anúncios.'
                      : query.isNotEmpty
                          ? 'Nenhum anúncio corresponde a “${_profileSearchController.text.trim()}”.'
                          : 'Não há anúncios ${_profileStatus.toLowerCase()} neste filtro.',
                  style: const TextStyle(color: _muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: mine.isEmpty
                      ? _publish
                      : () => setState(() {
                            _profileStatus = _profileStatus == 'Ativos'
                                ? 'Histórico'
                                : 'Ativos';
                            _profileMode = 'Todos';
                            _profileSearchController.clear();
                          }),
                  icon: Icon(mine.isEmpty ? Icons.add : Icons.filter_alt_off),
                  label: Text(
                    mine.isEmpty
                        ? 'Publicar primeiro anúncio'
                        : 'Limpar filtros',
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map(_profileListing),
      ],
    );
  }

  String _modeLabel(String mode) => switch (mode) {
        'Troca' => 'Trocas',
        'Venda' => 'Vendas',
        'Doação' => 'Doações',
        _ => 'Todos',
      };

  Widget _profileChip(
    String label,
    String count,
    bool selected,
    VoidCallback onTap,
  ) {
    return ActionChip(
      label: Text('$label  $count'),
      onPressed: onTap,
      backgroundColor: selected ? _leafPale : Colors.white,
      side: BorderSide(color: selected ? _leaf : _line),
    );
  }

  Widget _profileStat(
    IconData icon,
    int value,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, color: _leafDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 12, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileListing(Listing item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: item.imageBytes == null
                      ? Image.network(
                          item.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _leafPale,
                            child:
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      : Image.memory(item.imageBytes!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} · ${item.mode} · ${item.price}',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    if (item.completedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: _Tag(
                          label: 'Concluído em ${_date(item.completedAt!)}',
                          color: _leafPale,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: () => _editListing(item),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Editar anúncio'),
              ),
              if (!item.completed)
                FilledButton.tonalIcon(
                  onPressed: () => _completeListing(item),
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('Marcar como concluído'),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(
                    'Anúncio concluído',
                    style: TextStyle(
                      color: _leafDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completeListing(Listing item) async {
    final completedAt = DateTime.now();
    try {
      await _controller.completeListing(item, completedAt);
    } catch (error) {
      if (mounted) _showNotice('Não foi possível concluir o anúncio: $error');
      return;
    }
    if (!mounted) return;
    _showNotice('Anúncio movido para o histórico.');
  }

  Widget _sectionHeader(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSerifDisplay(fontSize: 25, height: 1.15),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing),
        ],
      ],
    );
  }

  Widget _placeRow(IconData icon, String name, String note, String tag) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _leafPale,
        foregroundColor: _leafDark,
        child: Icon(icon, size: 19),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(note, style: const TextStyle(fontSize: 11)),
      trailing: _Tag(label: tag, color: _leafPale),
    );
  }

  Widget _panel({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
          if (title.isNotEmpty || subtitle != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _showOffer(Listing item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    _listingImage(item, height: 230),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton.filled(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Tag(label: item.mode, color: _leafPale),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: GoogleFonts.dmSerifDisplay(fontSize: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(item.description),
                      const SizedBox(height: 12),
                      Text(
                        '${item.owner} · ${item.place} · ${item.distance}',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      if (item.mode == 'Troca') ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Aceita em troca',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: item.acceptedCategories.isEmpty
                              ? [const Text('Aberta a propostas de alimentos.')]
                              : item.acceptedCategories
                                  .map(
                                    (category) => _Tag(
                                      label: category,
                                      color: _leafPale,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.price,
                              style: const TextStyle(
                                color: _leafDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openConversation(item);
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Tenho interesse'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _ink,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openConversation(Listing item) async {
    late final Conversation conversation;
    try {
      conversation = await _controller.openConversation(item);
    } catch (error) {
      if (mounted) _showNotice('Não foi possível iniciar a conversa: $error');
      return;
    }
    if (!mounted) return;
    setState(() {
      _chatId = conversation.id;
      _tab = 2;
    });
    _showNotice('Conversa iniciada. Combine a retirada por aqui.');
  }

  Future<void> _publish() async {
    if (!_signedIn) {
      await _account(forPublishing: true);
      if (!mounted || !_signedIn) return;
    }

    final result = await showDialog<Listing>(
      context: context,
      builder: (context) => PublishDialog(
        location: _location,
        owner: _signedIn ? _accountName : 'Você',
      ),
    );
    if (result == null) return;
    try {
      await _controller.saveListing(result);
    } catch (error) {
      if (mounted) _showNotice('Não foi possível salvar o anúncio: $error');
      return;
    }
    if (!mounted) return;
    setState(() {
      _tab = 0;
      _category = 'Tudo';
      _mode = 'Todos os tipos';
      _searchController.clear();
    });
    _showNotice('Seu anúncio já está na comunidade.');
  }

  Future<void> _editListing(Listing item) async {
    final result = await showDialog<Listing>(
      context: context,
      builder: (context) => PublishDialog(
        location: item.place,
        owner: item.owner,
        initialListing: item,
      ),
    );
    if (result == null) return;
    try {
      await _controller.saveListing(result);
    } catch (error) {
      if (mounted) _showNotice('Não foi possível atualizar o anúncio: $error');
      return;
    }
    if (!mounted) return;
    _showNotice('Anúncio atualizado com sucesso.');
  }

  Future<void> _account({bool forPublishing = false}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AccountDialog(
        signedIn: _signedIn,
        accountName: _accountName,
        accountEmail: _accountEmail,
        forPublishing: forPublishing,
      ),
    );
    if (result == null) return;
    final name = result['name'] ?? 'Minha conta';
    final email = result['email'] ?? '';
    try {
      await _controller.saveAccountProfile(
        AccountProfile(
          name: name,
          email: email,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showNotice('Não foi possível salvar os dados da conta: $error');
      }
      return;
    }
    if (!mounted) return;
    _showNotice('Acesso demonstrativo iniciado.');
  }

  Future<void> _locate() async {
    _showNotice('Solicitando permissão de localização...');
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showNotice('Ative a localização do dispositivo e tente novamente.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showNotice(
          'Não foi possível acessar sua localização. Confira as permissões.',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _location =
            '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
      });
      _showNotice('Localização atualizada.');
    } catch (error) {
      _showNotice('Não foi possível atualizar a localização: $error');
    }
  }
}

class PublishDialog extends StatefulWidget {
  const PublishDialog({
    required this.location,
    required this.owner,
    this.initialListing,
    super.key,
  });

  final String location;
  final String owner;
  final Listing? initialListing;

  @override
  State<PublishDialog> createState() => _PublishDialogState();
}

class _PublishDialogState extends State<PublishDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _place = TextEditingController();
  final _price = TextEditingController();
  final Set<String> _accepted = {};
  late String _category;
  late String _mode;
  Uint8List? _imageBytes;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialListing;
    _title.text = item?.title ?? '';
    _description.text = item?.description ?? '';
    _place.text = item?.place ?? widget.location;
    _price.text = item != null && item.mode == 'Venda' ? item.price : '';
    _category = item?.category ?? listingCategories[1];
    _mode = item?.mode ?? 'Doação';
    if (item != null) _accepted.addAll(item.acceptedCategories);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _place.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _notice('Escolha uma imagem de até 5 MB.');
        return;
      }
      setState(() => _imageBytes = bytes);
    } catch (error) {
      _notice('Não foi possível carregar essa imagem: $error');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.initialListing;
    final listing = Listing(
      id: existing?.id ?? 'item-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      category: _category,
      mode: _mode,
      place: _place.text.trim(),
      distance: existing?.distance ?? 'perto de você',
      price: _mode == 'Doação'
          ? 'Grátis'
          : _mode == 'Troca'
              ? 'Por troca'
              : _price.text.trim().isEmpty
                  ? 'A combinar'
                  : _price.text.trim(),
      owner: existing?.owner ?? widget.owner,
      description: _description.text.trim().isEmpty
          ? 'Item compartilhado pela comunidade ShareBite.'
          : _description.text.trim(),
      image: existing?.image ?? samplePhoto('photo-1542838132-92c53300491e'),
      imageBytes: _imageBytes ?? existing?.imageBytes,
      acceptedCategories: _mode == 'Troca' ? _accepted.toList() : const [],
      isMine: true,
      completed: existing?.completed ?? false,
      completedAt: existing?.completedAt,
    );
    Navigator.pop(context, listing);
  }

  @override
  Widget build(BuildContext context) {
    final initialListing = widget.initialListing;
    final imagePreview = _imageBytes != null
        ? Image.memory(_imageBytes!, height: 100, fit: BoxFit.cover)
        : initialListing?.imageBytes != null
            ? Image.memory(
                initialListing!.imageBytes!,
                height: 100,
                fit: BoxFit.cover,
              )
            : initialListing == null
                ? null
                : Image.network(
                    initialListing.image,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  );
    return AlertDialog(
      title: Text(
        widget.initialListing == null
            ? 'Compartilhe algo bom'
            : 'Editar anúncio',
        style: GoogleFonts.dmSerifDisplay(fontSize: 25),
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      widget.initialListing == null
                          ? 'Publique um excedente para alguém aproveitar no seu bairro.'
                          : 'Atualize as informações para manter seu anúncio em dia.',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ),
                _formField(
                  'O que você está oferecendo?',
                  TextFormField(
                    controller: _title,
                    maxLength: 70,
                    decoration: const InputDecoration(
                      hintText: 'Ex.: frutas da feira de hoje',
                      counterStyle: TextStyle(fontSize: 10),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o nome do item.'
                        : null,
                  ),
                ),
                const SizedBox(height: 13),
                _formField(
                  'Descrição',
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Conte sobre o item, estado ou validade.',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                _formField(
                  'Foto do item (opcional)',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _pickingImage ? null : _pickImage,
                          icon: _pickingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                          label: Text(
                            widget.initialListing == null
                                ? 'Selecionar imagem'
                                : 'Trocar imagem',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Imagem de até 5 MB.',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                      if (imagePreview != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: imagePreview,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _formField(
                        'Categoria',
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(),
                          items: listingCategories
                              .skip(1)
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _category = value!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _formField(
                        'Modalidade',
                        DropdownButtonFormField<String>(
                          initialValue: _mode,
                          decoration: const InputDecoration(),
                          items: listingModes
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _mode = value!),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_mode == 'Troca') ...[
                  const SizedBox(height: 13),
                  _formField(
                    'Aceita em troca',
                    Wrap(
                      spacing: 4,
                      children: listingCategories.skip(1).map((category) {
                        return FilterChip(
                          label: Text(category),
                          selected: _accepted.contains(category),
                          onSelected: (selected) => setState(() {
                            selected
                                ? _accepted.add(category)
                                : _accepted.remove(category);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                _formField(
                  'Bairro ou localização',
                  TextFormField(
                    controller: _place,
                    decoration: const InputDecoration(),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe a localização.'
                        : null,
                  ),
                ),
                if (_mode == 'Venda') ...[
                  const SizedBox(height: 13),
                  _formField(
                    'Valor (se houver)',
                    TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: R\$ 10',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _leaf,
            foregroundColor: _ink,
          ),
          child: Text(
            widget.initialListing == null
                ? 'Publicar item'
                : 'Salvar alterações',
          ),
        ),
      ],
    );
  }

  Widget _formField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        field,
      ],
    );
  }
}

class AccountDialog extends StatefulWidget {
  const AccountDialog({
    required this.signedIn,
    required this.accountName,
    required this.accountEmail,
    this.forPublishing = false,
    super.key,
  });

  final bool signedIn;
  final String accountName;
  final String accountEmail;
  final bool forPublishing;

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.signedIn
            ? 'Olá, ${widget.accountName}'
            : widget.forPublishing
                ? 'Entre para publicar'
                : 'Que bom ter você por aqui',
        style: GoogleFonts.dmSerifDisplay(fontSize: 24),
      ),
      content: SizedBox(
        width: 440,
        child: widget.signedIn
            ? Text(
                'Sua conta de demonstração está ativa neste navegador.\n${widget.accountEmail}',
                style: const TextStyle(color: _muted),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            widget.forPublishing
                                ? 'Entre ou crie sua conta para publicar um anúncio. Depois do acesso, você poderá preencher os detalhes do item.'
                                : 'Entre para conversar com a vizinhança ou crie sua conta.',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Entrar')),
                          ButtonSegment(
                            value: true,
                            label: Text('Criar conta'),
                          ),
                        ],
                        selected: {_register},
                        onSelectionChanged: (selection) =>
                            setState(() => _register = selection.first),
                      ),
                      if (_register) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome',
                          ),
                          validator: (value) => _register &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Informe seu nome.'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Informe um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Senha'),
                        validator: (value) => value == null || value.length < 6
                            ? 'Use pelo menos 6 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Acesso demonstrativo. Autenticação real requer backend.',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        if (!widget.signedIn)
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final email = _email.text.trim();
              Navigator.pop<Map<String, String>>(context, {
                'name': _register ? _name.text.trim() : email.split('@').first,
                'email': email,
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: _leaf,
              foregroundColor: _ink,
            ),
            child: Text(_register ? 'Criar minha conta' : 'Entrar'),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      );
}

class _LocationLabel extends StatelessWidget {
  const _LocationLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _leafDark),
          const SizedBox(width: 5),
          Flexible(
            child:
                Text(text, style: const TextStyle(color: _muted, fontSize: 11)),
          ),
        ],
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _leafPale.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: _leafDark),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(text,
                      style: const TextStyle(fontSize: 11, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.left,
    required this.top,
    required this.icon,
    required this.label,
  });

  final double left;
  final double top;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Align(
          alignment: Alignment(left * 2 - 1, top * 2 - 1),
          child: Material(
            elevation: 2,
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: _leafDark),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFF8F8F1)
      ..strokeWidth = 17
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = const Color(0xFFF8F8F1)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-20, size.height * 0.32),
      Offset(size.width + 20, size.height * 0.6),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, -20),
      Offset(size.width * 0.66, size.height + 20),
      road,
    );
    canvas.drawLine(
      Offset(-10, size.height * 0.78),
      Offset(size.width * 0.93, size.height * 0.12),
      thinRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, -10),
      Offset(size.width * 0.37, size.height + 10),
      thinRoad,
    );
    final park = Paint()..color = const Color(0xFFD6E2C3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.7,
          size.height * 0.44,
          size.width * 0.2,
          size.height * 0.18,
        ),
        const Radius.circular(18),
      ),
      park,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _timeNow() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
