import 'package:flutter/material.dart';

IconData companionInterestIcon(String interest) => switch (interest) {
  'Gardening' => Icons.spa_outlined,
  'Music' => Icons.music_note,
  'Books' => Icons.auto_stories_outlined,
  'Movies' => Icons.movie_outlined,
  'Culture' => Icons.public_outlined,
  'Traditional Food' => Icons.restaurant_outlined,
  _ => Icons.favorite_border,
};
