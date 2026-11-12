import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharebite/models/sharebite_models.dart';

void main() {
  group('Listing persistence mapping', () {
    test('preserves listing fields, categories, image bytes, and completion',
        () {
      final completedAt = DateTime.utc(2026, 11, 11, 12);
      final listing = Listing(
        id: 'item-1',
        title: 'Maçãs',
        category: 'Frutas',
        mode: 'Troca',
        place: 'Pinheiros',
        distance: '800 m',
        price: 'Por troca',
        owner: 'Joana',
        description: 'Maçãs frescas',
        image: 'https://example.com/image.jpg',
        acceptedCategories: ['Pães e massas'],
        isMine: true,
        completed: true,
        imageBytes: Uint8List.fromList([1, 2, 3]),
        completedAt: completedAt,
      );

      final restored = Listing.fromMap(listing.toMap());

      expect(restored.id, listing.id);
      expect(restored.title, listing.title);
      expect(restored.acceptedCategories, listing.acceptedCategories);
      expect(restored.isMine, isTrue);
      expect(restored.completed, isTrue);
      expect(restored.imageBytes, orderedEquals([1, 2, 3]));
      expect(restored.completedAt, completedAt);
    });
  });

  test('message mapping stores ownership as an SQLite integer', () {
    expect(ChatMessage('Olá', true, 'Agora').toMap(), {
      'text': 'Olá',
      'mine': 1,
      'time': 'Agora',
    });
    expect(ChatMessage('Oi', false, 'Ontem').toMap()['mine'], 0);
  });

  test('conversation mapping keeps icon metadata separate from messages', () {
    final conversation = Conversation(
      id: 'chat-1',
      name: 'Horta da Vila',
      note: 'Pinheiros',
      listing: 'Cesta',
      image: 'https://example.com/image.jpg',
      icon: Icons.spa_outlined,
      messages: [ChatMessage('Olá', true, 'Agora')],
    );

    final row = conversation.toMap();

    expect(row['icon_code_point'], Icons.spa_outlined.codePoint);
    expect(row.containsKey('messages'), isFalse);
  });
}
