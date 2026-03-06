import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton pattern
  SupabaseService._privateConstructor();
  static final SupabaseService instance = SupabaseService._privateConstructor();

  final SupabaseClient client = Supabase.instance.client;

  // Shortcuts for tables
  SupabaseQueryBuilder get tasksTable => client.from('tasks');

  // Helper method for catching supabase errors uniformly (optional)
  Future<T> runCatching<T>(Future<T> Function() block) async {
    try {
      return await block();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
