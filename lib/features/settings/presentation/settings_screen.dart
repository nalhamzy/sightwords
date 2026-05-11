import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/tokens.dart';
import '../../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version} (${info.buildNumber})');
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _restoring = true);
    try {
      await ref.read(iapServiceProvider).restorePurchases();
      await ref.read(entitlementsProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not restore purchases.')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://idealai.app/sightwords/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(voiceSpeedProvider);
    final speechEnabled = ref.watch(quizSpeechProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Voice'),
          _card(
            children: [
              const ListTile(
                title: Text('Voice Speed'),
                contentPadding: EdgeInsets.zero,
              ),
              Row(
                children: [
                  const Text('Slow', style: TextStyle(color: kInkSoft)),
                  Expanded(
                    child: Slider(
                      value: speed,
                      min: 0.1,
                      max: 1.0,
                      divisions: 18,
                      activeColor: kPrimary,
                      onChanged: (v) =>
                          ref.read(voiceSpeedProvider.notifier).setSpeed(v),
                    ),
                  ),
                  const Text('Fast', style: TextStyle(color: kInkSoft)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _speedLabel(speed),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: kPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          _card(
            children: [
              ListTile(
                title: const Text('Language'),
                subtitle: const Text('English (US)'),
                trailing: const Icon(Icons.lock_outline, color: kInkSoft),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionHeader('Quiz'),
          _card(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use microphone in quiz'),
                subtitle: const Text('Let your child say words aloud'),
                value: speechEnabled,
                activeThumbColor: kPrimary,
                onChanged: (v) =>
                    ref.read(quizSpeechProvider.notifier).setValue(v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionHeader('Account'),
          _card(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Restore Purchases'),
                trailing: _restoring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore, color: kPrimary),
                onTap: _restoring ? null : _restorePurchases,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionHeader('About'),
          _card(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Version'),
                trailing: Text(
                  _version.isEmpty ? '...' : _version,
                  style: const TextStyle(color: kInkSoft),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new, color: kInkSoft),
                onTap: _openPrivacyPolicy,
              ),
              const Divider(height: 1),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Local-first. No account. No ads.'),
                subtitle: Text('All data stays on your device.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _speedLabel(double speed) {
    if (speed <= 0.38) return 'Slow';
    if (speed <= 0.56) return 'Normal';
    return 'Fast';
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kInkSoft,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Card(
      color: kCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
