import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class Listing {
  Listing({
    required this.id,
    required this.title,
    required this.category,
    required this.mode,
    required this.place,
    required this.distance,
    required this.price,
    required this.owner,
    required this.description,
    required this.image,
    this.acceptedCategories = const [],
    this.isMine = false,
    this.completed = false,
    this.imageBytes,
    this.completedAt,
  });

  final String id;
  final String title;
  final String category;
  final String mode;
  final String place;
  final String distance;
  final String price;
  final String owner;
  final String description;
  final String image;
  final List<String> acceptedCategories;
  final bool isMine;
  bool completed;
  Uint8List? imageBytes;
  DateTime? completedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'mode': mode,
        'place': place,
        'distance': distance,
        'price': price,
        'owner': owner,
        'description': description,
        'image': image,
        'accepted_categories': jsonEncode(acceptedCategories),
        'is_mine': isMine ? 1 : 0,
        'completed': completed ? 1 : 0,
        'image_bytes': imageBytes,
        'completed_at': completedAt?.toIso8601String(),
      };

  factory Listing.fromMap(Map<String, Object?> row) {
    final completedAt = row['completed_at'] as String?;
    return Listing(
      id: row['id']! as String,
      title: row['title']! as String,
      category: row['category']! as String,
      mode: row['mode']! as String,
      place: row['place']! as String,
      distance: row['distance']! as String,
      price: row['price']! as String,
      owner: row['owner']! as String,
      description: row['description']! as String,
      image: row['image']! as String,
      acceptedCategories:
          (jsonDecode(row['accepted_categories']! as String) as List<dynamic>)
              .cast<String>(),
      isMine: row['is_mine'] == 1,
      completed: row['completed'] == 1,
      imageBytes: row['image_bytes'] as Uint8List?,
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
    );
  }
}

class ChatMessage {
  ChatMessage(this.text, this.mine, this.time);

  final String text;
  final bool mine;
  final String time;

  Map<String, Object?> toMap() => {
        'text': text,
        'mine': mine ? 1 : 0,
        'time': time,
      };
}

class Conversation {
  Conversation({
    required this.id,
    required this.name,
    required this.note,
    required this.listing,
    required this.image,
    required this.messages,
    this.time = 'Agora',
    this.icon = Icons.person_outline,
  });

  final String id;
  final String name;
  final String note;
  final String listing;
  final String image;
  final IconData icon;
  final List<ChatMessage> messages;
  String time;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'note': note,
        'listing': listing,
        'image': image,
        'time': time,
        'icon_code_point': icon.codePoint,
      };
}

IconData conversationIcon(int codePoint) {
  if (codePoint == Icons.spa_outlined.codePoint) return Icons.spa_outlined;
  if (codePoint == Icons.storefront_outlined.codePoint) {
    return Icons.storefront_outlined;
  }
  return Icons.person_outline;
}
