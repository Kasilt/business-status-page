import '../entities/tag.dart';

abstract class TagRepository {
  Future<List<Tag>> getAllTags();
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String id);
}
