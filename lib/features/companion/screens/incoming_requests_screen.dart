import 'package:flutter/material.dart';

import '../controllers/companion_controller.dart';
import '../controllers/companion_controller_factory.dart';
import '../models/companion_incoming_request.dart';
import '../models/match_request.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key, this.controller});

  final CompanionController? controller;

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  late final CompanionController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? createCompanionController();
    _controller.watchIncomingRequests();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _respond(
    BuildContext context,
    CompanionIncomingRequest incoming,
    MatchRequestStatus status,
  ) async {
    await _controller.respondToIncomingRequest(
      incoming: incoming,
      status: status,
    );
    if (!context.mounted || _controller.errorMessage == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming companion requests')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoadingIncomingRequests &&
              _controller.incomingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.incomingRequestsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load incoming requests: '
                  '${_controller.incomingRequestsError}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (_controller.incomingRequests.isEmpty) {
            return const Center(child: Text('There are no pending requests.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.incomingRequests.length,
            itemBuilder: (context, index) {
              final incoming = _controller.incomingRequests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incoming.elderDisplayName.isEmpty
                            ? 'Older Adult'
                            : incoming.elderDisplayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (incoming.preferredLanguage.isNotEmpty)
                        _detail(
                          'Preferred language',
                          incoming.preferredLanguage,
                        ),
                      if (incoming.sharedInterests.isNotEmpty)
                        _detail(
                          'Shared interests',
                          incoming.sharedInterests.join(', '),
                        ),
                      if (incoming.compatibleAvailability.isNotEmpty)
                        _detail(
                          'Compatible availability',
                          incoming.compatibleAvailability,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _controller.isLoading
                                  ? null
                                  : () => _respond(
                                      context,
                                      incoming,
                                      MatchRequestStatus.declined,
                                    ),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _controller.isLoading
                                  ? null
                                  : () => _respond(
                                      context,
                                      incoming,
                                      MatchRequestStatus.accepted,
                                    ),
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text('$label: $value'),
  );
}
