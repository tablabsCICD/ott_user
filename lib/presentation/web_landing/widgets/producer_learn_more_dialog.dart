import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ProducerLearnMoreDialog extends StatelessWidget {
  const ProducerLearnMoreDialog({super.key});

  static const List<String> _features = [
    'Set and revise own rental price.',
    'Retain complete ownership of the content.',
    'Decide duration, how much time your content should be there on the platform.*',
    'Monitor performance through a transparent dashboard.',
    'Receive weekly payment settlements.',
    'Earn 70 to 60% of rental revenue, excluding applicable taxes.*',
    'Build an audience progressively instead of depending entirely on a conventional theatrical window.',
    'Share and Gift option makes it easy for marketing.',
    'User friendly interface of the platform.',
    'Wallet system simplifies purchase mechanism.',
    'Available on all alternate options like Android, iOS, Web and Google TV, Amazon fire tv, Jio app store.',
    'Filmytell enables content to travel beyond geographical and traditional distribution barriers.',
  ];

  Future<void> _openRegistration() async {
    final uri = Uri.parse(AppConstant.productionHouseUrl);
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.80),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 18 : 24,
                  isMobile ? 18 : 20,
                  isMobile ? 14 : 18,
                  isMobile ? 14 : 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: FilmytellTheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: FilmytellTheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.video_library_rounded,
                            color: FilmytellTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PRODUCER / CREATOR',
                            style: FilmytellTheme.font(
                              color: FilmytellTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Dialog Body
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 18 : 24,
                    16,
                    isMobile ? 18 : 24,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FILMYTELL is Producer / Creater friendly platform where,',
                              style: FilmytellTheme.font(
                                color: Colors.white,
                                fontSize: isMobile ? 15 : 17,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Movies, Web Series , Mini Series and Shortfilms Released and monitized.',
                              style: FilmytellTheme.font(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Features Title
                      Text(
                        'Features of Filmytell :',
                        style: FilmytellTheme.font(
                          color: Colors.white,
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Features List
                      for (int i = 0; i < _features.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6, right: 10),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: FilmytellTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _features[i],
                                  style: FilmytellTheme.font(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: isMobile ? 13.5 : 14.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),
                      // Conditions applied note
                      Text(
                        '*conditions applied',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dialog Footer
              Container(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 18 : 24,
                  14,
                  isMobile ? 18 : 24,
                  isMobile ? 18 : 20,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openRegistration();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FilmytellTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Register Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
