import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HTML फाइल से निकाली गई Firebase Keys
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-nWyD4RtphSv7WazRgM7o3Eaj2NwgPek",
      appId: "1:872712106347:web:48fc0bfcd7b9e182d89c2e",
      messagingSenderId: "872712106347",
      projectId: "chupakabra-khata",
      storageBucket: "chupakabra-khata.firebasestorage.app",
    ),
  );

  runApp(const ChupakabraKhataApp());
}

class ChupakabraKhataApp extends StatelessWidget {
  const ChupakabraKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'चुपाकाबरा खाता',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF075C43),
        scaffoldBackgroundColor: const Color(0xFFF4FBF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075C43),
          primary: const Color(0xFF075C43),
        ),
        useMaterial3: true,
      ),
      home: const GaddiHomeScreen(),
    );
  }
}

class GaddiHomeScreen extends StatefulWidget {
  const GaddiHomeScreen({super.key});

  @override
  State<GaddiHomeScreen> createState() => _GaddiHomeScreenState();
}

class _GaddiHomeScreenState extends State<GaddiHomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075C43),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('चुपाकाबरा खाता', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('प्रीमियम डिजिटल गद्दी', style: TextStyle(fontSize: 11, color: Color(0xFFA7F3D0))),
          ],
        ),
      ),
      body: _tabIndex == 0 ? const CustomerLedgerView() : const ExpenseLedgerView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'ग्राहक खाता'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'दुकान खर्च'),
        ],
      ),
    );
  }
}

// ---------------- 1. ग्राहक खाता सूची एवं लेजर ----------------
class CustomerLedgerView extends StatelessWidget {
  const CustomerLedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        double totalLena = 0;
        double totalDena = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final bal = (data['balance'] ?? 0.0).toDouble();
          if (bal > 0) totalLena += bal;
          if (bal < 0) totalDena += bal.abs();
        }

        return Column(
          children: [
            // गद्दी बैलेंस स्ट्रिप
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8EADE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('लेना है (बाज़ार में)', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('₹${totalLena.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 35, color: const Color(0xFFD8EADE)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('देना है (जमा / आवक)', style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('₹${totalDena.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ग्राहकों की लिस्ट
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('कोई खाता नहीं है। नीचे दिए बटन से जोड़ें।'))
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final id = docs[i].id;
                        final name = data['name'] ?? '';
                        final phone = data['phone'] ?? '';
                        final bal = (data['balance'] ?? 0.0).toDouble();
                        final isLena = bal >= 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: Colors.white,
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFD8EADE)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEAF5EF),
                              foregroundColor: const Color(0xFF075C43),
                              child: Text(name.isNotEmpty ? name[0] : '?'),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('📞 $phone'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${bal.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isLena ? Colors.red : const Color(0xFF059669),
                                  ),
                                ),
                                Text(
                                  isLena ? 'लेना है' : 'देना है',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(id: id, name: name, phone: phone, balance: bal),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- 2. खाता डिटेल और लेन-देन स्क्रीन ----------------
class CustomerDetailScreen extends StatelessWidget {
  final String id;
  final String name;
  final String phone;
  final double balance;

  const CustomerDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
  });

  void _sendWhatsApp(double bal) async {
    final msg = "नमस्ते $name जी 🙏\nचुपाकाबरा खाता पर आपका ₹${bal.abs().toStringAsFixed(2)} का हिसाब बाकी है।\nकृपया समय पर चुकता करें।";
    final url = Uri.parse("https://wa.me/91$phone?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _addTransaction(BuildContext context, String type) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type == 'give' ? '＋ माल दिया (उधार)' : '✓ माल लिया (जमा)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: type == 'give' ? Colors.red : const Color(0xFF059669))),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'रकम ₹', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'विवरण / माल का नाम', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'give' ? Colors.red : const Color(0xFF059669),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                final docRef = FirebaseFirestore.instance.collection('customers').doc(id);
                final txRef = docRef.collection('transactions').doc();

                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final snap = await transaction.get(docRef);
                  final curBal = (snap.data()?['balance'] ?? 0.0).toDouble();
                  final newBal = type == 'give' ? (curBal + amt) : (curBal - amt);

                  transaction.set(txRef, {
                    'amount': amt,
                    'type': type,
                    'note': noteCtrl.text.trim().isEmpty ? (type == 'give' ? 'माल दिया' : 'माल लिया') : noteCtrl.text.trim(),
                    'date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  transaction.update(docRef, {'balance': newBal});
                });

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('सुरक्षित करें ✓'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF075C43),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📞 $phone', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${balance.abs().toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: balance >= 0 ? Colors.red : const Color(0xFF059669)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendWhatsApp(balance),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAF5EF), foregroundColor: const Color(0xFF075C43)),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('customers').doc(id).collection('transactions').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final txs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (ctx, i) {
                    final t = txs[i].data() as Map<String, dynamic>;
                    final isGive = t['type'] == 'give';
                    return ListTile(
                      title: Text(t['note'] ?? ''),
                      subtitle: Text(t['date'] ?? ''),
                      trailing: Text(
                        '${isGive ? '+' : '-'} ₹${t['amount']}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isGive ? Colors.red : const Color(0xFF059669)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _addTransaction(context, 'give'),
                    child: const Text('माल दिया (उधार)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _addTransaction(context, 'get'),
                    child: const Text('माल लिया (जमा)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 3. गद्दी रोज़नामचा (दुकान खर्च) ----------------
class ExpenseLedgerView extends StatelessWidget {
  const ExpenseLedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('expenses').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final e = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(e['note'] ?? 'खर्च'),
              subtitle: Text('${e['category']} • ${e['date']}'),
              trailing: Text('₹${e['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            );
          },
        );
      },
    );
  }
}
