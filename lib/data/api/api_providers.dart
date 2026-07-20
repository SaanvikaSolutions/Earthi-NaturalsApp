import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// Single shared [ApiClient] instance for the whole app.
///
/// The auth layer sets its bearer token after login, so every repository
/// built on top of this provider automatically sends authenticated requests.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
