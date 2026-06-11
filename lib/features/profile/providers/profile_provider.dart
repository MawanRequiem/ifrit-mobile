import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';

/// Simple profile provider that reads user info from auth state.
final profileProvider = Provider<AuthState>((ref) {
  return ref.watch(authProvider);
});