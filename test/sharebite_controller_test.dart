import 'package:flutter_test/flutter_test.dart';
import 'package:sharebite/controllers/sharebite_controller.dart';
import 'package:sharebite/data/sharebite_repository.dart';
import 'package:sharebite/models/sharebite_models.dart';

void main() {
  test('load restores listings, saved items, and account profile', () async {
    final listing = _listing('item-1');
    final repository = _FakeShareBiteRepository(
      snapshot: ShareBiteSnapshot(
        listings: [listing],
        savedListingIds: {'item-1'},
        conversations: const [],
        accountProfile: const AccountProfile(
          name: 'Joana',
          email: 'joana@example.com',
        ),
      ),
    );
    final controller = ShareBiteController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.listings, [listing]);
    expect(controller.savedListingIds, {'item-1'});
    expect(controller.isSignedIn, isTrue);
    expect(controller.accountName, 'Joana');
    expect(controller.accountEmail, 'joana@example.com');
  });

  test('failed favorite persistence leaves state unchanged', () async {
    final repository = _FakeShareBiteRepository()..failFavoriteUpdate = true;
    final controller = ShareBiteController(repository: repository);
    addTearDown(controller.dispose);

    await expectLater(controller.toggleSaved('item-1'), throwsStateError);

    expect(controller.savedListingIds, isEmpty);
  });

  test('saving a listing updates it without adding a duplicate', () async {
    final original = _listing('item-1');
    final repository = _FakeShareBiteRepository(
      snapshot: ShareBiteSnapshot(
        listings: [original],
        savedListingIds: const {},
        conversations: const [],
        accountProfile: null,
      ),
    );
    final controller = ShareBiteController(repository: repository);
    addTearDown(controller.dispose);
    await controller.load();
    final updated = _listing('item-1', title: 'Título atualizado');

    await controller.saveListing(updated);

    expect(controller.listings, hasLength(1));
    expect(controller.listings.single.title, 'Título atualizado');
  });
}

Listing _listing(String id, {String title = 'Anúncio'}) => Listing(
      id: id,
      title: title,
      category: 'Frutas',
      mode: 'Doação',
      place: 'Pinheiros',
      distance: '500 m',
      price: 'Grátis',
      owner: 'Joana',
      description: 'Descrição',
      image: '',
    );

class _FakeShareBiteRepository implements ShareBiteRepository {
  _FakeShareBiteRepository({
    ShareBiteSnapshot? snapshot,
  }) : snapshot = snapshot ??
            const ShareBiteSnapshot(
              listings: [],
              savedListingIds: {},
              conversations: [],
              accountProfile: null,
            );

  final ShareBiteSnapshot snapshot;
  bool failFavoriteUpdate = false;

  @override
  Future<ShareBiteSnapshot> loadInitialData() async => snapshot;

  @override
  Future<void> setListingSaved(String id, bool saved) async {
    if (failFavoriteUpdate) throw StateError('Persistence failed');
  }

  @override
  Future<void> saveMessage(String conversationId, ChatMessage message) async {}

  @override
  Future<void> completeListing(String id, DateTime completedAt) async {}

  @override
  Future<void> saveListing(Listing listing) async {}

  @override
  Future<void> saveConversation(Conversation conversation) async {}

  @override
  Future<void> saveAccountProfile(AccountProfile profile) async {}
}
