import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/civsnap_portal.dart';
import 'package:local_app_tt/screens/dog_registration.dart';
import 'package:local_app_tt/screens/forms/forms_hub.dart';
import 'package:local_app_tt/screens/service_detail.dart';

class ServiceOption {
  final String label;
  final String description;
  final IconData icon;
  final String category;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> highlights;
  final List<String> quickActions;
  final List<String> formFields;
  final List<String> checkpoints;
  final Color accentColor;

  const ServiceOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.category,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.highlights,
    required this.quickActions,
    required this.formFields,
    required this.checkpoints,
    required this.accentColor,
  });
}

const List<ServiceOption> externalServiceOptions = [
  ServiceOption(
    label: 'Dog Registration',
    description: 'Register a new dog in the system',
    icon: Icons.pets,
    category: 'External Services',
    heroTitle: 'Register a new dog in minutes',
    heroSubtitle: 'Capture ownership, health, and care details for public records.',
    highlights: [
      'Guided intake flow with wellness checks',
      'Auto-saved progress and instant confirmation',
      'Shareable registration summary',
    ],
    quickActions: ['Start intake', 'View registry', 'Print confirmation'],
    formFields: ['Owner name', 'Contact number', 'Dog name', 'Breed'],
    checkpoints: ['Intake started', 'Profile complete', 'Verified', 'Registered'],
    accentColor: Colors.deepPurple,
  ),
  ServiceOption(
    label: 'Find File',
    description: 'Locate an external record',
    icon: Icons.search,
    category: 'External Services',
    heroTitle: 'Locate external records fast',
    heroSubtitle: 'Search across public-facing archives with verified access.',
    highlights: ['Unified search index', 'Secure access requests', 'Exports ready in minutes'],
    quickActions: ['New search', 'Upload reference', 'Request archive'],
    formFields: ['Record ID or name', 'Reason for access', 'Contact email'],
    checkpoints: ['Request submitted', 'In review', 'File located', 'Delivered'],
    accentColor: Colors.teal,
  ),
  ServiceOption(
    label: 'Scan File',
    description: 'Digitize external paperwork',
    icon: Icons.document_scanner,
    category: 'External Services',
    heroTitle: 'Digitize files securely',
    heroSubtitle: 'Turn paper submissions into digital records in one flow.',
    highlights: ['High-res capture', 'Smart tagging', 'Public-facing storage'],
    quickActions: ['Start scan', 'Upload PDF', 'Check queue'],
    formFields: ['Document title', 'Category', 'Requester name'],
    checkpoints: ['Queued', 'Scanning', 'Processing', 'Archived'],
    accentColor: Colors.indigo,
  ),
  ServiceOption(
    label: 'Forms',
    description: 'Access external service forms',
    icon: Icons.description,
    category: 'External Services',
    heroTitle: 'Self-serve public forms',
    heroSubtitle: 'Find the right external form and track submissions.',
    highlights: ['Smart form recommendations', 'Real-time submission status', 'Printable receipts'],
    quickActions: ['Browse forms', 'Resume draft', 'Track submission'],
    formFields: ['Form name', 'Submission ID', 'Contact email'],
    checkpoints: ['Drafted', 'Submitted', 'Validated', 'Completed'],
    accentColor: Colors.blueGrey,
  ),
  ServiceOption(
    label: 'CivSnap',
    description: 'Snap and geotag community issues',
    icon: Icons.add_a_photo,
    category: 'External Services',
    heroTitle: 'Capture, geotag, and confirm local issues',
    heroSubtitle: 'Auto-detect reports within 5 meters and vote on existing issues.',
    highlights: [
      'Photo capture with auto-geotagging',
      'Duplicate detection within 5 meters',
      'Vote to confirm or submit a new issue',
    ],
    quickActions: ['Snap photo', 'Check nearby', 'Vote on issue'],
    formFields: ['Issue title', 'Location notes', 'Contact preference'],
    checkpoints: ['Captured', 'Matched', 'Confirmed', 'Resolved'],
    accentColor: Colors.green,
  ),
  ServiceOption(
    label: 'Report a Bug',
    description: 'Log an external service bug',
    icon: Icons.bug_report,
    category: 'External Services',
    heroTitle: 'Report an external software bug',
    heroSubtitle: 'Capture issues with guided prompts and device data.',
    highlights: ['Auto-capture device info', 'Severity scoring', 'Updates delivered by email'],
    quickActions: ['New bug', 'Attach logs', 'View known issues'],
    formFields: ['Bug title', 'Steps to reproduce', 'Impact level'],
    checkpoints: ['Logged', 'Triaged', 'Fix in progress', 'Released'],
    accentColor: Colors.redAccent,
  ),
];

