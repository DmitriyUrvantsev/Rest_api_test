import '../../../../core/constants/api_constants.dart';

String safeImageUrl(String url) {
  try {
    final uri = Uri.parse(url);

    if (uri.host.contains('picsum.photos') && uri.pathSegments.length >= 2) {
      final width = uri.pathSegments[0];
      final rawHeight = uri.pathSegments[1].split('.').first;
      return 'https://picsum.photos/$width/$rawHeight?random=${DateTime.now().millisecondsSinceEpoch}';
    }

    return url;
  } catch (_) {
    return ApiConstants.placeholderImage;
  }
}

List<T> removeDuplicates<T>(List<T> list, String Function(T) getId) {
  final seenIds = <String>{};
  final filtered = <T>[];
  for (var item in list) {
    final id = getId(item);
    if (!seenIds.contains(id)) {
      filtered.add(item);
      seenIds.add(id);
    }
  }
  return filtered;
}
