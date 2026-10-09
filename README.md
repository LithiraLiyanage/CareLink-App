# CareLink

**Connecting older adults with trusted student companions through meaningful check-ins.**

CareLink is a Flutter application developed as part of **IT3060 – Human Computer Interaction (HCI)** at the **Sri Lanka Institute of Information Technology (SLIIT)**. The project explores how accessible, reassuring interfaces can help older adults maintain social connections while supporting consent, trust, and coordinated care.

> **Project status:** Academic project / active development. The Older Adult and Student Companion flows described below have been implemented and tested. Other role-specific functionality is part of the wider CareLink design scope and may still be under development.

## The Problem

Older adults can experience loneliness, limited opportunities for regular social interaction, and difficulty using complex digital services. Families and community coordinators may also need appropriate, privacy-conscious ways to support companionship and check-ins.

CareLink focuses on making it easier to discover a suitable companion, establish a trusted connection, schedule contact, and complete a check-in through an accessible experience.

## User Roles

| Role | Purpose |
| --- | --- |
| **Older Adult** | Find student companions, manage a trusted connection, schedule check-ins, and join voice/video calls. |
| **Student Companion** | Review and respond to companionship requests, manage the connection, and participate in scheduled check-ins. |
| **Family Caregiver** | Intended to support awareness and reassurance through appropriately permissioned family features. |
| **Community Coordinator** | Intended to support safe coordination and oversight of companionship activities. |

## Key Features

### Older Adult and Student Companion Flows

- **Companion discovery and matching:** Language, interests, availability, and companion profiles inform the matching journey.
- **Connection requests:** Send, review, accept, or decline companion requests.
- **Connection management:** View a current connection, pause it, resume it, or review ending it.
- **Check-in scheduling:** Create and view recurring or scheduled check-ins, including rescheduling flows.
- **Voice and video check-ins:** Start or answer calls using WebRTC, with microphone, camera, and supported speaker controls.
- **Call lifecycle:** Distinguish a cancelled/unanswered call from a genuinely connected and completed check-in.
- **Post-check-in experience:** Completion and reflection screens support the end of a check-in.
- **Multilingual interface:** English, Sinhala, and Tamil support in the companion-matching and connection-management flows.
- **Accessibility-oriented UI:** Readable interfaces, clear states, prominent actions, and responsive layouts designed with older adults in mind.

### Wider HCI Design Scope

CareLink's research and design work also considers family visibility, safety notifications, consent, memory sharing, wellbeing support, and community coordination. **Do not assume every concept is fully connected to a production backend.**

## Typical User Journey

1. An older adult explores recommended student companions and reviews profiles.
2. A connection request is sent and reviewed by the selected companion.
3. Once accepted, the connection becomes available for scheduling.
4. The older adult creates a check-in; the student companion can view the corresponding schedule.
5. The participants join a voice or video check-in.
6. A connected call can complete the check-in; an unanswered or cancelled call does **not** count as completed.
7. The connection may be paused, resumed, or ended through the management flow.

## Technology Stack

| Layer | Technology |
| --- | --- |
| Application | Flutter, Dart |
| Development | VS Code, Android tooling, Chrome for web testing |
| Authentication | Firebase Authentication |
| Database / realtime data | Cloud Firestore |
| Audio/video calling | WebRTC (`flutter_webrtc`) |
| Backend services | Firebase-managed services; no separate custom application server is required for the flows described here |
| Testing | Flutter widget tests and static analysis |

**Firebase project used by the team:** `carelink-hci`. Access to the project and its configuration must be granted separately.

## Project Organization

Relevant source code is organized by feature:

```text
lib/
├── features/
│   ├── elder/              # Older Adult screens, models, services, widgets
│   ├── companion/          # Matching, connection and companion flows
│   └── calls/
│       └── services/       # WebRTC calling and Firestore signaling
└── ...
test/                       # Flutter widget tests
```

Some screens retain older Dart filenames as **compatibility exports** that point to renamed `elder_...` implementations. Keep both the export files and their target files when moving or merging changes.

## Getting Started

### Prerequisites

- Flutter SDK and Dart (compatible with the checked-out project's SDK constraints)
- VS Code or Android Studio
- Google Chrome and/or an Android device or emulator
- Access to the team's Firebase project, with the correct Flutter Firebase configuration

### Run locally

```bash
git clone <repository-url>
cd CareLink-App
flutter pub get
flutter devices
flutter run -d chrome
```

For Android, connect a device or start an emulator, then run:

```bash
flutter run
```

**Firebase setup:** Ensure the Firebase configuration for the target platform is available before running authenticated or Firestore-backed functionality. Do not commit credentials, service-account keys, or local secrets. Firebase access rules apply to the signed-in user and role.

**Calling permissions:** Grant camera and microphone access when prompted. Browser calling is best tested from `localhost` or another secure context. To verify end-to-end calling, use **two separate authenticated participants** and confirm signaling, actual peer connection, and completion behavior—not just the call-screen UI.

## Quality Assurance

Run static analysis and automated tests before committing changes:

```bash
flutter analyze
flutter test
```

**Last reported verification (October 2026):** `flutter analyze` returned **No issues found**, and the Flutter test suite passed **99/99 tests**. These results describe the tested commit, not a guarantee for future changes or real-device networking.

Manual scenarios worth checking include matching/request acceptance, connection pause/resume, recurring schedules, cancellation before connection, video/voice calling, and post-call completion. Also inspect layouts at small mobile sizes and with longer translated labels.

## HCI Approach

The project follows a user-centered design process:

1. **Understand users:** Interviews, questionnaires, walkthroughs, and empathy mapping.
2. **Define needs:** Personas, user journeys, themes, functional/non-functional requirements, and user stories.
3. **Explore solutions:** Sketches, low-fidelity wireframes, and interactive prototypes.
4. **Build and refine:** Translate validated interactions into Flutter screens and connect appropriate services.
5. **Evaluate usability:** Test task completion, clarity, accessibility, confidence, and navigation; iterate on findings.

Key design priorities include **large tap targets, understandable feedback, limited cognitive load, multilingual readability, informed consent, and privacy-aware interactions**.

## Privacy and Safety Considerations

CareLink handles potentially sensitive details about people, connections, and check-ins. Implementation and deployment should use authenticated access, appropriate Firestore Security Rules, minimal data collection, explicit consent where applicable, and careful handling of role-based visibility. The app is an academic prototype and should **not** be represented as an emergency-response or professional care service.

## Collaboration and Version Control

This is a group HCI project. Develop changes on feature branches, review changes affecting shared screens/services, and verify imports and compatibility exports when renaming files.

Example checks:

```bash
git status
flutter analyze
flutter test
```

## Academic Context

**Module:** IT3060 – Human Computer Interaction  
**Institution:** Sri Lanka Institute of Information Technology (SLIIT)  
**Project:** CareLink – Elderly Companionship & Check-in App

---

*Built as an academic, human-centered exploration of accessible intergenerational companionship.*