const List<ServiceOption> internalServiceOptions = [
  ServiceOption(
    label: 'Find File',
    description: 'Locate internal records',
    icon: Icons.search,
    category: 'Internal Services',
    heroTitle: 'Find internal records instantly',
    heroSubtitle: 'Search department files with permission-based access.',
    highlights: ['Department filters', 'Secure approvals', 'Saved queries'],
    quickActions: ['Start search', 'Recent files', 'Saved queries'],
    formFields: ['Record ID', 'Department', 'Need-by date'],
    checkpoints: ['Requested', 'Approved', 'Retrieved', 'Shared'],
    accentColor: Colors.blueGrey,
  ),
  ServiceOption(
    label: 'Scan File',
    description: 'Scan an internal document',
    icon: Icons.document_scanner,
    category: 'Internal Services',
    heroTitle: 'Convert internal docs to digital',
    heroSubtitle: 'Scan, tag, and publish files to internal storage.',
    highlights: ['Auto-tagging', 'Secure storage', 'Batch uploads'],
    quickActions: ['Start scan', 'Upload batch', 'Review inbox'],
    formFields: ['Document title', 'Department', 'Retention policy'],
    checkpoints: ['Queued', 'Scanning', 'Quality check', 'Published'],
    accentColor: Colors.deepPurpleAccent,
  ),
  ServiceOption(
    label: 'Forms',
    description: 'Open internal forms',
    icon: Icons.description,
    category: 'Internal Services',
    heroTitle: 'Internal forms hub',
    heroSubtitle: 'Access HR, finance, and ops forms in one spot.',
    highlights: ['Role-based templates', 'Auto-filled metadata', 'Approvals tracking'],
    quickActions: ['Browse forms', 'Drafts', 'Approvals'],
    formFields: ['Form name', 'Manager approval', 'Submission date'],
    checkpoints: ['Drafted', 'Submitted', 'Reviewed', 'Approved'],
    accentColor: Colors.blueGrey,
  ),
  ServiceOption(
    label: 'Report a Bug',
    description: 'Log an internal bug',
    icon: Icons.bug_report,
    category: 'Internal Services',
    heroTitle: 'Report an internal software bug',
    heroSubtitle: 'Capture issues, add logs, and follow fixes.',
    highlights: ['Sprint alignment', 'Severity scoring', 'Release notes'],
    quickActions: ['New bug', 'Attach logs', 'View backlog'],
    formFields: ['Bug title', 'Module', 'Impact level'],
    checkpoints: ['Logged', 'Triaged', 'Fixing', 'Released'],
    accentColor: Colors.redAccent,
  ),
];

void handleExternalServiceTap(BuildContext context, ServiceOption option) {
  if (option.label == 'Dog Registration') {
    Navigator.of(context).push(DogRegistrationScreen.route());
    return;
  }
  if (option.label == 'CivSnap') {
    Navigator.of(context).push(CivSnapPortalScreen.route());
    return;
  }
  if (option.label == 'Forms') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FormsHubScreen(
          scope: 'public',
          title: 'Public Forms',
        ),
      ),
    );
    return;
  }

  Navigator.of(context).push(ServiceDetailScreen.route(option));
}

void handleInternalServiceTap(BuildContext context, ServiceOption option) {
  if (option.label == 'Forms') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FormsHubScreen(
          scope: 'internal',
          title: 'Internal Forms',
        ),
      ),
    );
    return;
  }
  Navigator.of(context).push(ServiceDetailScreen.route(option));
}
