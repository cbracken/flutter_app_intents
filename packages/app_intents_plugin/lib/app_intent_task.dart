/// A task exposed to Siri, Shortcuts and Spotlight as an App Entity.
///
/// Tasks live in Dart, but Siri and Spotlight query them while the app may not
/// be running, so the list is mirrored into a native cache. See
/// `AppIntentsPlugin.syncTasks`.
class AppIntentTask {
  const AppIntentTask({required this.id, required this.title, this.subtitle});

  /// Stable across app launches.
  ///
  /// Spotlight and Siri key off this, so reusing an id for a different task
  /// makes the index point at the wrong thing.
  final String id;

  /// Shown as the entity's display title, and matched against search text.
  final String title;

  /// Optional supporting text shown beneath [title].
  final String? subtitle;

  /// Decodes a task from the representation used on the method channel.
  factory AppIntentTask.fromMap(Map<dynamic, dynamic> map) {
    return AppIntentTask(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
    );
  }

  /// Encodes a task for the method channel.
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'subtitle': subtitle};
  }

  @override
  bool operator ==(Object other) =>
      other is AppIntentTask &&
      other.id == id &&
      other.title == title &&
      other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(id, title, subtitle);

  @override
  String toString() => 'AppIntentTask(id: $id, title: $title)';
}
