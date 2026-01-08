import 'package:flutter/material.dart';
import 'package:local_app_tt/screens/dog_registration.dart';

class ServiceOption {
  final String label;
  final String description;
  final IconData icon;
  final void Function(BuildContext context)? onTap;

  const ServiceOption({
    required this.label,
    required this.description,
    required this.icon,
    this.onTap,
  });
}

const List<ServiceOption> externalServiceOptions = [
  ServiceOption(
    label: 'Dog Registration',
    description: 'Register a new dog in the system',
    icon: Icons.pets,
  ),
  ServiceOption(
    label: 'Find File',
    description: 'Locate an external record',
    icon: Icons.search,
  ),
  ServiceOption(
    label: 'Scan File',
    description: 'Digitize external paperwork',
    icon: Icons.document_scanner,
  ),
  ServiceOption(
    label: 'Forms',
    description: 'Access external service forms',
    icon: Icons.description,
  ),
  ServiceOption(
    label: 'Report an Issue',
    description: 'Share a concern quickly',
    icon: Icons.report_gmailerrorred,
  ),
  ServiceOption(
    label: 'Software Bugs',
    description: 'Log an external service bug',
    icon: Icons.bug_report,
  ),
];

const List<ServiceOption> internalServiceOptions = [
  ServiceOption(
    label: 'Find File',
    description: 'Locate internal records',
    icon: Icons.search,
  ),
  ServiceOption(
    label: 'Scan File',
    description: 'Scan an internal document',
    icon: Icons.document_scanner,
  ),
  ServiceOption(
    label: 'Forms',
    description: 'Open internal forms',
    icon: Icons.description,
  ),
  ServiceOption(
    label: 'Report an Issue',
    description: 'Submit an internal concern',
    icon: Icons.report_gmailerrorred,
  ),
  ServiceOption(
    label: 'Software Bugs',
    description: 'Log an internal bug',
    icon: Icons.bug_report,
  ),
];

void handleExternalServiceTap(BuildContext context, ServiceOption option) {
  if (option.label == 'Dog Registration') {
    Navigator.of(context).push(DogRegistrationScreen.route());
    return;
  }
}
