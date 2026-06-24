import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/enums/user_role.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final authState = await ref.read(authStateProvider.future);
      if (!mounted) return;
      
      if (authState == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Check tenant context and user role
      final tenantContext = await ref.read(tenantContextProvider.future);
      final userData = await ref.read(userDataProvider.future);
      final role = UserRole.fromString(userData?['role'] as String?);
      if (!mounted) return;

      if (role == UserRole.admin || tenantContext != null) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/company-access-required');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}