import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'doctor_profile_setup_page.dart';
import 'doctor_service.dart';
import '../common/widgets/novtek_brand_widgets.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key, this.initialDoctor});

  final Map<String, dynamic>? initialDoctor;

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  Map<String, dynamic> _doctor = {};
  bool _isLoading = true;
  String? _error;
  List<dynamic> _matchingPatients = [];
  List<dynamic> _allPatients = [];
  List<String> _doctorPincodes = [];
  int _selectedFilterIndex = 0; // 0: Area, 1: Critical, 2: All

  static const Color _primaryColor = Color(0xFF197278);
  static const Color _secondaryColor = Color(0xFF283D3B);

  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor != null) {
      _doctor = Map<String, dynamic>.from(widget.initialDoctor ?? {});
    }
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await DoctorService.getPatients();
      if (!mounted) return;

      final isProfileComplete = (result['isProfileComplete'] as bool?) ?? true;
      if (!isProfileComplete) {
        final doc = (result['doctor'] as Map<String, dynamic>?) ?? {};
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => DoctorProfileSetupPage(
                email: doc['email']?.toString(),
                doctorId: doc['id']?.toString(),
              ),
            ),
          );
          return;
        }
      }

      setState(() {
        if (result['doctor'] != null && result['doctor'] is Map) {
          _doctor = Map<String, dynamic>.from(result['doctor'] as Map);
        }
        _matchingPatients = (result['patients'] as List?) ?? [];
        _allPatients = (result['allPatients'] as List?) ?? [];
        _doctorPincodes = ((result['doctorPincodes'] as List?) ?? [])
            .map((e) => e.toString())
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: (_doctor['fullName'] ?? _doctor['name'])?.toString() ?? '');
    final specCtrl = TextEditingController(
      text: _doctor['specialization']?.toString() ?? 'General Practitioner',
    );
    final phoneCtrl = TextEditingController(
      text: _doctor['phoneNumber']?.toString() ?? '',
    );
    final pinInputCtrl = TextEditingController();
    final List<String> editPincodes = List<String>.from(_doctorPincodes);
    String? pinError;
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addPin() {
              final raw = pinInputCtrl.text.trim();
              if (raw.isEmpty) {
                setDialogState(() => pinError = 'Enter a pincode to add');
                return;
              }
              if (raw.length < 2 || raw.length > 8) {
                setDialogState(() => pinError = 'Pincode must be between 2 and 8 characters');
                return;
              }
              if (!RegExp(r'^[a-zA-Z0-9\s]{2,8}$').hasMatch(raw)) {
                setDialogState(() => pinError = 'Pincode can only contain text and numbers');
                return;
              }
              final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
              final exists = editPincodes.any(
                (p) => p.replaceAll(RegExp(r'\s+'), '').toUpperCase() == normalized.replaceAll(' ', ''),
              );
              if (exists) {
                setDialogState(() => pinError = 'Pincode "$normalized" is already added');
                return;
              }
              setDialogState(() {
                editPincodes.add(normalized);
                pinInputCtrl.clear();
                pinError = null;
              });
            }

            void removePin(int i) {
              setDialogState(() {
                editPincodes.removeAt(i);
                if (editPincodes.isEmpty) {
                  pinError = 'At least one service pincode is required';
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Update Doctor Profile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Dr. Jane Doe',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.\'-]")),
                          LengthLimitingTextInputFormatter(60),
                        ],
                        validator: (v) {
                          final name = (v ?? '').trim();
                          if (name.isEmpty) return 'Doctor full name is mandatory';
                          if (name.length < 2) return 'Name must be at least 2 characters';
                          if (!RegExp(r"^[a-zA-Z\s\.\'-]{2,60}$").hasMatch(name)) {
                            return 'Enter a valid name with alphabetic characters only';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: specCtrl,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Specialization',
                          hintText: 'e.g. Psychiatry, Addiction Medicine',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s&/,\.\'-]")),
                          LengthLimitingTextInputFormatter(60),
                        ],
                        validator: (v) {
                          final spec = (v ?? '').trim();
                          if (spec.isEmpty) return 'Specialization is mandatory';
                          if (spec.length < 2) return 'Specialization must be at least 2 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+91 9876543210 or 9876543210',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s]')),
                          LengthLimitingTextInputFormatter(16),
                        ],
                        validator: (v) {
                          final phone = (v ?? '').trim();
                          if (phone.isEmpty) return 'Phone number is mandatory';
                          final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length < 10 || digitsOnly.length > 15) {
                            return 'Phone number must have between 10 and 15 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Service Pincodes / Coverage',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            '${editPincodes.length} added',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Text & numbers up to 8 chars. Area patients will match these postcodes.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pinInputCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 8,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 302017, SW1A1AA',
                                prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                                counterText: '',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                                LengthLimitingTextInputFormatter(8),
                              ],
                              onFieldSubmitted: (_) => addPin(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: addPin,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (pinError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          pinError ?? "",
                          style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (editPincodes.isEmpty)
                        Text(
                          'No pincodes added yet. Add at least one pincode.',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 11),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(editPincodes.length, (i) {
                            return Chip(
                              label: Text(
                                editPincodes[i],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              deleteIconColor: Colors.red.shade600,
                              onDeleted: () => removePin(i),
                              backgroundColor: _primaryColor.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: _primaryColor.withValues(alpha: 0.25)),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (editPincodes.isEmpty) {
                            setDialogState(() => pinError = 'At least one service pincode is required');
                            return;
                          }
                          if ((formKey.currentState?.validate() ?? false)) {
                            setDialogState(() => isSaving = true);
                            try {
                              final cleanPincodes = editPincodes.join(', ');
                              await DoctorService.updateProfile(
                                name: nameCtrl.text.trim(),
                                specialization: specCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                                servicePincode: cleanPincodes,
                              );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop(true);
                              }
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update: $e'),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: _primaryColor),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      _loadDashboardData();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out'),
        content: const Text(
          'Are you sure you want to sign out from the Doctor Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DoctorService.signOut();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _openCardCategory(int index) {
    setState(() => _selectedFilterIndex = index);
  }

  Widget _buildCategoryInfoBanner() {
    final criticalCount = _allPatients.where((p) => p['isCriticalRisk'] == true).length;
    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (_selectedFilterIndex == 0) {
      color = _primaryColor;
      icon = Icons.location_on_rounded;
      title = 'Area Patients (${_matchingPatients.length})';
      subtitle = _doctorPincodes.isEmpty
          ? 'Showing patients residing in your service postcodes. None currently configured.'
          : 'Showing patients in your coverage area (${_doctorPincodes.join(', ')}). You have clinical oversight for these individuals.';
    } else if (_selectedFilterIndex == 1) {
      color = Colors.red.shade700;
      icon = Icons.warning_amber_rounded;
      title = 'Critical Risk Patients ($criticalCount)';
      subtitle =
          'Showing high-priority patients scoring ≥ 30 on clinical assessments. Immediate review and triage recommended.';
    } else {
      color = Colors.indigo;
      icon = Icons.people_outline;
      title = 'All Patients (${_allPatients.length})';
      subtitle =
          'Complete directory of all registered participants across all geographical zones and risk profiles.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> get _displayedPatients {
    if (_selectedFilterIndex == 0) {
      return _matchingPatients;
    } else if (_selectedFilterIndex == 1) {
      return _allPatients.where((p) => p['isCriticalRisk'] == true).toList();
    } else {
      return _allPatients;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = _doctor['fullName'] ?? _doctor['name'] ?? 'Doctor';
    final email = _doctor['email'] ?? '';
    final specialization = _doctor['specialization'] ?? 'General Practitioner';
    final phone = _doctor['phoneNumber'] ?? 'Not set';

    final criticalCount = _allPatients.where((p) => p['isCriticalRisk'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const NovtekBrandLockup(iconSize: 28, subtitle: 'CLINICAL DOCTOR'),
        backgroundColor: Colors.white,
        foregroundColor: _secondaryColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Doctor Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. $doctorName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                specialization,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showEditProfileDialog,
                          icon: const Icon(Icons.edit_outlined, color: Colors.white),
                          tooltip: 'Edit Profile',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.phone_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Service Postcodes / Coverage:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _doctorPincodes.isEmpty
                        ? Text(
                            'No postcodes configured. Tap edit to assign service areas.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _doctorPincodes.map((pin) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  pin,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overview Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Area Patients',
                      value: '${_matchingPatients.length}',
                      icon: Icons.location_on_outlined,
                      color: _primaryColor,
                      isSelected: _selectedFilterIndex == 0,
                      onTap: () => _openCardCategory(0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Critical Risk',
                      value: '$criticalCount',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      isSelected: _selectedFilterIndex == 1,
                      onTap: () => _openCardCategory(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'All Patients',
                      value: '${_allPatients.length}',
                      icon: Icons.people_outline,
                      color: Colors.indigo,
                      isSelected: _selectedFilterIndex == 2,
                      onTap: () => _openCardCategory(2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category Explanatory Banner
              _buildCategoryInfoBanner(),

              const SizedBox(height: 20),

              // Segmented Filter
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text('Area (${_matchingPatients.length})'),
                    icon: const Icon(Icons.near_me_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Critical ($criticalCount)'),
                    icon: const Icon(Icons.emergency_outlined),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('All (${_allPatients.length})'),
                    icon: const Icon(Icons.list_alt_rounded),
                  ),
                ],
                selected: {_selectedFilterIndex},
                onSelectionChanged: (set) {
                  setState(() => _selectedFilterIndex = set.first);
                },
              ),

              const SizedBox(height: 16),

              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                ),
              ] else if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error ?? "",
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ] else if (_displayedPatients.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilterIndex == 0
                              ? 'No patients found matching your service postcodes.'
                              : _selectedFilterIndex == 1
                                  ? 'No patients currently flagged with critical risk.'
                                  : 'No registered patients found.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFilterIndex == 0 && _doctorPincodes.isEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showEditProfileDialog,
                            child: const Text('Add your service postcodes'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _displayedPatients.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final patient = _displayedPatients[index] as Map<String, dynamic>;
                    return _PatientCard(
                      patient: patient,
                      primaryColor: _primaryColor,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isSelected ? 2 : 0,
      shadowColor: color.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: color,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.primaryColor,
  });

  final Map<String, dynamic> patient;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] ?? 'Anonymous Participant';
    final email = patient['email'] ?? '';
    final pin = patient['pinCode'] ?? 'No postcode';
    final gender = patient['gender'] ?? '';
    final age = patient['age'] != null && patient['age'].toString().isNotEmpty
        ? '${patient['age']}'
        : '';
    final isCritical = patient['isCriticalRisk'] == true;
    final maxScore = patient['maxScore'] ?? 0;
    final category = patient['surveyCategory'] ?? 'ADDICTION';
    final submissions = (patient['submissions'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? Colors.red.shade300 : Colors.grey.shade200,
          width: isCritical ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isCritical
                    ? Colors.red.shade100
                    : primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  isCritical ? Icons.warning_amber_rounded : Icons.person_outline,
                  color: isCritical ? Colors.red.shade700 : primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CRITICAL RISK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoBadge(icon: Icons.pin_drop_outlined, text: 'PIN: $pin'),
              if (age.isNotEmpty) ...[
                const SizedBox(width: 8),
                _InfoBadge(icon: Icons.calendar_today_outlined, text: age),
              ],
              if (gender.isNotEmpty && gender != 'Not specified') ...[
                const SizedBox(width: 8),
                _InfoBadge(icon: Icons.wc_outlined, text: gender),
              ],
              const Spacer(),
              _InfoBadge(
                icon: Icons.category_outlined,
                text: category,
                color: Colors.indigo,
              ),
            ],
          ),
          if (submissions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Assessments: ${submissions.length} submission(s) • Highest Score: $maxScore',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
