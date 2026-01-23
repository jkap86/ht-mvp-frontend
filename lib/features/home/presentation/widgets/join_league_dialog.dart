import 'package:flutter/material.dart';

class JoinLeagueDialog extends StatefulWidget {
  final Future<void> Function(String inviteCode) onJoinLeague;

  const JoinLeagueDialog({super.key, required this.onJoinLeague});

  @override
  State<JoinLeagueDialog> createState() => _JoinLeagueDialogState();
}

class _JoinLeagueDialogState extends State<JoinLeagueDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join League'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Invite Code',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an invite code';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              await widget.onJoinLeague(_codeController.text);
            }
          },
          child: const Text('Join'),
        ),
      ],
    );
  }
}

void showJoinLeagueDialog(
  BuildContext context, {
  required Future<void> Function(String inviteCode) onJoinLeague,
}) {
  showDialog(
    context: context,
    builder: (context) => JoinLeagueDialog(onJoinLeague: onJoinLeague),
  );
}
