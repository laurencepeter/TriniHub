import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_app_tt/services/civsnap_service.dart';
import 'package:local_app_tt/utils/error_mapper.dart';
import 'package:local_app_tt/widgets/responsive_scaffold.dart';

class IssueSnapScreen extends StatefulWidget {
  const IssueSnapScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => ResponsiveScaffold(
        childBuilder: (device) => const IssueSnapScreen(),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<IssueSnapScreen> createState() => _IssueSnapScreenState();
}

class _IssueSnapScreenState extends State<IssueSnapScreen> {
  final CivSnapService _service = CivSnapService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  XFile? _photo;
  Uint8List? _photoBytes;
  Position? _position;
  CivSnapReport? _nearbyReport;
  double? _nearbyDistance;
  String? _errorMessage;
  bool _loadingLocation = false;
  bool _loadingMatch = false;
  bool _submitting = false;
  bool _photoMismatch = false;
  bool _voted = false;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  onClose: () => Navigator.popUntil(context, (route) => route.isFirst),
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (_errorMessage != null)
                        _StatusBanner(
                          message: _errorMessage!,
                          tone: _StatusTone.error,
                          onDismiss: () => setState(() => _errorMessage = null),
                        ),
                      if (_submitting)
                        const _StatusBanner(
                          message: 'Submitting your report…',
                          tone: _StatusTone.info,
                        ),
                      _CaptureCard(
                        photoBytes: _photoBytes,
                        onPickCamera: () => _pickPhoto(ImageSource.camera),
                        onPickGallery: () => _pickPhoto(ImageSource.gallery),
                      ),
                      const SizedBox(height: 16),
                      _IssueDetailsCard(
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        locationController: _locationController,
                      ),
                      const SizedBox(height: 16),
                      _GeoTagCard(
                        position: _position,
                        loading: _loadingLocation,
                        onRefresh: _refreshLocation,
                      ),
                      const SizedBox(height: 16),
                      if (_loadingMatch)
                        const _StatusBanner(
                          message: 'Checking for nearby issues…',
                          tone: _StatusTone.info,
                        ),
                      _DuplicateAlert(
                        report: _nearbyReport,
                        distanceMeters: _nearbyDistance,
                        photoMismatch: _photoMismatch,
                        voted: _voted,
                        onMismatchChanged: (value) {
                          setState(() {
                            _photoMismatch = value;
                          });
                        },
                        onVote: _nearbyReport == null ? null : () => _handleVote(_nearbyReport!),
                        onSubmitNew: _canSubmitNew ? _handleSubmit : null,
                      ),
                      const SizedBox(height: 16),
                      _NextStepsPanel(
                        photoMismatch: _photoMismatch,
                        voted: _voted,
                        hasNearby: _nearbyReport != null,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmitNew {
    if (_submitting) {
      return false;
    }
    if (_nearbyReport != null && !_photoMismatch) {
      return false;
    }
    return _photo != null && _position != null && _titleController.text.trim().isNotEmpty;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() {
      _photo = file;
      _photoBytes = bytes;
    });
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _loadingLocation = true;
      _errorMessage = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied.');
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _position = position;
      });
      await _findNearby();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _findNearby() async {
    final position = _position;
    if (position == null) {
      return;
    }
    setState(() {
      _loadingMatch = true;
    });
    try {
      final report = await _service.findNearbyReport(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _nearbyReport = report;
        _nearbyDistance = report == null
            ? null
            : _distanceMeters(
                position.latitude,
                position.longitude,
                report.latitude,
                report.longitude,
              );
        _voted = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = mapSupabaseError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMatch = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    final position = _position;
    if (position == null) {
      setState(() {
        _errorMessage = 'Location is required before submitting.';
      });
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Add a short title to describe the issue.';
      });
      return;
    }
    if (_photo == null) {
      setState(() {
        _errorMessage = 'Capture a photo before submitting.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _service.submitReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        locationLabel: _locationController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        photo: _photo,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _photo = null;
        _photoBytes = null;
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _photoMismatch = false;
        _nearbyReport = null;
        _nearbyDistance = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted. We will keep you posted.')),
      );
    } catch (error) {
      setState(() {
        _errorMessage = mapSupabaseError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _handleVote(CivSnapReport report) async {
    try {
      await _service.voteForReport(report.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _voted = true;
        _nearbyReport = CivSnapReport(
          id: report.id,
          title: report.title,
          description: report.description,
          photoUrl: report.photoUrl,
          latitude: report.latitude,
          longitude: report.longitude,
          accuracyMeters: report.accuracyMeters,
          locationLabel: report.locationLabel,
          createdAt: report.createdAt,
          status: report.status,
          voteCount: report.voteCount + 1,
        );
      });
    } catch (error) {
      setState(() {
        _errorMessage = mapSupabaseError(error);
      });
    }
  }

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  static double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _HeroHeader({required this.onBack, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'External Service',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'CivSnap',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Snap a photo, auto-geotag, and check if the issue is already logged within 5 meters.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _HeroChip(label: 'Camera ready'),
                const SizedBox(width: 8),
                _HeroChip(label: 'Auto-match enabled'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final Uint8List? photoBytes;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _CaptureCard({
    required this.photoBytes,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Capture evidence',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: photoBytes == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera, size: 40, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('Tap to snap a photo', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(photoBytes!, fit: BoxFit.cover, width: double.infinity),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open camera'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueDetailsCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;

  const _IssueDetailsCard({
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Issue details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Issue title',
              hintText: 'e.g., Streetlight out on Queen St',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Share more details for the crew',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              labelText: 'Nearby landmark (optional)',
              hintText: 'e.g., Near the post office entrance',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeoTagCard extends StatelessWidget {
  final Position? position;
  final bool loading;
  final VoidCallback onRefresh;

  const _GeoTagCard({
    required this.position,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latitude = position?.latitude;
    final longitude = position?.longitude;
    final accuracy = position?.accuracy;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Geotag details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Latitude',
                  value: latitude == null ? 'Not available' : latitude.toStringAsFixed(5),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Longitude',
                  value: longitude == null ? 'Not available' : longitude.toStringAsFixed(5),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Accuracy',
                  value: accuracy == null ? 'Not available' : '± ${accuracy.toStringAsFixed(1)} m',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.my_location),
            label: Text(loading ? 'Refreshing…' : 'Refresh location'),
          ),
        ],
      ),
    );
  }
}

class _DuplicateAlert extends StatelessWidget {
  final CivSnapReport? report;
  final double? distanceMeters;
  final bool photoMismatch;
  final bool voted;
  final ValueChanged<bool> onMismatchChanged;
  final VoidCallback? onVote;
  final VoidCallback? onSubmitNew;

  const _DuplicateAlert({
    required this.report,
    required this.distanceMeters,
    required this.photoMismatch,
    required this.voted,
    required this.onMismatchChanged,
    required this.onVote,
    required this.onSubmitNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = this.report;
    final distanceLabel = distanceMeters == null
        ? null
        : '${distanceMeters!.toStringAsFixed(1)} m away';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                report == null ? 'No nearby issues' : 'Nearby issue detected',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report == null
                ? 'You are clear to submit a new report from this location.'
                : 'We found an issue already logged within 5 meters. Compare details before submitting a new report.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (report != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.image_outlined, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTimeAgo(report.createdAt)} · ${report.voteCount} community votes',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (report.locationLabel != null && report.locationLabel!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(report.locationLabel!, style: theme.textTheme.bodySmall),
                        ],
                        if (distanceLabel != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.place, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(distanceLabel, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: photoMismatch,
              onChanged: (value) => onMismatchChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text('Photo does not match my issue'),
              subtitle: const Text('Submit a new report if the issue is different.'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: voted || onVote == null ? null : onVote,
                    icon: Icon(voted ? Icons.check_circle : Icons.how_to_vote),
                    label: Text(voted ? 'Voted' : 'Vote for this issue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSubmitNew,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Submit new issue'),
                  ),
                ),
              ],
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: onSubmitNew,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Submit issue'),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    return '${diff.inDays} days ago';
  }
}

class _NextStepsPanel extends StatelessWidget {
  final bool photoMismatch;
  final bool voted;
  final bool hasNearby;

  const _NextStepsPanel({
    required this.photoMismatch,
    required this.voted,
    required this.hasNearby,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    if (!hasNearby) {
      message = 'Add a title and photo, then submit your new report. We will notify you once it is assigned.';
    } else if (photoMismatch) {
      message = 'A new report can be created because the photo does not match. We will notify you if a duplicate appears later.';
    } else if (voted) {
      message = 'Thanks for voting. We will keep you updated on the existing issue and add your confirmation.';
    } else {
      message = 'Review the matched issue. Vote to confirm it or flag that your issue is different.';
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next steps',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

enum _StatusTone { info, error }

class _StatusBanner extends StatelessWidget {
  final String message;
  final _StatusTone tone;
  final VoidCallback? onDismiss;

  const _StatusBanner({
    required this.message,
    required this.tone,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = tone == _StatusTone.error;
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}
