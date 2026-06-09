import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/features/auth/providers/auth_provider.dart';

final userCompanyIdProvider = FutureProvider<String>((ref) async {
  debugPrint('[DEBUG] userCompanyIdProvider started');
  final user = ref.watch(currentUserProvider);
  debugPrint('[DEBUG] userCompanyIdProvider currentUser: ${user?.uid}');
  return user?.uid ?? 'default-company';
});
