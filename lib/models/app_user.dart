import 'package:supabase_flutter/supabase_flutter.dart';

/// Itilizatè app la — vlope sou `User` Supabase la.
class AppUser {
  final String id;
  final String email;
  final String? fullName;

  const AppUser({required this.id, required this.email, this.fullName});

  factory AppUser.fromSupabase(User user) => AppUser(
    id: user.id,
    email: user.email ?? '',
    fullName: user.userMetadata?['full_name'] as String?,
  );
}
