import 'package:flutter/material.dart';

class CheckoutNoteDialog extends StatefulWidget {
  final bool isDeviceBeingCheckedOut;
  final String orgId;
  final bool isAdminOrDeskstation;
  final ValueChanged<String> onSubmit; // Callback with the entered note

  const CheckoutNoteDialog({
    super.key,
    required this.isDeviceBeingCheckedOut,
    required this.orgId,
    required this.isAdminOrDeskstation,
    required this.onSubmit,
  });

  @override
  _CheckoutNoteDialogState createState() => _CheckoutNoteDialogState();
}

class _CheckoutNoteDialogState extends State<CheckoutNoteDialog> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Please Leave a Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please describe why you are checking out this device',
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Leave a Note',
              prefixIcon: Icon(Icons.note),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        ElevatedButton.icon(
          onPressed: () {
            // Get the note from the text field
            final note = _noteController.text;
            Navigator.of(context).pop(); // Close the dialog
            widget.onSubmit(note); // Pass the note back to the caller
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Check Out Device'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Just close the dialog
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
        ),
      ],
    );
  }
}