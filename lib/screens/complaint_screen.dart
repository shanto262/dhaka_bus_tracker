import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/language_provider.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>(); 

  String? _selectedCompany; 
  String? _selectedComplaintType = 'Overcharging Fare';
  
  final TextEditingController _busIdController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _companies = ['Bikash Paribahan', 'Prochesta Paribahan', 'BRTC City Service' , 'Thikana Paribahan', 'Turag Paribahan','Raida Enterprise'];

  // Variables for Image and Loading State
  File? _selectedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _busIdController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600, 
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitComplaint(LanguageProvider langProvider) async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() {
      _isSubmitting = true; 
    });

    try {
      String? base64Image;

      if (_selectedImage != null) {
        List<int> imageBytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(imageBytes); 
        
        // Safety check: Firestore limit is ~1MB (1,048,576 bytes)
        if (base64Image.length > 950000) {
           throw Exception('Photo is still too large for the database. Please try a different photo without zooming in.');
        }
      }

      // Save everything directly to your existing Firestore Database
      await FirebaseFirestore.instance.collection('complaints').add({
        'company_name': _selectedCompany,
        'bus_id': _busIdController.text.trim(),
        'complaint_type': _selectedComplaintType,
        'details': _detailsController.text.trim(),
        'photo_base64': base64Image, 
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      setState(() {
        _isSubmitting = false;
      });

      // Show Success Dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: const EdgeInsets.all(24),
            backgroundColor: Theme.of(context).cardColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                ),
                const SizedBox(height: 16),
                Text(langProvider.t('Thank you!'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                    children: [
                      TextSpan(text: langProvider.t('Your report ')),
                      const TextSpan(text: '#C-414', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: langProvider.t(' has been sent to ')),
                      TextSpan(text: '$_selectedCompany.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('BRTA REF • C-414', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(langProvider.t('Bus Company Admin will look into this.'), 
                  style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Reset the form
                      _busIdController.clear();
                      _detailsController.clear();
                      setState(() {
                        _selectedCompany = null;
                        _selectedComplaintType = 'Overcharging Fare';
                        _selectedImage = null; // Clear image
                      });
                    },
                    child: Text(langProvider.t('Done'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(langProvider.t('Submit Complaint'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(langProvider.t('Dhaka Bus Tracker · BRTC Authority'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBusInfoSection(langProvider),
              const SizedBox(height: 16),
              _buildComplaintTypeSection(langProvider),
              const SizedBox(height: 16),
              _buildDetailsSection(langProvider),
              const SizedBox(height: 24),
              _buildSubmitButton(langProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfoSection(LanguageProvider langProvider) {
    return _buildCardWrapper(
      title: langProvider.t('Bus Information'),
      icon: Icons.directions_bus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(langProvider.t('Bus Line Company *'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCompany,
            hint: Text(langProvider.t('Select a company')),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return langProvider.t('Please select a company');
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _companies.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (newValue) => setState(() => _selectedCompany = newValue),
          ),
          const SizedBox(height: 16),
          Text(langProvider.t('Bus ID *'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _busIdController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return langProvider.t('Please enter the Bus ID');
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: langProvider.t('e.g. Dhaka Metro-Cha 11-2367'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
              suffixIcon: const Icon(Icons.location_on, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintTypeSection(LanguageProvider langProvider) {
    return _buildCardWrapper(
      title: langProvider.t('Complaint Type'),
      icon: Icons.warning_amber_rounded,
      child: Column(
        children: [
          _buildRadioOption('Overcharging Fare', langProvider.t('Overcharging Fare'), langProvider.t('Charged more than official fare'), Icons.money_off),
          const SizedBox(height: 8),
          _buildRadioOption('Reckless Driving', langProvider.t('Reckless Driving'), langProvider.t('Dangerous or aggressive driving'), Icons.speed),
          const SizedBox(height: 8),
          _buildRadioOption('Other', langProvider.t('Other'), langProvider.t('Other issues not listed above'), Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String valueKey, String translatedTitle, String subtitle, IconData icon) {
    bool isSelected = _selectedComplaintType == valueKey;
    return InkWell(
      onTap: () => setState(() => _selectedComplaintType = valueKey),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: valueKey,
              groupValue: _selectedComplaintType,
              activeColor: Colors.orange,
              onChanged: (value) => setState(() => _selectedComplaintType = value),
            ),
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(translatedTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.orange : null)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(LanguageProvider langProvider) {
    return _buildCardWrapper(
      title: langProvider.t('Details / Description'),
      icon: Icons.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _detailsController,
            maxLines: 4,
            maxLength: 500,
            validator: (value) {
              if (_selectedComplaintType == 'Other' && (value == null || value.trim().isEmpty)) {
                return langProvider.t('Please provide details for your complaint');
              }
              return null; 
            },
            decoration: InputDecoration(
              hintText: langProvider.t('Be as specific as possible — it helps our review team.'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage, 
                icon: const Icon(Icons.camera_alt, size: 16), 
                label: Text(langProvider.t(_selectedImage == null ? 'Add Photo' : 'Change Photo'))
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, width: 50, height: 50, fit: BoxFit.cover),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                )
              ]
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(langProvider.t('REPORT SUMMARY'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                _buildSummaryRow(langProvider.t('Company'), _selectedCompany ?? '-'),
                _buildSummaryRow(langProvider.t('Bus ID'), _busIdController.text.isEmpty ? '-' : _busIdController.text),
                _buildSummaryRow(langProvider.t('Issue'), langProvider.t(_selectedComplaintType ?? '-')),
                if (_selectedImage != null) _buildSummaryRow(langProvider.t('Attachment'), '1 Photo'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSubmitButton(LanguageProvider langProvider) {
    return Column(
      children: [
        Text(
          langProvider.t('By submitting, you agree to our Terms of Service and confirm this report is accurate.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : () => _submitComplaint(langProvider),
            icon: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send, color: Colors.white),
            label: Text(
              _isSubmitting ? langProvider.t('UPLOADING...') : langProvider.t('SUBMIT REPORT'), 
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ],
    );
  }
}