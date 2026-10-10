import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../services/family_link_service.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String _formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${_formatDate(date)}, $hour:$minute $period';
}

class FamilyPendingScreen extends StatefulWidget {
  const FamilyPendingScreen({super.key});

  static const _ink = Color(0xFF00776F);
  static const _titleInk = Color(0xFF073F42);
  static const _muted = Color(0xFF708486);
  static const _mint = Color(0xFFF5FBF9);
  static const _line = Color(0xFFD1EBE7);
  static const _coral = Color(0xFFFF5369);
  static const _timelineMuted = Color(0xFF9AABAC);

  @override
  State<FamilyPendingScreen> createState() => _FamilyPendingScreenState();
}

class _FamilyPendingScreenState extends State<FamilyPendingScreen> {
  static const _ink = FamilyPendingScreen._ink;
  static const _mint = FamilyPendingScreen._mint;
  static const _coral = FamilyPendingScreen._coral;

  // The family member's own pending requests, newest first.
  StreamSubscription<List<FamilyLinkRequest>>? _subscription;
  List<FamilyLinkRequest>? _requests;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _subscription = FamilyLinkService.instance.watchPendingRequests().listen(
          (requests) => setState(() {
            _requests = requests;
            _failed = false;
          }),
          onError: (Object error) {
            debugPrint('Pending family requests stream failed: $error');
            setState(() => _failed = true);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Server timestamps are null until they land, so fall back to the local
  /// time.
  List<_PendingRequest> get _pendingRequests => [
        for (final request in _requests ?? const <FamilyLinkRequest>[])
          _PendingRequest(
            title: request.elderName.trim().isEmpty
                ? 'Older adult'
                : request.elderName.trim(),
            relationship: request.relationship,
            sentAt: request.createdAt?.toLocal() ?? DateTime.now(),
            idNumber: request.idNumber,
          ),
      ];

  // Returns to the linking screen underneath when there is one; otherwise
  // (e.g. opened directly by route) replaces this screen with it.
  void _backToLinking() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.familyLinking);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF073F42),
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Back to family linking',
          onPressed: _backToLinking,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 23),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: Color(0xFF073F42), size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172, color: Color(0xFFE7F6F1)),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38, color: Color(0xFFE7F6F1)),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 9, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _PendingIllustration()),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          if (_failed) {
                            return const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Heading(
                                  title: 'Unable to Load Requests',
                                  subtitle: 'Your requests couldn\'t be shown\n'
                                      'at the moment.',
                                ),
                                Text(
                                  'We couldn\'t load your requests right now. '
                                  'Please check your connection and try again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _coral, fontSize: 13),
                                ),
                              ],
                            );
                          }
                          if (_requests == null) {
                            return const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Heading.pending(),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child:
                                        CircularProgressIndicator(color: _ink),
                                  ),
                                ),
                              ],
                            );
                          }
                          final requests = _pendingRequests;
                          if (requests.isEmpty) {
                            return const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Heading(
                                  title: 'No Pending Requests',
                                  subtitle: 'Send a new request from Family\n'
                                      'Linking whenever you\'re ready.',
                                ),
                                _EmptyRequests(),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _Heading.pending(),
                              for (final request in requests) ...[
                                _OlderAdultCard(request: request),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 10),
                              _RequestTimeline(sentAt: requests.first.sentAt),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        button: true,
                        label: 'Back to Family Linking',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _backToLinking,
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _coral, width: 1.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Back to Family Linking',
                                style: TextStyle(
                                  color: _coral,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingIllustration extends StatelessWidget {
  const _PendingIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D9),
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          const Icon(Icons.access_time_rounded,
              size: 39, color: FamilyPendingScreen._coral),
        ],
      ),
    );
  }
}

/// Title and supporting text above the request content, matching the
/// current stream state.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  const _Heading.pending()
      : title = 'Request Sent',
        subtitle = 'Your family link request is\npending approval.';

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FamilyPendingScreen._titleInk,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FamilyPendingScreen._muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'You have no pending requests',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FamilyPendingScreen._titleInk,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Approved requests can be viewed through the profile badge.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FamilyPendingScreen._muted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// A pending request in display form.
class _PendingRequest {
  const _PendingRequest({
    required this.title,
    required this.relationship,
    required this.sentAt,
    required this.idNumber,
  });

  /// The older adult's name as the family member typed it.
  final String title;
  final String relationship;
  final DateTime sentAt;
  final String idNumber;
}

class _OlderAdultCard extends StatelessWidget {
  const _OlderAdultCard({required this.request});

  final _PendingRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamilyPendingScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14073F42),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE7F6F1),
            child: Icon(
              Icons.person_rounded,
              size: 31,
              color: FamilyPendingScreen._ink,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FamilyPendingScreen._titleInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    request.relationship,
                    if (request.idNumber.trim().isNotEmpty)
                      'ID ${request.idNumber.trim()}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: FamilyPendingScreen._muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested on ${_formatDate(request.sentAt)}',
                  style: const TextStyle(
                    color: Color(0xFF9AABAC),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTimeline extends StatelessWidget {
  const _RequestTimeline({required this.sentAt});

  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineEntry(
          title: 'Request sent',
          detail: _formatDateTime(sentAt),
          indicatorColor: FamilyPendingScreen._coral,
          isLast: false,
        ),
        const _TimelineEntry(
          title: 'Pending approval',
          detail: 'Waiting for elder approval',
          indicatorColor: FamilyPendingScreen._timelineMuted,
          isLast: false,
        ),
        const _TimelineEntry(
          title: 'Access will be enabled',
          detail: 'after approval',
          indicatorColor: FamilyPendingScreen._timelineMuted,
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.title,
    required this.detail,
    required this.indicatorColor,
    required this.isLast,
  });

  final String title;
  final String detail;
  final Color indicatorColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: FamilyPendingScreen._line,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: FamilyPendingScreen._titleInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: FamilyPendingScreen._muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
