import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/utils/text_capitalization_formatter.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/services/email_service.dart';
import 'package:ott/app/core/services/legal_document_service.dart';
import 'package:ott/app/core/utils/legal_document_url_utils.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/screens/about_filmytell_screen.dart';
import 'package:ott/presentation/web_landing/screens/faq_screen.dart';
import 'package:ott/presentation/web_landing/models/web_landing_provider.dart';
import 'package:ott/presentation/web_landing/widgets/available_devices_section.dart';
import 'package:ott/presentation/web_landing/widgets/final_cta_section.dart';
import 'package:ott/presentation/web_landing/widgets/footer_section.dart';
import 'package:ott/presentation/web_landing/widgets/hero_banner.dart';
import 'package:ott/presentation/web_landing/widgets/landing_header.dart';
import 'package:ott/presentation/web_landing/widgets/latest_content_section.dart';
import 'package:ott/presentation/web_landing/widgets/production_house_section.dart';
import 'package:ott/presentation/web_landing/widgets/trending_section.dart';
import 'package:ott/presentation/web_landing/widgets/user_portal_section.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _moviesKey = GlobalKey();
  final GlobalKey _latestKey = GlobalKey();
  final GlobalKey _liveTvKey = GlobalKey();
  late final WebLandingProvider _provider;
  bool _scrolled = false;
  final Stopwatch _screenLoadWatch = Stopwatch();
  String _privacyPolicyUrl = AppConstant.privacyPolicy;
  String _termsAndConditionUrl = AppConstant.termsAndCondition;

  @override
  void initState() {
    super.initState();
    _provider = WebLandingProvider();
    _provider.loadLandingContent();
    _loadLegalDocumentUrls();
    _screenLoadWatch.start();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _logPerformance(
        'Landing first frame rendered in ${_screenLoadWatch.elapsedMilliseconds}ms',
      );
    });
  }

  Future<void> _loadLegalDocumentUrls() async {
    final documentUrls = await LegalDocumentService.instance.getDocumentUrls();
    if (!mounted) return;
    setState(() {
      _privacyPolicyUrl = documentUrls.privacyPolicyUrl;
      _termsAndConditionUrl = documentUrls.termsAndConditionsUrl;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    final next = _scrollController.hasClients && _scrollController.offset > 18;
    if (next != _scrolled) {
      setState(() => _scrolled = next);
    }
  }

  void _openLogin() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginCard()),
    );
  }

  bool _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return false;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
    return true;
  }

  void _handleNav(String label) {
    switch (label) {
      case 'Home':
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        break;
      case 'Movies':
        _showLatestContentType('MOVIE');
        break;
      case 'Series':
        _showLatestContentType('SERIES');
        break;
      case 'Mini Series':
        _showLatestContentType('MINI SERIES');
        break;
      case 'Short Film':
        _showLatestContentType('SHORT_FILM');
        break;

      default:
        _scrollTo(_homeKey);
    }
  }

  Future<void> _showLatestContentType(String type) async {
    final loadFuture = _provider.loadLatestContentByType(type);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollTo(_latestKey);
    });
    await loadFuture;
    if (!mounted) return;
    _scrollTo(_latestKey);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Consumer<WebLandingProvider>(
              builder: (context, provider, _) {
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: KeyedSubtree(
                        key: _homeKey,
                        child: HeroBanner(
                          items: provider.topTen,
                          onWatchNow: _openContent,
                          onPlayTrailer: _openTrailer,
                        ),
                      ),
                    ),
                    if (provider.isLoading)
                      const SliverToBoxAdapter(child: _LandingLoader()),
                    if (provider.errorMessage != null)
                      SliverToBoxAdapter(
                        child: _LandingError(message: provider.errorMessage!),
                      ),
                    if (provider.topTen.isNotEmpty)
                      SliverToBoxAdapter(
                        child: KeyedSubtree(
                          key: _moviesKey,
                          child: TrendingSection(
                            items: provider.topTen,
                            onContentTap: _openContent,
                          ),
                        ),
                      ),
                    if (provider.latestContent.isNotEmpty ||
                        provider.isLoadingLatest ||
                        provider.latestType != null)
                      SliverToBoxAdapter(
                        child: KeyedSubtree(
                          key: _latestKey,
                          child: provider.latestContent.isEmpty
                              ? _LatestContentStatus(
                                  isLoading: provider.isLoadingLatest,
                                )
                              : LatestContentSection(
                                  items: provider.latestContent,
                                  onContentTap: _openContent,
                                  onLoadMore: () {
                                    provider.loadMoreLatestContent();
                                  },
                                  isLoadingMore: provider.isLoadingLatest,
                                  hasMore: provider.hasMoreLatest,
                                ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: UserPortalSection(
                        onGetStarted: _openLogin,
                        onExplorePlans: _openLogin,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AvailableDevicesSection(
                        onStartWatching: _openLogin,
                        onExplorePlans: _openLogin,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProductionHouseSection(
                        key: _liveTvKey,
                        onRegister: () => _openExternal(
                          AppConstant.productionHouseUrl,
                        ),
                        onLearnMore: () => _openExternal(
                          AppConstant.productionHouseUrl,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FinalCtaSection(
                        onWatchContent: _openLogin,
                        onPublishContent: () => _openExternal(
                          AppConstant.productionHouseUrl,
                        ),
                        onEarnReferrals: () => _openExternal(
                          AppConstant.promoterPortalUrl,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FooterSection(onOpenLink: _handleFooterLink),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LandingHeader(
                scrolled: _scrolled,
                onLogin: _openLogin,
                onSignUp: _openLogin,
                onNavigate: _handleNav,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openContent(Content content) {
    _openLogin();
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!mounted) return;
    if (!opened) {
      CustomToast.show(
        context,
        AppLocalizations.of(context)!.unableOpenLink,
        isSuccess: false,
      );
    }
  }

  Future<void> _openInternalStaticPage(String path) async {
    try {
      final uri = kIsWeb
          ? Uri.base.resolve(path)
          : Uri.https('filmytell.com', path.startsWith('/') ? path : '/$path');
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
      if (!mounted || opened) return;
      CustomToast.show(
        context,
        AppLocalizations.of(context)!.unableOpenLink,
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) return;
      CustomToast.show(
        context,
        AppLocalizations.of(context)!.unableOpenLink,
        isSuccess: false,
      );
    }
  }

  Future<void> _openDocumentInNewTab(String url) async {
    final uri = legalDocumentViewUri(url);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!mounted) return;
    if (!opened) {
      CustomToast.show(
        context,
        AppLocalizations.of(context)!.unableOpenDocument,
        isSuccess: false,
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final documentUrls =
          await LegalDocumentService.instance.getDocumentUrls();
      final url = documentUrls.privacyPolicyUrl.trim().isEmpty
          ? _privacyPolicyUrl
          : documentUrls.privacyPolicyUrl;
      if (mounted) {
        setState(() => _privacyPolicyUrl = url);
      }
      await _openDocumentInNewTab(url);
    } catch (error) {
      if (!mounted) return;
      CustomToast.show(
        context,
        'Unable to open privacy policy page right now.',
        isSuccess: false,
      );
    }
  }

  Future<void> _openTerms() async {
    try {
      final documentUrls =
          await LegalDocumentService.instance.getDocumentUrls();
      final url = documentUrls.termsAndConditionsUrl.trim().isEmpty
          ? _termsAndConditionUrl
          : documentUrls.termsAndConditionsUrl;
      if (mounted) {
        setState(() => _termsAndConditionUrl = url);
      }
      await _openDocumentInNewTab(url);
    } catch (error) {
      if (!mounted) return;
      CustomToast.show(
        context,
        'Unable to open terms and condition right now.',
        isSuccess: false,
      );
    }
  }

  void _showContactDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => const _ContactUsDialog(),
    );
  }

  void _handleFooterLink(String label) {
    switch (label) {
      case 'Home':
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        return;
      case 'Movies':
        _showLatestContentType('MOVIE');
        return;
      case 'Series':
        _showLatestContentType('SERIES');
        return;
      case 'User Portal':
        _openLogin();
        return;
      case 'Mini Series':
        _showLatestContentType('MINI SERIES');
        return;
      case 'Short Film':
        _showLatestContentType('SHORT_FILM');
        return;
      case 'Production House':
        _openExternal(
          AppConstant.productionHouseUrl,
        );
        return;
      case 'Promoter':
        _openExternal(
          AppConstant.promoterPortalUrl,
        );
        return;
      case 'OTT Admin':
        _openExternal(
          '',
        );
        return;
      case 'Privacy Policy':
        _openInternalStaticPage('/privacy-policy.html');
        return;
      case 'Terms & Conditions':
        _openInternalStaticPage('/terms-of-service.html');
        return;
      case 'Account Deletion':
        _openExternal(AppConstant.accountDeletionUrl);
        return;
      case 'Facebook':
        _openExternal(AppConstant.facebookUrl);
        return;
      case 'Instagram':
        _openExternal(AppConstant.instagramUrl);
        return;
      case 'X (Twitter)':
        _openExternal(AppConstant.xUrl);
        return;
      case 'About Us':
        _openInternalStaticPage('/about-us.html');
        return;
      case 'Contact Us':
        _openInternalStaticPage('/contact.html');
        return;
      case 'FAQ':
        _openInternalStaticPage('/help-center.html');
        return;
      case 'Cookies':
        _openInternalStaticPage('/cookies.html');
        return;
    }

    final slug = switch (label) {
      'Refund Policy' => 'refund-policy',
      'Facebook' => 'facebook',
      _ => label.toLowerCase().replaceAll(' ', '-'),
    };
    _openExternal('https://filmytell.com/$slug/');
  }

  Future<void> _openTrailer(Content content) async {
    var playableContent = content;
    var trailerUrl = playableContent.teaserOrTrailerUrl?.trim() ?? '';

    if (trailerUrl.isEmpty) {
      if (!mounted) return;
      final provider = context.read<WebLandingProvider>();
      playableContent = await provider.loadContentWithTrailer(content);
      trailerUrl = playableContent.teaserOrTrailerUrl?.trim() ?? '';
    }

    if (!mounted) return;
    if (trailerUrl.isEmpty) {
      CustomToast.show(
        context,
        AppLocalizations.of(context)!.trailerNotAvailable,
        isSuccess: false,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailerPage(
          trailerUrl: trailerUrl,
          isTrailerUrl: true,
          content: playableContent,
        ),
      ),
    );
  }

  void _logPerformance(String message) {
    if (!kDebugMode) return;
    developer.log(message, name: 'WebLandingPerformance');
  }
}

class _ContactUsDialog extends StatefulWidget {
  const _ContactUsDialog();

  @override
  State<_ContactUsDialog> createState() => _ContactUsDialogState();
}

class _ContactUsDialogState extends State<_ContactUsDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final EmailService _emailService = EmailService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendContactMessage() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);

    final name = _nameController.text.trim();
    final phoneNumber = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    final submittedAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.now(),
    );
    final body = '''A new contact request has been received.

Name: $name
Email: $email
Phone Number: $phoneNumber
Subject: $subject
Message: $message

Submitted At: $submittedAt''';

    try {
      final sent = await _emailService.sendEmail(
        subject: 'New Contact Us Message',
        message: body,
      );

      if (!mounted) return;
      if (!sent) {
        CustomToast.show(
          context,
          'Failed to send email. Please try again.',
          isSuccess: false,
        );
        return;
      }

      _nameController.clear();
      _mobileController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
      _formKey.currentState?.reset();
      CustomToast.show(
        context,
        'Email sent successfully.',
        isSuccess: true,
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
  }) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.055),
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.64),
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.34),
        fontWeight: FontWeight.w600,
      ),
      errorStyle: const TextStyle(fontWeight: FontWeight.w700),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  String? _validateMobile(String? value) {
    final mobile = (value ?? '').trim();
    if (mobile.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(mobile)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF101010),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Contact Filmytell',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _sending ? null : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Send us your message and our support team will get back to you.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.64),
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [CapitalizeWordsTextInputFormatter()],
                    enabled: !_sending,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _fieldDecoration(
                      label: 'Name',
                      hint: 'Enter your name',
                    ),
                    validator: (value) =>
                        _validateRequired(value, 'Please enter your name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _mobileController,
                    enabled: !_sending,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _fieldDecoration(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                    ),
                    validator: _validateMobile,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_sending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _fieldDecoration(
                      label: 'Email',
                      hint: 'Enter your email',
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [CapitalizeWordsTextInputFormatter()],
                    enabled: !_sending,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _fieldDecoration(
                      label: 'Subject',
                      hint: 'Enter subject',
                    ),
                    validator: (value) =>
                        _validateRequired(value, 'Please enter subject'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      CapitalizeSentencesTextInputFormatter(),
                    ],
                    enabled: !_sending,
                    minLines: 4,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _fieldDecoration(
                      label: 'Message',
                      hint: 'How can we help?',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Please enter your message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _sendContactMessage,
                      icon: _sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_sending ? 'Sending...' : 'Send Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestContentStatus extends StatelessWidget {
  const _LatestContentStatus({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 600 ? 20.0 : 56.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.latestContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Center(
              child: isLoading
                  ? CircularProgressIndicator(color: theme.primaryColor)
                  : Text(
                      'No content found',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingLoader extends StatelessWidget {
  const _LandingLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class _LandingError extends StatelessWidget {
  const _LandingError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 600 ? 20.0 : 56.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        34,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
