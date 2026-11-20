import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'admin_service.dart';

const Color _adminPrimary = Color(0xFF0F172A); // Slate 900
const Color _adminDark = Color(0xFF1E293B); // Slate 800
const Color _adminAccent = Color(0xFF0284C7); // Sky 600

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.initialAdmin});

  final Map<String, dynamic>? initialAdmin;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentTab = 0; // 0: Overview, 1: Submissions, 2: Patients, 3: Doctors, 4: Audit Logs
  String _currentCategory = ''; // '': All Paths, 'ADDICTION', 'MENTAL'
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _adminProfile = {};
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _segmentation = {};
  List<dynamic> _submissions = [];
  List<dynamic> _logs = [];
  List<dynamic> _doctors = [];
  List<dynamic> _patients = [];

  // Filter & Search states
  String _doctorSearch = '';
  String _patientSearch = '';
  int _patientRiskFilter = 0; // 0: All, 1: Critical Only, 2: Normal Only
  String _submissionSearch = '';
  String _submissionStageFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialAdmin != null) {
      _adminProfile = Map<String, dynamic>.from(widget.initialAdmin ?? {});
    }
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final token = await AdminService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AdminService.getStats(category: _currentCategory),
        AdminService.getDoctors(),
        AdminService.getPatients(),
        AdminService.getProfile().catchError((_) => <String, dynamic>{}),
        AdminService.getSubmissions().catchError((_) => <dynamic>[]),
        AdminService.getLogs().catchError((_) => <dynamic>[]),
      ]);

      if (!mounted) return;

      setState(() {
        final statsData = results[0] as Map<String, dynamic>;
        _stats = (statsData['stats'] as Map<String, dynamic>?) ?? statsData;
        _segmentation = (statsData['segmentation'] as Map<String, dynamic>?) ?? {};
        _doctors = results[1] as List<dynamic>;
        _patients = results[2] as List<dynamic>;
        if ((results[3] as Map).isNotEmpty) {
          _adminProfile = results[3] as Map<String, dynamic>;
        }
        _submissions = results[4] as List<dynamic>;
        _logs = results[5] as List<dynamic>;
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Admin Sign Out'),
        content: const Text('Are you sure you want to end your administrative session?'),
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
      await AdminService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
    }
  }

  // --- DOCTOR ACTIONS ---

  Future<void> _showAddDoctorDialog() async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController(text: 'General Practitioner');
    final phoneCtrl = TextEditingController();
    final pinInputCtrl = TextEditingController();
    final List<String> pincodes = [];
    String? pinError;
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addPin() {
              final raw = pinInputCtrl.text.trim();
              if (raw.isEmpty) {
                setDialogState(() => pinError = 'Enter pincode');
                return;
              }
              if (raw.length < 2 || raw.length > 8) {
                setDialogState(() => pinError = 'Must be 2-8 chars');
                return;
              }
              if (!RegExp(r'^[a-zA-Z0-9\s]{2,8}$').hasMatch(raw)) {
                setDialogState(() => pinError = 'Alphanumeric only');
                return;
              }
              final norm = raw.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
              if (pincodes.contains(norm)) {
                setDialogState(() => pinError = 'Already added');
                return;
              }
              setDialogState(() {
                pincodes.add(norm);
                pinInputCtrl.clear();
                pinError = null;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: _adminAccent),
                  SizedBox(width: 10),
                  Text('Register New Doctor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Doctor Email *',
                          hintText: 'doctor@hospital.org',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          TextInputFormatter.withFunction((_, n) => n.copyWith(text: n.text.toLowerCase())),
                        ],
                        validator: (v) {
                          final e = (v ?? '').trim().toLowerCase();
                          if (e.isEmpty) return 'Email is required';
                          if (!e.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Dr. Jane Smith',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v ?? '').trim().length < 2 ? 'Minimum 2 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: specCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Specialization *',
                          hintText: 'e.g. Psychiatry, Physician',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Specialization required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+91 9876543210',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Service Postcodes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text('${pincodes.length} added', style: const TextStyle(fontSize: 11, color: _adminAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pinInputCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 8,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 302017',
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
                            style: FilledButton.styleFrom(backgroundColor: _adminAccent),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (pinError != null) ...[
                        const SizedBox(height: 4),
                        Text(pinError ?? "", style: TextStyle(color: Colors.red.shade700, fontSize: 11)),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(pincodes.length, (i) {
                          return Chip(
                            label: Text(pincodes[i], style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 13),
                            onDeleted: () => setDialogState(() => pincodes.removeAt(i)),
                            backgroundColor: _adminAccent.withValues(alpha: 0.1),
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
                          if ((formKey.currentState?.validate() ?? false)) {
                            setDialogState(() => isSaving = true);
                            try {
                              await AdminService.createDoctor(
                                email: emailCtrl.text.trim().toLowerCase(),
                                fullName: nameCtrl.text.trim(),
                                specialization: specCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                                servicePincode: pincodes.join(', '),
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: _adminPrimary),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register Doctor'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) _loadAllData();
  }

  Future<void> _showEditDoctorDialog(Map<String, dynamic> doctor) async {
    final nameCtrl = TextEditingController(text: doctor['fullName']?.toString() ?? '');
    final specCtrl = TextEditingController(text: doctor['specialization']?.toString() ?? 'General Practitioner');
    final phoneCtrl = TextEditingController(text: doctor['phoneNumber']?.toString() ?? '');
    final pinInputCtrl = TextEditingController();
    final rawCodes = (doctor['servicePincode']?.toString() ?? '')
        .split(',')
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .toList();
    final List<String> editPincodes = List<String>.from(rawCodes);
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
              if (raw.isEmpty) return;
              if (raw.length < 2 || raw.length > 8 || !RegExp(r'^[a-zA-Z0-9\s]{2,8}$').hasMatch(raw)) {
                setDialogState(() => pinError = 'Pincode must be 2-8 alphanumeric chars');
                return;
              }
              final norm = raw.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
              if (editPincodes.contains(norm)) {
                setDialogState(() => pinError = 'Pincode already added');
                return;
              }
              setDialogState(() {
                editPincodes.add(norm);
                pinInputCtrl.clear();
                pinError = null;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Doctor: ${doctor['fullName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Doctor Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v ?? '').trim().length < 2 ? 'Minimum 2 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: specCtrl,
                        decoration: const InputDecoration(labelText: 'Specialization', prefixIcon: Icon(Icons.medical_services_outlined)),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Coverage Postcodes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text('${editPincodes.length} configured', style: const TextStyle(fontSize: 11, color: _adminAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: pinInputCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 8,
                              decoration: const InputDecoration(
                                hintText: 'Add code (e.g. 302017)',
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
                            style: FilledButton.styleFrom(backgroundColor: _adminAccent),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (pinError != null) ...[
                        const SizedBox(height: 4),
                        Text(pinError ?? "", style: TextStyle(color: Colors.red.shade700, fontSize: 11)),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(editPincodes.length, (i) {
                          return Chip(
                            label: Text(editPincodes[i], style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 13),
                            onDeleted: () => setDialogState(() => editPincodes.removeAt(i)),
                            backgroundColor: _adminAccent.withValues(alpha: 0.1),
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
                          if ((formKey.currentState?.validate() ?? false)) {
                            setDialogState(() => isSaving = true);
                            try {
                              await AdminService.updateDoctor(
                                doctor['id'].toString(),
                                fullName: nameCtrl.text.trim(),
                                specialization: specCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                                servicePincode: editPincodes.join(', '),
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red.shade700),
                                );
                              }
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: _adminPrimary),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) _loadAllData();
  }

  Future<void> _deleteDoctor(Map<String, dynamic> doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Doctor Account?'),
        content: Text('Are you sure you want to delete ${doctor['fullName']} (${doctor['email']})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete Doctor'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteDoctor(doctor['id'].toString());
        _loadAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete doctor: $e'), backgroundColor: Colors.red.shade700),
          );
        }
      }
    }
  }

  // --- PATIENT ACTIONS ---

  Future<void> _showEditPatientDialog(Map<String, dynamic> patient) async {
    final nameCtrl = TextEditingController(text: patient['fullName']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: patient['phoneNumber']?.toString() ?? '');
    final pinCtrl = TextEditingController(text: patient['postcode']?.toString() ?? '');
    final ageCtrl = TextEditingController(text: patient['ageGroup']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Edit Patient: ${patient['fullName']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v ?? '').trim().length < 2 ? 'Minimum 2 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pinCtrl,
                        maxLength: 8,
                        decoration: const InputDecoration(labelText: 'Postcode / Pincode', prefixIcon: Icon(Icons.pin_drop_outlined), counterText: ''),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                          LengthLimitingTextInputFormatter(8),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ageCtrl,
                        decoration: const InputDecoration(labelText: 'Age Group', prefixIcon: Icon(Icons.cake_outlined)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if ((formKey.currentState?.validate() ?? false)) {
                            setDialogState(() => isSaving = true);
                            try {
                              await AdminService.updatePatient(
                                patient['id'].toString(),
                                fullName: nameCtrl.text.trim(),
                                postcode: pinCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                                ageGroup: ageCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red.shade700),
                                );
                              }
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: _adminPrimary),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) _loadAllData();
  }

  Future<void> _deletePatient(Map<String, dynamic> patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Patient Account?'),
        content: Text('Are you sure you want to permanently delete patient ${patient['fullName']}? All associated assessment history will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete Patient'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deletePatient(patient['id'].toString());
        _loadAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red.shade700),
          );
        }
      }
    }
  }

  // --- FILTERED LISTS ---

  List<dynamic> get _filteredDoctors {
    if (_doctorSearch.isEmpty) return _doctors;
    final q = _doctorSearch.toLowerCase();
    return _doctors.where((d) {
      final name = (d['fullName'] ?? '').toString().toLowerCase();
      final email = (d['email'] ?? '').toString().toLowerCase();
      final spec = (d['specialization'] ?? '').toString().toLowerCase();
      final pin = (d['servicePincode'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || spec.contains(q) || pin.contains(q);
    }).toList();
  }

  List<dynamic> get _filteredPatients {
    return _patients.where((p) {
      if (_patientRiskFilter == 1 && p['isCriticalRisk'] != true) return false;
      if (_patientRiskFilter == 2 && p['isCriticalRisk'] == true) return false;

      if (_patientSearch.isNotEmpty) {
        final q = _patientSearch.toLowerCase();
        final name = (p['fullName'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        final pin = (p['postcode'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || pin.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: _adminAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Novtek ATK Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: _adminPrimary,
        elevation: 1,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _adminProfile['email'] as String? ?? 'Admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _adminAccent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text(_error ?? "", style: TextStyle(color: Colors.red.shade800), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(onPressed: _loadAllData, child: const Text('Retry')),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              await AdminService.signOut();
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacementNamed('/admin');
                            },
                            child: const Text('Go to Admin Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Navigation Selector
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildTabButton(0, 'Dashboard', Icons.dashboard_outlined),
                                const SizedBox(width: 8),
                                _buildTabButton(1, 'Submissions (${_submissions.length})', Icons.assignment_outlined),
                                const SizedBox(width: 8),
                                _buildTabButton(2, 'Participants (${_patients.length})', Icons.people_outline),
                                const SizedBox(width: 8),
                                _buildTabButton(3, 'Doctors (${_doctors.length})', Icons.medical_services_outlined),
                                const SizedBox(width: 8),
                                _buildTabButton(4, 'Audit Logs (${_logs.length})', Icons.history_edu_outlined),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Active Tab View
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAllData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: _currentTab == 0
                                  ? _buildOverviewTab()
                                  : _currentTab == 1
                                      ? _buildSubmissionsTab()
                                      : _currentTab == 2
                                          ? _buildPatientsTab()
                                          : _currentTab == 3
                                              ? _buildDoctorsTab()
                                              : _buildLogsTab(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    return Material(
      color: isSelected ? _adminPrimary : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 0: OVERVIEW (IDENTICAL TO EZYZIP) ---

  Widget _buildOverviewTab() {
    final int totalReg = (_stats['totalRegistered'] as int?) ?? 0;
    final int totalUsers = (_stats['totalUsers'] as int?) ?? 1;
    final int totalStage2 = (_stats['totalStage2'] as int?) ?? 0;
    final int totalStage3 = (_stats['totalStage3Unlocked'] as int?) ?? 0;
    final int initSubs = (_stats['initialSubmissions'] as int?) ?? 0;
    final int detSubs = (_stats['detailedSubmissions'] as int?) ?? 0;
    final int active7d = (_stats['active7d'] as int?) ?? 0;
    final int active30d = (_stats['active30d'] as int?) ?? 0;
    final recentSubs = (_stats['recentSubmissions'] as List?) ?? [];

    final ageList = (_segmentation['age'] as List?) ?? [
      {'label': '18-24', 'value': 0},
      {'label': '25-34', 'value': 0},
      {'label': '35-44', 'value': 0},
      {'label': '45-54', 'value': 0},
      {'label': '55+', 'value': 0},
    ];
    final genderList = (_segmentation['gender'] as List?) ?? [
      {'label': 'Male', 'value': 0},
      {'label': 'Female', 'value': 0},
      {'label': 'Non-Binary', 'value': 0},
      {'label': 'Other', 'value': 0},
    ];
    final maritalList = (_segmentation['marital'] as List?) ?? [
      {'label': 'Single', 'value': 0},
      {'label': 'Married', 'value': 0},
      {'label': 'Divorced / Separated', 'value': 0},
      {'label': 'Widowed', 'value': 0},
    ];

    final stage2Conversion = totalReg > 0 ? (totalStage2 * 100 / totalReg).round() : 0;
    final stage3Qual = totalStage2 > 0 ? (totalStage3 * 100 / totalStage2).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header & Filter (Same as ezyZip)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DASHBOARD',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'SYSTEM ANALYTICS OVERVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            // Filter Pills
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCategoryPill('All Paths', ''),
                  const SizedBox(width: 4),
                  _buildCategoryPill('Addiction', 'ADDICTION', activeColor: const Color(0xFF4F46E5)),
                  const SizedBox(width: 4),
                  _buildCategoryPill('Mental Health', 'MENTAL', activeColor: const Color(0xFF7C3AED)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 5 Metric Cards (Same as ezyZip)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            final isMedium = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isWide ? 5 : (isMedium ? 3 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isWide ? 1.25 : 1.3,
              children: [
                // 1. Registered Users
                _buildEzyCard(
                  title: 'REGISTERED USERS',
                  value: '$totalReg',
                  subtitle: 'Profile Completed',
                  icon: Icons.person_outline,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F46E5),
                  progress: totalUsers > 0 ? (totalReg as num) / (totalUsers as num) : 0.0,
                  progressColor: const Color(0xFF6366F1),
                ),
                // 2. Stage 2 Completed
                _buildEzyCard(
                  title: 'STAGE 2 COMPLETED',
                  value: '$totalStage2',
                  subtitle: 'Initial Survey',
                  icon: Icons.task_alt_outlined,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  footerText: '$stage2Conversion% Conversion from Registration',
                ),
                // 3. Stage 3 Unlocked
                _buildEzyCard(
                  title: 'STAGE 3 UNLOCKED',
                  value: '$totalStage3',
                  subtitle: 'Detailed Survey',
                  icon: Icons.lock_open_outlined,
                  iconBg: const Color(0xFFF5F3FF),
                  iconColor: const Color(0xFF7C3AED),
                  valueColor: const Color(0xFF7C3AED),
                  footerText: '$stage3Qual% Qualification Rate',
                ),
                // 4. Submissions Breakdown
                _buildEzySubmissionsCard(
                  initSubs: initSubs as int? ?? 0,
                  detSubs: detSubs as int? ?? 0,
                ),
                // 5. Active Users
                _buildEzyActiveUsersCard(
                  active7d: active7d as int? ?? 0,
                  active30d: active30d as int? ?? 0,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Demographic Segmentation (Same as ezyZip)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSegmentationCard('AGE GROUP DISTRIBUTION', ageList, totalReg, const Color(0xFF6366F1))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSegmentationCard('GENDER IDENTITY', genderList, totalReg, const Color(0xFF818CF8))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSegmentationCard('MARITAL STATUS', maritalList, totalReg, const Color(0xFFA5B4FC))),
                    ],
                  )
                : Column(
                    children: [
                      _buildSegmentationCard('AGE GROUP DISTRIBUTION', ageList, totalReg, const Color(0xFF6366F1)),
                      const SizedBox(height: 14),
                      _buildSegmentationCard('GENDER IDENTITY', genderList, totalReg, const Color(0xFF818CF8)),
                      const SizedBox(height: 14),
                      _buildSegmentationCard('MARITAL STATUS', maritalList, totalReg, const Color(0xFFA5B4FC)),
                    ],
                  );
          },
        ),

        const SizedBox(height: 28),

        // Recent Submissions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT SUBMISSIONS & ASSESSMENTS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _currentTab = 1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View All Submissions'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recentSubs.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(child: Text('No submissions recorded yet.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(6, recentSubs.length),
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sub = recentSubs[index] as Map<String, dynamic>;
              final isCrit = sub['isCriticalRisk'] == true;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isCrit ? const Color(0xFFFECACA) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isCrit ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF),
                      child: Icon(
                        isCrit ? Icons.warning_amber_rounded : Icons.assignment_outlined,
                        color: isCrit ? Colors.red.shade700 : const Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub['patientName'] ?? 'Anonymous Participant',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${sub['patientEmail']} • Stage: ${sub['type']} • PIN: ${sub['postcode']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Score: ${sub['score'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: isCrit ? Colors.red.shade700 : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isCrit)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('CRITICAL', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCategoryPill(String title, String category, {Color activeColor = const Color(0xFF0F172A)}) {
    final isSelected = _currentCategory == category;
    return InkWell(
      onTap: () {
        setState(() => _currentCategory = category);
        _loadAllData();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : null,
        ),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildEzyCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    Color? valueColor,
    double? progress,
    Color? progressColor,
    String? footerText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: valueColor ?? const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? const Color(0xFF6366F1)),
              ),
            )
          else if (footerText != null)
            Text(
              footerText,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildEzySubmissionsCard({required int initSubs, required int detSubs}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL SUBMISSIONS',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.grey.shade500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('STAGE 2', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4338CA))),
                Text('$initSubs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF312E81))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('STAGE 3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF6D28D9))),
                Text('$detSubs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF4C1D95))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEzyActiveUsersCard({required int active7d, required int active30d}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ACTIVE USERS',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.grey.shade500),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$active7d', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('LAST 7D', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade200),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$active30d', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('LAST 30D', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('TRACKING LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentationCard(String title, List<dynamic> list, int totalUsers, Color barColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          ...list.map((item) {
            final label = item['label'] ?? '';
            final val = item['value'] ?? 0;
            final pct = totalUsers > 0 ? ((val as num) / totalUsers) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      Text('$val', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: barColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- TAB 1: SUBMISSIONS MANAGEMENT ---

  Widget _buildSubmissionsTab() {
    final filtered = _submissions.where((s) {
      final text = _submissionSearch.toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      final name = (s['patientName'] ?? '').toString().toLowerCase();
      final id = (s['id'] ?? '').toString().toLowerCase();
      final matchesSearch = text.isEmpty || email.contains(text) || name.contains(text) || id.contains(text);
      final matchesStage = _submissionStageFilter == 'all' || (s['type'] ?? '') == _submissionStageFilter;
      return matchesSearch && matchesStage;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by participant name, email, or ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => setState(() => _submissionSearch = v),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _submissionStageFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Stages')),
                DropdownMenuItem(value: 'INITIAL', child: Text('Stage 2 (Initial)')),
                DropdownMenuItem(value: 'DETAILED', child: Text('Stage 3 (Detailed)')),
                DropdownMenuItem(value: 'MENTAL', child: Text('Mental Health')),
              ],
              onChanged: (v) => setState(() => _submissionStageFilter = v ?? 'all'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No matching submissions found.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sub = filtered[index] as Map<String, dynamic>;
              final isCrit = sub['isCriticalRisk'] == true;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isCrit ? const Color(0xFFFECACA) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isCrit ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF),
                      child: Icon(
                        isCrit ? Icons.warning_amber_rounded : Icons.assignment_turned_in_outlined,
                        color: isCrit ? Colors.red.shade700 : const Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub['patientName'] ?? 'Participant',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${sub['email']} • Stage: ${sub['type']} • PIN: ${sub['postcode']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Score: ${sub['score'] ?? 0}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isCrit ? Colors.red.shade700 : const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () => _showSubmissionDetailDialog(sub),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Inspect Answers', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showSubmissionDetailDialog(Map<String, dynamic> sub) {
    final answers = sub['answers'] as Map? ?? {};
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${sub['patientName']} - Answers (${sub['type']})'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Score: ${sub['score'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Email: ${sub['email']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const Divider(),
                if (answers.isEmpty)
                  const Text('No detailed answer fields recorded.')
                else
                  ...answers.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(child: Text('${e.value}', style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  // --- TAB 4: AUDIT LOGS ---

  Widget _buildLogsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SYSTEM AUDIT TRAIL',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        if (_logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No system audit logs found.')),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = _logs[index] as Map<String, dynamic>;
              final action = (log['action'] ?? '').toString();
              Color badgeColor = const Color(0xFF475569);
              Color badgeBg = const Color(0xFFF1F5F9);
              if (action.contains('SIGN_IN')) {
                badgeColor = const Color(0xFF2563EB);
                badgeBg = const Color(0xFFEFF6FF);
              } else if (action.contains('COMPLETED')) {
                badgeColor = const Color(0xFF16A34A);
                badgeBg = const Color(0xFFF0FDF4);
              } else if (action.contains('REGISTERED')) {
                badgeColor = const Color(0xFF9333EA);
                badgeBg = const Color(0xFFFAF5FF);
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(action, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log['userEmail'] ?? 'System', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(log['details'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text(
                      (log['createdAt'] ?? '').toString().split('T').first,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 1: DOCTORS MANAGEMENT ---

  Widget _buildDoctorsTab() {
    final docs = _filteredDoctors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Action Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _doctorSearch = v),
                decoration: InputDecoration(
                  hintText: 'Search doctors by name, email, specialization...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _showAddDoctorDialog,
              style: FilledButton.styleFrom(backgroundColor: _adminPrimary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Doctor'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.person_search_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No doctors match your search criteria.'),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index] as Map<String, dynamic>;
              final pincodes = (doc['servicePincode']?.toString() ?? '')
                  .split(',')
                  .map((c) => c.trim())
                  .where((c) => c.isNotEmpty)
                  .toList();
              final assignedCount = doc['assignedPatientsCount'] ?? 0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                          child: const Icon(Icons.medical_services_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['fullName'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  doc['specialization'] ?? 'General Practitioner',
                                  style: const TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showEditDoctorDialog(doc);
                            if (val == 'delete') _deleteDoctor(doc);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade100),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(child: Text(doc['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                        if (doc['phoneNumber'] != null && doc['phoneNumber'].toString().isNotEmpty) ...[
                          Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(doc['phoneNumber'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Coverage PINs: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _adminDark)),
                        Expanded(
                          child: pincodes.isEmpty
                              ? Text('None configured', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                              : Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: pincodes.map((pin) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text(pin, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _adminAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('$assignedCount area patient(s)', style: const TextStyle(fontSize: 11, color: _adminAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 2: PATIENTS DIRECTORY ---

  Widget _buildPatientsTab() {
    final patients = _filteredPatients;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _patientSearch = v),
                decoration: InputDecoration(
                  hintText: 'Search patients by name, email, pincode...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Risk Filter Chips
        Row(
          children: [
            ChoiceChip(
              label: Text('All (${_patients.length})'),
              selected: _patientRiskFilter == 0,
              onSelected: (_) => setState(() => _patientRiskFilter = 0),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('Critical Risk (${_patients.where((p) => p['isCriticalRisk'] == true).length})'),
              selected: _patientRiskFilter == 1,
              selectedColor: Colors.red.shade100,
              onSelected: (_) => setState(() => _patientRiskFilter = 1),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Normal'),
              selected: _patientRiskFilter == 2,
              onSelected: (_) => setState(() => _patientRiskFilter = 2),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (patients.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.person_search_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No patients match your search filter.'),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: patients.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pat = patients[index] as Map<String, dynamic>;
              final isCrit = pat['isCriticalRisk'] == true;
              final maxScore = pat['maxScore'] ?? 0;
              final coveringDoctors = (pat['coveringDoctors'] as List?) ?? [];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCrit ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isCrit ? Colors.red.shade300 : Colors.grey.shade200, width: isCrit ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isCrit ? Colors.red.shade100 : Colors.indigo.shade50,
                          child: Icon(
                            isCrit ? Icons.warning_rounded : Icons.person_outline,
                            color: isCrit ? Colors.red.shade700 : Colors.indigo,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(pat['fullName'] ?? 'Anonymous Participant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  if (isCrit)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('CRITICAL RISK', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(pat['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showEditPatientDialog(pat);
                            if (val == 'delete') _deletePatient(pat);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit Details')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: isCrit ? Colors.red.shade100 : Colors.grey.shade100),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildPatientDetailChip(Icons.pin_drop_outlined, 'PIN: ${pat['postcode'] ?? 'N/A'}'),
                        const SizedBox(width: 8),
                        if (pat['ageGroup'] != null && pat['ageGroup'].toString().isNotEmpty) ...[
                          _buildPatientDetailChip(Icons.cake_outlined, 'Age: ${pat['ageGroup']}'),
                          const SizedBox(width: 8),
                        ],
                        if (pat['gender'] != null && pat['gender'].toString().isNotEmpty) ...[
                          _buildPatientDetailChip(Icons.transgender_outlined, '${pat['gender']}'),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        Text(
                          'Max Score: $maxScore',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isCrit ? Colors.red.shade700 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    if (coveringDoctors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Assigned Doctor: ${coveringDoctors.join(', ')}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPatientDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
