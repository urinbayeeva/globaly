import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'seed_data/countries.dart';
import 'seed_data/cost_of_living.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const _SeederApp());
}

typedef Logger = void Function(String line);

abstract class Seeder {
  Future<void> run();
}

class CountriesSeeder implements Seeder {
  CountriesSeeder(this._db, this._log);

  final FirebaseFirestore _db;
  final Logger _log;

  @override
  Future<void> run() async {
    _log('Countries yuklanmoqda...');
    final batch = _db.batch();
    final col = _db.collection('countries');
    for (final c in countriesSeed) {
      batch.set(col.doc(c['code'] as String), c);
    }
    await batch.commit();
    _log('  ${countriesSeed.length} ta country yuklandi.');
  }
}

class CostOfLivingSeeder implements Seeder {
  CostOfLivingSeeder(this._db, this._log);

  final FirebaseFirestore _db;
  final Logger _log;

  @override
  Future<void> run() async {
    _log('Cost of living yuklanmoqda...');
    for (final MapEntry(:key, :value) in costOfLivingSeed.entries) {
      final items = (value['items'] as List).cast<Map<String, dynamic>>();
      final doc = _db.collection('costOfLiving').doc(key);
      await doc.set({
        'country': value['country'],
        'currency': value['currency'],
        'monthlyTotal': items.fold<double>(
          0,
          (acc, i) => acc + ((i['monthly'] as num?)?.toDouble() ?? 0),
        ),
      });
      final itemsRef = doc.collection('items');
      final existing = await itemsRef.get();
      await Future.wait(existing.docs.map((d) => d.reference.delete()));
      await Future.wait(items.map(itemsRef.add));
      _log('  $key: ${items.length} ta item.');
    }
  }
}

class FirestoreSeeder {
  FirestoreSeeder(FirebaseFirestore db, Logger log)
      : _seeders = [CountriesSeeder(db, log), CostOfLivingSeeder(db, log)];

  final List<Seeder> _seeders;

  Future<void> run() async {
    for (final s in _seeders) {
      await s.run();
    }
  }
}

class _SeederApp extends StatelessWidget {
  const _SeederApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: _SeederView()),
      );
}

class _SeederView extends StatefulWidget {
  const _SeederView();

  @override
  State<_SeederView> createState() => _SeederViewState();
}

class _SeederViewState extends State<_SeederView> {
  final _log = <String>[];
  bool _running = false;

  Future<void> _seed() async {
    setState(() {
      _running = true;
      _log.clear();
    });
    try {
      await FirestoreSeeder(FirebaseFirestore.instance, _append).run();
      _append('✓ Hammasi muvaffaqiyatli yuklandi.');
    } catch (e) {
      _append('✗ Xatolik: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  void _append(String line) => setState(() => _log.add(line));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Firestore Seeder',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Bir martalik ishlatish uchun.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _running ? null : _seed,
                child: Text(_running ? 'Ishlamoqda…' : 'Seed Firestore'),
              ),
              const SizedBox(height: 16),
              Expanded(child: _LogView(_log)),
            ],
          ),
        ),
      );
}

class _LogView extends StatelessWidget {
  const _LogView(this.lines);

  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        color: Colors.black87,
        child: SingleChildScrollView(
          child: Text(
            lines.join('\n'),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
        ),
      );
}
