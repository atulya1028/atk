import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'doctor_dashboard_page.dart';
import 'doctor_service.dart';

class DoctorProfileSetupPage extends StatefulWidget {
  const DoctorProfileSetupPage({
    super.key,
    this.email,
    this.doctorId,
  });

  final String? email;
  final String? doctorId;

  @override
  State<DoctorProfileSetupPage> createState() => _DoctorProfileSetupPageState();
}

class _DoctorProfileSetupPageState extends State<DoctorProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specController = TextEditingController(text: 'General Practitioner');
  final _phoneController = TextEditingController();
  final _pincodeInputController = TextEditingController();

  final List<String> _pincodes = [];
  String? _pincodeError;
  bool _isSaving = false;

  static const Color _primaryColor = Color(0xFF197278);
  static const Color _secondaryColor = Color(0xFF283D3B);

  final List<String> _commonSpecializations = [
    'General Practitioner',
    'Psychiatrist',
    'Addiction Specialist',
    'Clinical Psychologist',
    'Neurologist',
    'Counselor',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _specController.dispose();
    _phoneController.dispose();
    _pincodeInputController.dispose();
    super.dispose();
  }

  void _addPincode() {
    final rawInput = _pincodeInputController.text.trim();
    if (rawInput.isEmpty) {
      setState(() => _pincodeError = 'Enter a pincode to add');
      return;
    }

    if (rawInput.length < 2 || rawInput.length > 8) {
      setState(() => _pincodeError = 'Pincode must be between 2 and 8 characters');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9\s]{2,8}$').hasMatch(rawInput)) {
      setState(() => _pincodeError = 'Pincode can only contain letters and numbers');
      return;
    }

    final normalized = rawInput.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
    final alreadyExists = _pincodes.any(
      (p) => p.replaceAll(RegExp(r'\s+'), '').toUpperCase() == normalized.replaceAll(' ', ''),
    );

    if (alreadyExists) {
      setState(() => _pincodeError = 'Pincode "$normalized" has already been added');
      return;
    }

    setState(() {
      _pincodes.add(normalized);
      _pincodeInputController.clear();
      _pincodeError = null;
    });
  }

  void _removePincode(int index) {
    setState(() {
      _pincodes.removeAt(index);
      if (_pincodes.isEmpty) {
        _pincodeError = 'At least one service pincode is required';
      }
    });
  }

  Future<void> _submitRegistration() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (_pincodes.isEmpty) {
      setState(() => _pincodeError = 'Please add at least one service pincode / coverage area');
      return;
    }

    if (!isFormValid) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final specialization = _specController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final servicePincodes = _pincodes.join(', ');

      await DoctorService.updateProfile(
        name: name,
        specialization: specialization,
        phoneNumber: phoneNumber,
        servicePincode: servicePincodes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Doctor registration completed successfully! Welcome to the portal.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DoctorDashboardPage(
            initialDoctor: {
              'id': widget.doctorId,
              'email': widget.email,
              'name': name,
              'specialization': specialization,
              'phoneNumber': phoneNumber,
              'servicePincode': servicePincodes,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        backgroundColor: Colors.white,
        foregroundColor: _secondaryColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header banner
                Container(
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
                        color: _primaryColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Clinical Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Set up your credentials and coverage areas to start reviewing patient assessments.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if ((widget.email ?? "").isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.lightGreenAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                widget.email ?? "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Doctor Full Name
                const Text(
                  'Full Name *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dr. Jane Smith',
                    prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.\'-]")),
                    LengthLimitingTextInputFormatter(60),
                  ],
                  validator: (v) {
                    final name = (v ?? '').trim();
                    if (name.isEmpty) return 'Doctor full name is required';
                    if (name.length < 2) return 'Full name must be at least 2 characters';
                    if (!RegExp(r"^[a-zA-Z\s\.\'-]{2,60}$").hasMatch(name)) {
                      return 'Enter letters and standard characters only';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Specialization
                const Text(
                  'Clinical Specialization *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _specController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Addiction Medicine, Psychiatry',
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: _primaryColor),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s&/,\.\'-]")),
                    LengthLimitingTextInputFormatter(60),
                  ],
                  validator: (v) {
                    final spec = (v ?? '').trim();
                    if (spec.isEmpty) return 'Specialization is required';
                    if (spec.length < 2) return 'Specialization must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonSpecializations.map((spec) {
                    final isSelected = _specController.text.trim().toLowerCase() == spec.toLowerCase();
                    return ActionChip(
                      label: Text(spec),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: isSelected ? _primaryColor : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? _primaryColor : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _specController.text = spec;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Contact Phone Number
                const Text(
                  'Contact Phone Number *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 9876543210 (10 to 15 digits)',
                    prefixIcon: Icon(Icons.phone_outlined, color: _primaryColor),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (v) {
                    final phone = (v ?? '').trim();
                    if (phone.isEmpty) return 'Phone number is required';
                    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
                      return 'Phone number must have between 10 and 15 digits';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Multiple Service Pincodes Section
                Row(
                  children: [
                    const Text(
                      'Service Pincodes / Coverage *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pincodes.length} added',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Add one or multiple postcodes (letters and numbers, max 8 chars). Area patients with matching postcodes will be assigned to you.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),

                // Pincode Input & Add Button Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeInputController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. 302017 or SW1A1AA',
                          prefixIcon: const Icon(Icons.pin_drop_outlined, color: _primaryColor),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLength: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onFieldSubmitted: (_) => _addPincode(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _addPincode,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),

                if (_pincodeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _pincodeError ?? "",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Display added pincodes as chips
                if (_pincodes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No service pincodes added yet. Enter a pincode above and tap "Add".',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_pincodes.length, (index) {
                        final pin = _pincodes[index];
                        return Chip(
                          avatar: const CircleAvatar(
                            backgroundColor: _primaryColor,
                            radius: 10,
                            child: Icon(Icons.location_on, size: 12, color: Colors.white),
                          ),
                          label: Text(
                            pin,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _secondaryColor,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          deleteIconColor: Colors.red.shade600,
                          onDeleted: () => _removePincode(index),
                          backgroundColor: _primaryColor.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _primaryColor.withValues(alpha: 0.3)),
                          ),
                        );
                      }),
                    ),
                  ),

                const SizedBox(height: 36),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitRegistration,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Complete Doctor Registration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
