import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'auth/firebase_auth_service.dart';
import 'models/emergency_contact.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        setState(() {
          _emergencyContacts = profile?.emergencyContacts ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading emergency contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEmergencyContacts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use set with merge to create document if it doesn't exist
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'emergencyContacts': _emergencyContacts.map((contact) => contact.toMap()).toList(),
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency contacts saved!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving emergency contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save emergency contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => _AddEmergencyContactDialog(
        onAdd: (contact) {
          setState(() {
            _emergencyContacts.add(contact);
          });
          _saveEmergencyContacts();
        },
      ),
    );
  }

  void _editEmergencyContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => _AddEmergencyContactDialog(
        contact: contact,
        onAdd: (updatedContact) {
          setState(() {
            final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
            if (index != -1) {
              _emergencyContacts[index] = updatedContact;
            }
          });
          _saveEmergencyContacts();
        },
      ),
    );
  }

  void _deleteEmergencyContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _emergencyContacts.removeWhere((c) => c.id == contact.id);
              });
              _saveEmergencyContacts();
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPhoneNumbers() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts to copy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneNumbers = _emergencyContacts
        .where((contact) => contact.phoneNumber.isNotEmpty)
        .map((contact) => '${contact.name}: ${contact.phoneNumber}')
        .join('\n');

    if (phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone numbers available to copy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get current location for emergency message
    String locationInfo = '';
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15), // Wait up to 15 seconds for best GPS signal
      );
      final locationUrl = 'https://www.google.com/maps?q=${position.latitude.toStringAsFixed(7)},${position.longitude.toStringAsFixed(7)}';
      locationInfo = '\n\nMy location: $locationUrl';
    } catch (e) {
      print('Could not get location: $e');
      locationInfo = '\n\n(Location unavailable)';
    }

    // Create a more comprehensive copy text
    final copyText = 'EMERGENCY CONTACTS\n$phoneNumbers\n\nEMERGENCY MESSAGE:\nEMERGENCY: I need help immediately! Please respond as soon as possible.$locationInfo\n\nCopy these phone numbers and paste them into your messaging app to send the emergency message.';

    await Clipboard.setData(ClipboardData(text: copyText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contacts and message copied to clipboard!\nPaste into your messaging app to send.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _sendGroupMessage() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts to message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create a group message with all emergency contacts
    final phoneNumbers = _emergencyContacts
        .where((contact) => contact.phoneNumber.isNotEmpty)
        .map((contact) => contact.phoneNumber)
        .toList();

    if (phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone numbers available for emergency contacts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Emergency Message'),
        content: Text(
          'This will send an emergency message to ${_emergencyContacts.where((contact) => contact.phoneNumber.isNotEmpty).length} contact(s). '
          'The message will open in your default messaging app where you can review and send it.\n\n'
          'Message: "EMERGENCY: I need help immediately! Please respond as soon as possible."'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get phone numbers for SMS
    final phoneNumbersList = _emergencyContacts
        .where((contact) => contact.phoneNumber.isNotEmpty)
        .map((contact) => contact.phoneNumber)
        .toList();
    
    if (phoneNumbersList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone numbers available for SMS'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Try to launch SMS with a simpler approach
    try {
      // Get current location for emergency message
      String locationInfo = '';
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 15), // Wait up to 15 seconds for best GPS signal
        );
        final locationUrl = 'https://www.google.com/maps?q=${position.latitude.toStringAsFixed(7)},${position.longitude.toStringAsFixed(7)}';
        locationInfo = '\n\nMy location: $locationUrl';
      } catch (e) {
        print('Could not get location: $e');
        locationInfo = '\n\n(Location unavailable)';
      }
      
      // Use a more basic SMS URI that should work on most Android devices
      final message = 'EMERGENCY: I need help immediately! Please respond as soon as possible.$locationInfo';
      final smsUri = Uri.parse('sms:${phoneNumbersList.join(',')}?body=${Uri.encodeComponent(message)}');
      
      // Try to launch without checking canLaunchUrl first (sometimes this works when canLaunchUrl fails)
      try {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message app opened. Please review and send the message.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      } catch (e) {
        print('Direct SMS launch failed: $e');
      }
      
      // Fallback: Try with tel: for single contact
      if (phoneNumbersList.length == 1) {
        try {
          final telUri = Uri.parse('tel:${phoneNumbersList.first}');
          await launchUrl(telUri, mode: LaunchMode.externalApplication);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone dialer opened. Switch to messages to send SMS.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        } catch (e) {
          print('Tel fallback failed: $e');
        }
      }
      
      // If all methods fail, show copy instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open messaging app automatically.\n'
              'Please use the copy button to get phone numbers: ${phoneNumbersList.join(', ')}\n'
              'Then paste them into your messaging app.'
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open messaging app: $e\nPlease use the copy button instead.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _copyPhoneNumbers,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Phone Numbers',
          ),
          IconButton(
            onPressed: _sendGroupMessage,
            icon: const Icon(Icons.message),
            tooltip: 'Send Group Message',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with add button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Manage your emergency contacts who will be notified in case of emergency.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addEmergencyContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Emergency contacts list
                Expanded(
                  child: _emergencyContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.contacts,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No emergency contacts added',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add contacts to notify them in emergencies',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _emergencyContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _emergencyContacts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red[100],
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.red[600],
                                  ),
                                ),
                                title: Text(contact.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(contact.phoneNumber),
                                    if (contact.relationship != null)
                                      Text(
                                        contact.relationship!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _editEmergencyContact(contact),
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteEmergencyContact(contact),
                                      icon: const Icon(Icons.delete),
                                      tooltip: 'Delete',
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                onTap: () => _editEmergencyContact(contact),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AddEmergencyContactDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final Function(EmergencyContact) onAdd;

  const _AddEmergencyContactDialog({
    this.contact,
    required this.onAdd,
  });

  @override
  State<_AddEmergencyContactDialog> createState() => _AddEmergencyContactDialogState();
}

class _AddEmergencyContactDialogState extends State<_AddEmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _emailController.text = widget.contact!.email ?? '';
      _relationshipController.text = widget.contact!.relationship ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final contact = EmergencyContact(
        id: widget.contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        relationship: _relationshipController.text.trim().isEmpty ? null : _relationshipController.text.trim(),
      );
      
      widget.onAdd(contact);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Emergency Contact' : 'Edit Emergency Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter full name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (Optional)',
                  hintText: 'e.g., Family, Friend, Doctor',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: Text(widget.contact == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
