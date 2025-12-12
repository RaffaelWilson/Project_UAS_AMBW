import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://bktznlpwvnhbfzvcxhha.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrdHpubHB3dm5oYmZ6dmN4aGhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMTYwNTMsImV4cCI6MjA4MDY5MjA1M30.fPZYc7iZrxWt_yQ68Q4jAuQ-tpE-diGVebDgeP3EWf8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
}