import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/core/constants/colors.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final _emailController = TextEditingController();
  final _coopNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendInvitation() async {
    if (_emailController.text.isEmpty || 
        _coopNameController.text.isEmpty || 
        _fullNameController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      // Call edge function to create user
      final response = await Supabase.instance.client.functions.invoke(
        'create-cooperative-user',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'cooperativeName': _coopNameController.text.trim(),
        },
      );

      if (response.status != 200) {
        throw response.data['error'] ?? 'Unknown error';
      }

      // Also record invitation for tracking
      await Supabase.instance.client.from('invitations').insert({
        'email': _emailController.text.trim(),
        'cooperative_name': _coopNameController.text.trim(),
        'status': 'accepted', // Since we created the user directly
      });

      if (mounted) {
        _emailController.clear();
        _coopNameController.clear();
        _fullNameController.clear();
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cooperative user created successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Cooperative Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _coopNameController,
                      decoration: const InputDecoration(labelText: 'Cooperative Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Admin Full Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Admin Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Initial Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendInvitation,
                        child: _isSending 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: InvitationList(),
            ),
          ],
        ),
      ),
    );
  }
}

class InvitationList extends StatelessWidget {
  const InvitationList({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client.from('invitations').stream(primaryKey: ['id']).order('created_at');

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final invitations = snapshot.data!;
        return ListView.builder(
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invite = invitations[index];
            return ListTile(
              title: Text(invite['cooperative_name']),
              subtitle: Text(invite['email']),
              trailing: Chip(
                label: Text(invite['status']),
                backgroundColor: invite['status'] == 'pending' ? Colors.orange : Colors.green,
              ),
            );
          },
        );
      },
    );
  }
}
