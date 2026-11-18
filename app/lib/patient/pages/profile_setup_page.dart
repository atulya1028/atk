import 'package:atk/patient/widgets/responsive_action.dart';
import 'package:atk/patient/services/api_client.dart';
import 'package:atk/patient/widgets/responsive_content.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class ProfileSetupPage extends StatefulWidget {
  final bool isEditing;
  const ProfileSetupPage({super.key, this.isEditing = false});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();

  String? _selectedAgeGroup;
  String? _selectedGender;
  String? _selectedMaritalStatus;

  final List<String> _ageGroups = [
    '18-25',
    '26-35',
    '36-45',
    '46-55',
    '56-64',
    '65+',
  ];
  final List<String> _genders = [
    'Male',
    'Female',
    'Non-Binary',
    'Prefer not to say',
  ];
  final List<String> _maritalOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final profile = await ApiClient.getProfile();
      if (!mounted || profile == null) return;
      _nameController.text = profile['fullName'] as String? ?? '';
      _phoneController.text = profile['phoneNumber'] as String? ?? '';
      _pinController.text = profile['postcode'] as String? ?? '';
      _occupationController.text = profile['occupation'] as String? ?? '';
      _selectedAgeGroup = profile['ageGroup'] as String?;
      _selectedGender = profile['gender'] as String?;
      _selectedMaritalStatus = profile['maritalStatus'] as String?;
    } catch (error) {
      if (mounted) {
        _loadError = error is ApiException
            ? error.message
            : 'Could not load your profile. Try again.';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Iterable<String> _withSavedOption(List<String> options, String? saved) sync* {
    yield* options;
    if (saved != null && !options.contains(saved)) yield saved;
  }

  Future<void> _submitProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final phone = _phoneController.text.trim();
      await ApiClient.saveProfile({
        'fullName': _nameController.text.trim(),
        'ageGroup': _selectedAgeGroup,
        'phoneNumber': phone.isEmpty ? null : phone,
        'postcode': _pinController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'gender': _selectedGender,
        'maritalStatus': _selectedMaritalStatus,
      });
      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
          arguments: ModalRoute.of(context)?.settings.arguments,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Could not save your profile. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'Complete Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!),
                  TextButton(
                    onPressed: _loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ResponsiveContent(
                maxWidth: 600,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.isEditing
                            ? 'Update your personal information below.'
                            : 'Please complete your profile to continue.',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        maxLength: 30,
                        enabled: !_isSaving,
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (v) {
                          if ((v == null || v.trim().isEmpty)) {
                            return 'Full Name is mandatory';
                          }
                          if ((v.trim().length < 2 || v.trim().length > 100)) {
                            return 'Please enter a valid name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedAgeGroup,
                        decoration: const InputDecoration(
                          labelText: 'Age Group',
                        ),
                        items: _withSavedOption(_ageGroups, _selectedAgeGroup)
                            .map(
                              (group) => DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (v) => setState(() => _selectedAgeGroup = v),
                        validator: (v) =>
                            v == null ? 'Age selection is mandatory' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        maxLength: 15,
                        enabled: !_isSaving,
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Optional)',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final phoneRegex = RegExp(r'^\+?[\d\s\-]{8,15}$');
                          if ((!phoneRegex.hasMatch(v.trim()))) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        maxLength: 8,
                        enabled: !_isSaving,
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'Postcode (Mandatory)',
                        ),
                        // 1. Change keyboard from number-only to standard text
                        keyboardType: TextInputType.text,
                        // 2. Allow letters, numbers, and spaces instead of digitsOnly
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\s]'),
                          ),
                          LengthLimitingTextInputFormatter(
                            8,
                          ), // Matched to your maxLength
                        ],
                        validator: (v) {
                          final value = v?.trim() ?? '';

                          if (value.isEmpty) {
                            return 'Postcode is mandatory';
                          }

                          // 3. Validate alphanumeric characters (e.g., 5 to 8 characters long)
                          if (!RegExp(r'^[a-zA-Z0-9\s]{5,8}$')
                              .hasMatch(value)) {
                            return 'Enter a valid alphanumeric postcode';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender (Mandatory)',
                        ),
                        items: _withSavedOption(_genders, _selectedGender)
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (v) => setState(() => _selectedGender = v),
                        validator: (v) =>
                            v == null ? 'Gender is mandatory' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: !_isSaving,
                        controller: _occupationController,
                        decoration: const InputDecoration(
                          labelText: 'Occupation (Mandatory)',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Occupation is mandatory'
                            : v.trim().length > 100
                            ? 'Use 100 characters or fewer'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedMaritalStatus,
                        decoration: const InputDecoration(
                          labelText: 'Marital Status (Mandatory)',
                        ),
                        items:
                            _withSavedOption(
                                  _maritalOptions,
                                  _selectedMaritalStatus,
                                )
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                        onChanged: _isSaving
                            ? null
                            : (v) => setState(() => _selectedMaritalStatus = v),
                        validator: (v) =>
                            v == null ? 'Marital status is mandatory' : null,
                      ),
                      const SizedBox(height: 32),
                      ResponsiveAction(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _submitProfile,
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  widget.isEditing
                                      ? 'Save Changes'
                                      : 'Save & Continue',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
