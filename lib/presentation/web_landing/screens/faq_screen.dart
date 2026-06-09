import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = [
    _FaqItem(
      question: 'What is Filmytell?',
      answer:
          'Filmytell is an OTT platform where viewers can watch movies, series, short films, and entertainment content across supported devices.',
    ),
    _FaqItem(
      question: 'Do I need to create an account to watch content?',
      answer:
          'Yes. You need to create an account or log in before watching paid or protected content on Filmytell.',
    ),
    _FaqItem(
      question: 'Is Filmytell subscription based?',
      answer:
          'No. Filmytell works on a pay-per-movie model, so you can choose and pay only for the content you want to watch.',
    ),
    _FaqItem(
      question: 'How do I watch a movie on Filmytell?',
      answer:
          'Log in to your account, select the movie or series you want to watch, complete the required payment if applicable, and start streaming.',
    ),
    _FaqItem(
      question: 'Can I gift a movie to someone?',
      answer:
          'Yes. Filmytell supports movie gifting, so you can share selected content access with another viewer.',
    ),
    _FaqItem(
      question: 'Can I download content for offline viewing?',
      answer:
          'Yes. Supported content can be downloaded inside the app for offline viewing, depending on content availability and access rules.',
    ),
    _FaqItem(
      question: 'Which devices does Filmytell support?',
      answer:
          'Filmytell supports Android mobile, Android tablet, Android TV, Google TV, Smart TV, and web browser experiences.',
    ),
    _FaqItem(
      question: 'How can a production house publish content?',
      answer:
          'Production houses can register on the Filmytell Production House portal, complete verification, upload content, and submit it for approval.',
    ),
    _FaqItem(
      question: 'How can I become a Filmytell promoter?',
      answer:
          'You can register through the Promoter portal, share referral links, track performance, and earn through eligible promotions.',
    ),
    _FaqItem(
      question: 'How do I contact Filmytell support?',
      answer:
          'For help with account, payment, access, or content issues, contact Filmytell support at support@filmytell.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const red = Color(0xFFD80D18);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            height: 56,
            color: red,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FAQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 44, 56, 38),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FILMYTELL SUPPORT',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 13,
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Find quick answers about watching content, pay-per-movie access, gifting, downloads, devices, and Filmytell partner portals.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 17,
                              height: 1.55,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(56, 0, 56, 80),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: Column(
                          children: [
                            for (var index = 0; index < _items.length; index++)
                              _FaqTile(
                                item: _items[index],
                                initiallyExpanded: index == 0,
                              ),
                          ],
                        ),
                      ),
                    ),
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.initiallyExpanded,
  });

  final _FaqItem item;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.white.withOpacity(0.04),
          highlightColor: Colors.white.withOpacity(0.03),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          iconColor: theme.primaryColor,
          collapsedIconColor: Colors.white.withOpacity(0.70),
          title: Text(
            item.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.answer,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 14,
                  height: 1.65,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}
