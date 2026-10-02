import 'package:flutter/material.dart';

class FamilyPendingScreen extends StatelessWidget {
  const FamilyPendingScreen({super.key});

  static const _ink = Color(0xFF00695C);
  static const _titleInk = Color(0xFF004D40);
  static const _muted = Color(0xFF55706E);
  static const _mint = Color(0xFFF2F9F7);
  static const _line = Color(0xFFD5E5E2);
  static const _coral = Color(0xFFF26F6A);
  static const _timelineMuted = Color(0xFFA8B7B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Back to family linking',
          onPressed: () => Navigator.of(context).pushReplacementNamed(
            '/family-linking',
          ),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 23),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: _ink,
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
              backgroundColor: Color(0xFFE0F2EF),
              child: Icon(Icons.person_rounded, color: _ink, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172, color: Color(0xFFDFF1ED)),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38, color: Color(0xFFDFF1ED)),
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
                      const Text(
                        'Request Sent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Your family link request is\npending approval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 19),
                      const _OlderAdultCard(),
                      const SizedBox(height: 22),
                      const _RequestTimeline(),
                      const SizedBox(height: 24),
                      Semantics(
                        button: true,
                        label: 'Cancel Request',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context)
                                .pushNamed('/family-approved'),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _coral, width: 1.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Cancel Request',
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

class _OlderAdultCard extends StatelessWidget {
  const _OlderAdultCard();

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
            color: Color(0x0A00695C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE0F2EF),
            child: Icon(
              Icons.person_rounded,
              size: 31,
              color: FamilyPendingScreen._ink,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mrs. Silva',
                  style: TextStyle(
                    color: FamilyPendingScreen._titleInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Daughter',
                  style: TextStyle(
                    color: FamilyPendingScreen._muted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Requested on 30 Sep 2026',
                  style: TextStyle(
                    color: Color(0xFF829390),
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
  const _RequestTimeline();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TimelineEntry(
          title: 'Request sent',
          detail: '30 Sep 2026, 10:30 AM',
          indicatorColor: FamilyPendingScreen._coral,
          isLast: false,
        ),
        _TimelineEntry(
          title: 'Pending approval',
          detail: 'Waiting for elder approval',
          indicatorColor: FamilyPendingScreen._timelineMuted,
          isLast: false,
        ),
        _TimelineEntry(
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
