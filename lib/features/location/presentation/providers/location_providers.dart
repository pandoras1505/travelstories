import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepositoryImpl(),
);
