import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/features/auth/providers/auth_provider.dart';

final userCompanyIdProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  return user?.uid ?? 'default-company';
});
