import '../models/sharebite_models.dart';
import 'sharebite_database.dart';
import 'sample_data.dart';

class AccountProfile {
  const AccountProfile({required this.name, required this.email});

  final String name;
  final String email;
}

class ShareBiteSnapshot {
  const ShareBiteSnapshot({
    required this.listings,
    required this.savedListingIds,
    required this.conversations,
    required this.accountProfile,
  });

  final List<Listing> listings;
  final Set<String> savedListingIds;
  final List<Conversation> conversations;
  final AccountProfile? accountProfile;
}

abstract interface class ShareBiteRepository {
  Future<ShareBiteSnapshot> loadInitialData();
  Future<void> setListingSaved(String id, bool saved);
  Future<void> saveMessage(String conversationId, ChatMessage message);
  Future<void> completeListing(String id, DateTime completedAt);
  Future<void> saveListing(Listing listing);
  Future<void> saveConversation(Conversation conversation);
  Future<void> saveAccountProfile(AccountProfile profile);
}

class SqliteShareBiteRepository implements ShareBiteRepository {
  SqliteShareBiteRepository({ShareBiteDatabase? database})
      : _database = database ?? ShareBiteDatabase.instance;

  final ShareBiteDatabase _database;

  @override
  Future<ShareBiteSnapshot> loadInitialData() async {
    await _database.seedIfEmpty(
      listings: sampleListings().map((listing) => listing.toMap()).toList(),
      conversations: sampleConversations()
          .map(
            (conversation) => {
              ...conversation.toMap(),
              'messages': conversation.messages
                  .map((message) => message.toMap())
                  .toList(),
            },
          )
          .toList(),
    );

    final results = await Future.wait<Object?>([
      _database.loadListings(),
      _database.loadSavedListingIds(),
      _database.loadAccountProfile(),
      _database.loadConversations(),
    ]);

    final listings = (results[0] as List<Map<String, Object?>>)
        .map(Listing.fromMap)
        .toList();
    final savedListingIds = results[1] as Set<String>;
    final profileRow = results[2] as Map<String, Object?>?;
    final conversationRows = results[3] as List<Map<String, Object?>>;

    return ShareBiteSnapshot(
      listings: listings,
      savedListingIds: savedListingIds,
      accountProfile: profileRow == null
          ? null
          : AccountProfile(
              name: profileRow['name']! as String,
              email: profileRow['email']! as String,
            ),
      conversations: conversationRows.map(_conversationFromRow).toList(),
    );
  }

  Conversation _conversationFromRow(Map<String, Object?> row) {
    final messages = (row['messages']! as List<Map<String, Object?>>)
        .map(
          (message) => ChatMessage(
            message['text']! as String,
            message['mine'] == 1,
            message['time']! as String,
          ),
        )
        .toList();
    return Conversation(
      id: row['id']! as String,
      name: row['name']! as String,
      note: row['note']! as String,
      listing: row['listing']! as String,
      image: row['image']! as String,
      time: row['time']! as String,
      icon: conversationIcon(row['icon_code_point']! as int),
      messages: messages,
    );
  }

  @override
  Future<void> setListingSaved(String id, bool saved) =>
      _database.setListingSaved(id, saved);

  @override
  Future<void> saveMessage(String conversationId, ChatMessage message) =>
      _database.saveMessage(conversationId, message.toMap());

  @override
  Future<void> completeListing(String id, DateTime completedAt) =>
      _database.completeListing(id, completedAt);

  @override
  Future<void> saveListing(Listing listing) =>
      _database.saveListing(listing.toMap());

  @override
  Future<void> saveConversation(Conversation conversation) =>
      _database.saveConversation(
        conversation.toMap(),
        conversation.messages.map((message) => message.toMap()).toList(),
      );

  @override
  Future<void> saveAccountProfile(AccountProfile profile) =>
      _database.saveAccountProfile(name: profile.name, email: profile.email);
}
