import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final _supabase = SupabaseService();
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _userProfile;
  StreamSubscription? _profileSubscription;
  Timer? _roleCheckTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _supabase.isLoggedIn;
  User? get currentUser => _supabase.currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isAdmin => _userProfile?.isAdmin ?? false;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      
      await _loadUserProfile();
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadUserProfile();
      
      await _updateFCMToken();
      _startRoleMonitoring();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _supabase.client.from('user_profiles').insert({
          'id': response.user!.id,
          'email': email,
          'role': 'user',
        });
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _stopRoleMonitoring();
    await _supabase.client.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> reloadUserProfile() async {
    await _loadUserProfile();
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    final user = _supabase.currentUser;
    if (user != null) {
      try {
        print('=== LOADING PROFILE ===');
        print('User ID: ${user.id}');
        print('User Email: ${user.email}');
        
        final response = await _supabase.client
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        print('Raw response: $response');
        
        if (response != null) {
          _userProfile = UserProfile.fromJson(response);
          print('✅ Profile loaded successfully');
          print('Role: ${_userProfile?.role}');
          print('Is Admin: ${_userProfile?.isAdmin}');
        } else {
          print('❌ No profile found, creating new one');
          await _supabase.client.from('user_profiles').insert({
            'id': user.id,
            'email': user.email ?? '',
            'role': 'user',
          });
          await _loadUserProfile();
        }
      } catch (e) {
        print('❌ Error loading user profile: $e');
      }
    }
  }

  Future<void> _updateFCMToken() async {
    try {
      final token = await FirebaseService.getToken();
      if (token != null && _userProfile != null) {
        await _supabase.client
            .from('user_profiles')
            .update({'fcm_token': token})
            .eq('id', _userProfile!.id);
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  void _startRoleMonitoring() {
    final user = _supabase.currentUser;
    if (user == null) return;

    
    _supabase.ensureRealtimeConnection();

    
    try {
      _profileSubscription = _supabase.client
          .from('user_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen(
            (data) {
              if (data.isNotEmpty) {
                final newProfile = UserProfile.fromJson(data.first);
                final oldRole = _userProfile?.role;
                _userProfile = newProfile;
                
                // Notify jika role berubah
                if (oldRole != null && oldRole != newProfile.role) {
                  print('Role changed from $oldRole to ${newProfile.role}');
                  notifyListeners();
                }
              }
            },
            onError: (error) {
              print('Real-time subscription error: $error');
            
            },
          );
    } catch (e) {
      print('Failed to start real-time subscription: $e');
    }

    _roleCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkRoleUpdate();
    });
  }

  void _stopRoleMonitoring() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _roleCheckTimer?.cancel();
    _roleCheckTimer = null;
  }

  Future<void> _checkRoleUpdate() async {
    final user = _supabase.currentUser;
    if (user == null || _userProfile == null) return;

    try {
      final response = await _supabase.client
          .from('user_profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final currentRole = response['role'] as String;
      if (_userProfile!.role != currentRole) {
        print('Role updated from ${_userProfile!.role} to $currentRole');
        await _loadUserProfile();
        notifyListeners();
      }
    } catch (e) {
      print('Error checking role update: $e');
    }
  }

  @override
  void dispose() {
    _stopRoleMonitoring();
    super.dispose();
  }
}
