CARELINK RESCHEDULE FIX - LOCAL REVIEW ONLY

Cause found in code: Flutter reschedule writes status=scheduled even for ready check-ins.
The older Firestore rule disallows ready -> scheduled for new pair-linked documents.
This patch allows ready -> scheduled only if scheduledAt changes to a future time.
It leaves Family Linking, matching and WebRTC rules unchanged.

Do not deploy without running the new test and existing regression tests.
Test file carelink.reschedule.rules.test.cjs reads PROJECT ROOT firestore.rules.
Change ONLY local file first after taking a backup.

Base file SHA256 (for provenance, not a production assertion):
cedeb872ffd795eaf909f8712603e54891b5a47f67aa681143f909360816bc5f
