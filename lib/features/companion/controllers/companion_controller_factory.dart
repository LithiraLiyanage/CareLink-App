import '../services/companion_service.dart';
import '../services/firebase_companion_service.dart';
import 'companion_controller.dart';

/// The authenticated application uses Firestore. Tests and previews should
/// inject [MockCompanionService] through [createCompanionController].
CompanionService createCompanionService() => FirebaseCompanionService();

CompanionController createCompanionController({CompanionService? service}) =>
    CompanionController(service: service ?? createCompanionService());
