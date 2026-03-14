import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';

class SupabaseTagRepository implements TagRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Tag>> getAllTags() async {
    final response = await _client.from('tags').select().order('label', ascending: true);
    return (response as List).map((json) => Tag.fromJson(json)).toList();
  }

  @override
  Future<void> createTag(Tag tag) async {
    await _client.from('tags').insert({
      'label': tag.label,
      'color': tag.color,
    });
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await _client.from('tags').update({
      'label': tag.label,
      'color': tag.color,
    }).eq('id', tag.id);
  }

  @override
  Future<void> deleteTag(String id) async {
    // 1. Récupérer le label du tag
    final tagResponse = await _client.from('tags').select('label').eq('id', id).single();
    if (tagResponse == null) return;
    
    final String label = tagResponse['label'];

    // 2. Vérifier l'utilisation du tag dans les autres tables (tableaux JSON/Text)
    // Supabase / PostgREST supporte l'opérateur cs (contains) pour les tableaux
    
    // CIs
    final cisCount = await _client.from('cis').select('id', const FetchOptions(count: CountOption.exact)).contains('tags', [label]).limit(1);
    if (cisCount.count != null && cisCount.count! > 0) {
      throw Exception('Impossible de supprimer ce tag : il est utilisé par un ou plusieurs CIs.');
    }

    // Dépendances
    final depsCount = await _client.from('dependencies').select('id', const FetchOptions(count: CountOption.exact)).contains('tags', [label]).limit(1);
    if (depsCount.count != null && depsCount.count! > 0) {
      throw Exception('Impossible de supprimer ce tag : il est utilisé dans des statuts/règles de dépendance.');
    }

    // Evénements
    final eventsCount = await _client.from('events').select('id', const FetchOptions(count: CountOption.exact)).contains('tags', [label]).limit(1);
    if (eventsCount.count != null && eventsCount.count! > 0) {
      throw Exception('Impossible de supprimer ce tag : il est utilisé par des événements.');
    }

    // Journey Maps
    final jmCount = await _client.from('journey_maps').select('id', const FetchOptions(count: CountOption.exact)).contains('tags', [label]).limit(1);
    if (jmCount.count != null && jmCount.count! > 0) {
      throw Exception('Impossible de supprimer ce tag : il est utilisé par une ou plusieurs Journey Maps.');
    }

    // 3. Si non utilisé, on supprime
    await _client.from('tags').delete().eq('id', id);
  }
}
