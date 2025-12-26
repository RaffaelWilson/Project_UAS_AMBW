import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/login_screen.dart';

class RoleAwareWrapper extends StatefulWidget {
  const RoleAwareWrapper({super.key});

  @override
  State<RoleAwareWrapper> createState() => _RoleAwareWrapperState();
}

class _RoleAwareWrapperState extends State<RoleAwareWrapper> {
  String? _previousRole;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        print('=== ROLE AWARE WRAPPER ===');
        print('Is Logged In: ${auth.isLoggedIn}');
        print('User Profile: ${auth.userProfile?.toJson()}');
        print('Is Admin: ${auth.isAdmin}');
        print('Current Role: ${auth.userProfile?.role}');
        
        if (!auth.isLoggedIn) {
          _previousRole = null;
          return const LoginScreen();
        }

        if (auth.userProfile == null) {
          print('Profile is null, forcing reload...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            auth.reloadUserProfile();
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        final currentRole = auth.userProfile?.role;
        if (_previousRole != null && 
            _previousRole != currentRole && 
            currentRole != null) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Role Anda telah diubah menjadi: $currentRole'),
                  backgroundColor: currentRole == 'admin' ? Colors.green : Colors.blue,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
        _previousRole = currentRole;

        print('Redirecting to: ${auth.isAdmin ? 'AdminDashboard' : 'HomeScreen'}');
        return auth.isAdmin ? const AdminDashboardScreen() : const HomeScreen();
      },
    );
  }
}