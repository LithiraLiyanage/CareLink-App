import '../services/companion_service.dart';
import '../services/mock_companion_service.dart';
import 'companion_controller.dart';

/// The single companion service selection point. Keep mock active until the
/// approval schema, profile publisher, and Firestore rules are ready.
CompanionService createCompanionService() => MockCompanionService();

CompanionController createCompanionController() =>
    CompanionController(service: createCompanionService());
