import '../content/content.dart';

/// A place on the map that a visitor can be at. Each map URL is one
/// location.
sealed class MapLocation {
  const MapLocation();

  /// The location that Esc goes to. It is null at the overview.
  MapLocation? get parent;

  /// The URL path of this location, such as `/projects/project-01`.
  String get path;
}

/// The farthest view, at `/`.
final class OverviewLocation extends MapLocation {
  const OverviewLocation();

  @override
  MapLocation? get parent => null;

  @override
  String get path => '/';

  @override
  bool operator ==(Object other) => other is OverviewLocation;

  @override
  int get hashCode => (OverviewLocation).hashCode;
}

/// A location at the body of a category.
sealed class BodyLocation extends MapLocation {
  const BodyLocation();

  /// The category that the body shows.
  Category get category;
}

/// The view of the body of a category, at `/<category>`.
final class CategoryLocation extends BodyLocation {
  const CategoryLocation(this.category);

  @override
  final Category category;

  @override
  MapLocation get parent => const OverviewLocation();

  @override
  String get path => '/${category.slug}';

  @override
  bool operator ==(Object other) =>
      other is CategoryLocation && other.category == category;

  @override
  int get hashCode => category.hashCode;
}

/// An open message, at `/<category>/<message>`.
final class MessageLocation extends BodyLocation {
  const MessageLocation(this.category, this.message);

  @override
  final Category category;

  /// The open message. It is one of the messages of [category].
  final Message message;

  @override
  MapLocation get parent => CategoryLocation(category);

  @override
  String get path => '/${category.slug}/${message.slug}';

  @override
  bool operator ==(Object other) =>
      other is MessageLocation &&
      other.category == category &&
      other.message == message;

  @override
  int get hashCode => Object.hash(category, message);
}
