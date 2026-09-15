import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class InAppLicensesPage extends StatefulWidget {
  const InAppLicensesPage({super.key});

  @override
  State<InAppLicensesPage> createState() => _InAppLicensesPageState();
}

class _InAppLicensesPageState extends State<InAppLicensesPage> {
  final List<LicenseEntry> _licenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    try {
      await for (final entry in LicenseRegistry.licenses) {
        _licenses.add(entry);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTv = ResponsiveWidget.isTv(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        leading: OttTvFocus(
          autofocus: isTv,
          onTap: () => Navigator.of(context).maybePop(),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          'Open Source Licenses',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTv ? 22 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF28C28)),
            )
          : SafeArea(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: isTv ? 48.0 : 20.0,
                  vertical: 24.0,
                ),
                itemCount: _licenses.isEmpty ? 1 : _licenses.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 28),
                itemBuilder: (context, index) {
                  if (_licenses.isEmpty) {
                    return const Text(
                      'Filmytell utilizes open-source software libraries licensed under BSD, MIT, and Apache 2.0 terms.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    );
                  }

                  final license = _licenses[index];
                  final packages = license.packages.join(', ');
                  final paragraphs = license.paragraphs.map((p) => p.text).join('\n\n');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packages,
                        style: TextStyle(
                          color: const Color(0xFFF28C28),
                          fontSize: isTv ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paragraphs,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: isTv ? 13 : 12,
                          height: 1.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
