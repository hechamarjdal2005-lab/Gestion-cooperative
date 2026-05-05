import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/core/constants/colors.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _coopNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreating = false;

  Future<void> _createAccount() async {
    if (_emailController.text.isEmpty || 
        _fullNameController.text.isEmpty || 
        _coopNameController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      // Call Edge Function to create user without signing out the admin
      final response = await Supabase.instance.client.functions.invoke(
        'create-cooperative-user',
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'cooperativeName': _coopNameController.text.trim(),
        },
      );

      if (response.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Admin session maintained.'),
              backgroundColor: AppColors.success,
            ),
          );
          _emailController.clear();
          _fullNameController.clear();
          _coopNameController.clear();
          _passwordController.clear();
        }
      } else {
        throw response.data['error'] ?? 'Unknown error';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cooperative Accounts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Cooperative Admin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
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
                        onPressed: _isCreating ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isCreating 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: UserList(),
            ),
          ],
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('created_at');

    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final profiles = snapshot.data!.where((p) => p['role'] == 'admin_cooperative').toList();
        return ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(profile['full_name'] ?? 'No Name'),
              subtitle: Text(profile['email'] ?? 'No Email'),
            );
          },
        );
      },
    );
  }
}
