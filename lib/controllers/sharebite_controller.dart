import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/sharebite_repository.dart';
import '../models/sharebite_models.dart';

class ShareBiteController extends ChangeNotifier {
  ShareBiteController({required ShareBiteRepository repository})
      : _repository = repository;

  final ShareBiteRepository _repository;
  final List<Listing> _listings = [];
  final Set<String> _savedListingIds = {};
  final List<Conversation> _conversations = [];
  bool _isLoading = true;
  Object? _error;
  String _accountName = 'Minha conta';
  String _accountEmail = '';
  bool _isSignedIn = false;

  List<Listing> get listings => UnmodifiableListView(_listings);
  Set<String> get savedListingIds => UnmodifiableSetView(_savedListingIds);
  List<Conversation> get conversations => UnmodifiableListView(_conversations);
  bool get isLoading => _isLoading;
  Object? get error => _error;
  String get accountName => _accountName;
  String get accountEmail => _accountEmail;
  bool get isSignedIn => _isSignedIn;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _repository.loadInitialData();
      _listings
        ..clear()
        ..addAll(snapshot.listings);
      _savedListingIds
        ..clear()
        ..addAll(snapshot.savedListingIds);
      _conversations
        ..clear()
        ..addAll(snapshot.conversations);
      final profile = snapshot.accountProfile;
      _isSignedIn = profile != null;
      _accountName = profile?.name ?? 'Minha conta';
      _accountEmail = profile?.email ?? '';
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSaved(String id) async {
    final saved = !_savedListingIds.contains(id);
    await _repository.setListingSaved(id, saved);
    if (saved) {
      _savedListingIds.add(id);
    } else {
      _savedListingIds.remove(id);
    }
    notifyListeners();
  }

  Future<ChatMessage?> sendMessage(
    Conversation conversation,
    String text, {
    required String time,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return null;
    final message = ChatMessage(trimmedText, true, time);
    await _repository.saveMessage(conversation.id, message);
    conversation.messages.add(message);
    conversation.time = message.time;
    notifyListeners();
    return message;
  }

  Future<void> completeListing(Listing listing, DateTime completedAt) async {
    await _repository.completeListing(listing.id, completedAt);
    listing.completed = true;
    listing.completedAt = completedAt;
    notifyListeners();
  }

  Future<void> saveListing(Listing listing) async {
    await _repository.saveListing(listing);
    final index = _listings.indexWhere((item) => item.id == listing.id);
    if (index == -1) {
      _listings.insert(0, listing);
    } else {
      _listings[index] = listing;
    }
    notifyListeners();
  }

  Future<Conversation> openConversation(Listing listing) async {
    final id = 'item-${listing.id}';
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }

    final conversation = Conversation(
      id: id,
      name: listing.owner,
      note: 'Sobre: ${listing.title}',
      listing: listing.title,
      image: listing.image,
      messages: [
        ChatMessage(
          'Olá! Tenho interesse em “${listing.title}”. Ainda está disponível?',
          true,
          'Agora',
        ),
      ],
    );
    await _repository.saveConversation(conversation);
    _conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  Future<void> saveAccountProfile(AccountProfile profile) async {
    await _repository.saveAccountProfile(profile);
    _isSignedIn = true;
    _accountName = profile.name;
    _accountEmail = profile.email;
    notifyListeners();
  }
}
