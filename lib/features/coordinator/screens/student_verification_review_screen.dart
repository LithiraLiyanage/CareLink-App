import 'package:flutter/material.dart';

import '../services/student_verification_review_service.dart';

class StudentVerificationReviewScreen extends StatefulWidget {
  const StudentVerificationReviewScreen({super.key, this.repository});

  final StudentVerificationReviewRepository? repository;

  @override
  State<StudentVerificationReviewScreen> createState() =>
      _StudentVerificationReviewScreenState();
}

class _StudentVerificationReviewScreenState
    extends State<StudentVerificationReviewScreen> {
  late final StudentVerificationReviewRepository _repository;
  late final Future<bool> _authorization;
  bool _isReviewing = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StudentVerificationReviewService();
    _authorization = _repository.isAuthorizedReviewer();
  }

  Future<void> _review(
    StudentVerificationReviewRequest request,
    String status,
  ) async {
    String? reason;
    if (status == 'rejected') {
      reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Reject verification'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );
      if (reason == null) return;
    }

    setState(() => _isReviewing = true);
    try {
      await _repository.reviewRequest(
        userId: request.userId,
        status: status,
        rejectionReason: reason,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not update verification: $error')),
        );
    } finally {
      if (mounted) setState(() => _isReviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student verification review')),
      body: FutureBuilder<bool>(
        future: _authorization,
        builder: (context, authorizationSnapshot) {
          if (!authorizationSnapshot.hasData) {
            if (authorizationSnapshot.hasError) {
              return const Center(
                child: Text('Could not verify reviewer access.'),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (authorizationSnapshot.data != true) {
            return const Center(
              child: Text('Coordinator or Admin access is required.'),
            );
          }
          return StreamBuilder<List<StudentVerificationReviewRequest>>(
            stream: _repository.watchPendingRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Could not load pending verifications.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final requests = snapshot.data!;
              if (requests.isEmpty) {
                return const Center(
                  child: Text('There are no pending student verifications.'),
                );
              }
              return Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) =>
                        _buildRequestCard(context, requests[index]),
                  ),
                  if (_isReviewing)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x55000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    StudentVerificationReviewRequest request,
  ) {
    final submittedAt = request.submittedAt;
    final submittedText = submittedAt == null
        ? 'Unknown'
        : '${submittedAt.toLocal()}'.split('.').first;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.fullName.isEmpty ? 'Student' : request.fullName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _detail('University / Institute', request.university),
            _detail('Student ID', request.studentId),
            _detail('University Email', request.universityEmail),
            _detail('Submitted', submittedText),
            _detail('Status', request.status),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isReviewing
                        ? null
                        : () => _review(request, 'rejected'),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isReviewing
                        ? null
                        : () => _review(request, 'verified'),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('$label: $value'),
  );
}
