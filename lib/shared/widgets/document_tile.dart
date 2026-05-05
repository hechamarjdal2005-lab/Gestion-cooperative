import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/models/document.dart';
import '../../features/cooperative/screens/documents/document_detail_screen.dart';

class DocumentTile extends StatelessWidget {
  final AppDocument document;

  const DocumentTile({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DocumentDetailScreen(document: document)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(document.number, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('\${document.total.toStringAsFixed(2)} DH', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(document.clientName ?? document.supplierName ?? 'بدون اسم'),
            Text(DateFormat('yyyy/MM/dd').format(document.date)),
          ],
        ),
        leading: _buildTypeBadge(document.type),
        trailing: _buildStatusBadge(document.status),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blue.withOpacity(0.1),
      child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'validated') color = Colors.green;
    if (status == 'draft') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
