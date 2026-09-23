import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Mapé non icon (string nan DB) → IconData Lucide.
IconData lucideIcon(String? name) => switch (name) {
  'cog' => LucideIcons.cog,
  'disc' => LucideIcons.disc,
  'battery' => LucideIcons.battery,
  'droplet' => LucideIcons.droplet,
  'tag' => LucideIcons.tag,
  'car' => LucideIcons.car,
  'wrench' => LucideIcons.wrench,
  'gauge' => LucideIcons.gauge,
  'fuel' => LucideIcons.fuel,
  'sparkles' => LucideIcons.sparkles,
  'zap' => LucideIcons.zap,
  'shieldCheck' => LucideIcons.shieldCheck,
  'store' => LucideIcons.store,
  'bike' => LucideIcons.bike,
  _ => LucideIcons.package,
};

/// Lis icon yo disponib pou kategori (admin dropdown).
const categoryIconOptions = <String>[
  'cog',
  'disc',
  'battery',
  'droplet',
  'tag',
  'car',
  'wrench',
  'gauge',
  'fuel',
  'sparkles',
  'zap',
  'shieldCheck',
  'store',
  'bike',
  'package',
];
