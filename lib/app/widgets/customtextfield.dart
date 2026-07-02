import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:wc_form_validators/wc_form_validators.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType textInputType;
  final int maxLine;
  final bool isPhoneNumber;
  final bool isValidator;
  final bool isEmail;
  final bool isName;
  final bool isDigits;
  final TextCapitalization capitalization;
  final IconData? iconData;
  final bool isPassword;
  final bool? readOnly;
  final String? validatorMsg;
  final String? label;
  final Function? onTap;
  final Function(String)? onValueChange;
  final IconData? suffixIcon;
  final Widget? prefixIcon;
  final Color? backgroundColor;
  final String? Function(String?)? validator;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.textInputType,
    this.maxLine = 1,
    this.validatorMsg,
    this.isPhoneNumber = false,
    this.isValidator = true,
    this.isEmail = false,
    this.isName = false,
    this.isDigits = false,
    this.capitalization = TextCapitalization.none,
    this.iconData,
    this.isPassword = false,
    this.readOnly,
    this.onTap,
    this.label,
    this.onValueChange,
    this.suffixIcon,
    this.prefixIcon,
    this.backgroundColor,
    this.validator,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    super.key,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'custom-text-field');
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;

    _focusNode.removeListener(_handleFocusChanged);
    if (oldWidget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'custom-text-field');
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_isTvInput || !_focusNode.hasFocus) return;
    _showTextInputKeyboard();
  }

  bool get _isTvInput => !kIsWeb && ResponsiveWidget.isTv(context);

  void _showTextInputKeyboard() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    var selectedTheme =
        Provider.of<ThemeProvider>(context, listen: false).getTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Text(
              widget.label!,
              style: TextStyle(
                color: selectedTheme.canvasColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 5),
          Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.gameButtonA):
                  ActivateIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    if (_isTvInput) {
                      _showTextInputKeyboard();
                    }
                    return null;
                  },
                ),
              },
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                obscureText: widget.isPassword ? _isObscure : false,
                keyboardType: widget.textInputType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.capitalization,
                readOnly: widget.readOnly ?? false,
                onTap: () {
                  if (_isTvInput) {
                    _showTextInputKeyboard();
                  }
                  widget.onTap?.call();
                },
                onFieldSubmitted: widget.onFieldSubmitted,
                maxLines: widget.maxLine,
                cursorColor: const Color(0xFFE50914),
                inputFormatters: _buildInputFormatters(),
                validator: _buildValidator(),
                style:
                    TextStyle(color: selectedTheme.canvasColor, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.backgroundColor ?? selectedTheme.cardColor,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: selectedTheme.canvasColor,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: selectedTheme.primaryColor,
                      width: _isTvInput ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: selectedTheme.canvasColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        )
                      : (widget.suffixIcon != null
                          ? Icon(
                              widget.suffixIcon,
                              color: selectedTheme.canvasColor,
                            )
                          : null),
                  prefixIcon: widget.prefixIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? Function(String?)? _buildValidator() {
    if (widget.validator != null) return widget.validator;
    if (!widget.isValidator) return null;
    if (widget.isPhoneNumber) {
      return Validators.compose([
        Validators.required('Phone number is required'),
        Validators.minLength(10, 'Mobile number cannot be less than 10 digits'),
        Validators.maxLength(
            10, 'Mobile number cannot be greater than 10 digits'),
      ]);
    } else if (widget.isEmail) {
      return Validators.compose([
        Validators.required('Email is required'),
        Validators.email('Invalid email address'),
      ]);
    } else if (widget.isName) {
      return Validators.compose([
        Validators.patternString(r"^[A-Za-z]+$", 'Only alphabets are allowed'),
        Validators.required('${widget.hintText} is required'),
      ]);
    } else if (widget.isDigits) {
      return Validators.compose([
        Validators.patternRegExp(
            RegExp(r"^[0-9]*$"), 'Only digits are allowed'),
        Validators.required('${widget.hintText} is required'),
      ]);
    } else {
      return Validators.required('This field is required');
    }
  }

  List<TextInputFormatter> _buildInputFormatters() {
    if (widget.isPhoneNumber || widget.isDigits) {
      return [FilteringTextInputFormatter.digitsOnly];
    }

    return [
      if (widget.maxLine == 1) FilteringTextInputFormatter.singleLineFormatter,
      if (widget.capitalization == TextCapitalization.words)
        CapitalizeWordsTextInputFormatter(),
    ];
  }
}

class CapitalizeWordsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    var shouldCapitalize = true;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (RegExp(r'\s').hasMatch(char)) {
        shouldCapitalize = true;
        buffer.write(char);
        continue;
      }

      if (shouldCapitalize) {
        buffer.write(char.toUpperCase());
        shouldCapitalize = false;
      } else {
        buffer.write(char);
      }
    }

    final formatted = buffer.toString();
    if (formatted == text) return newValue;

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, formatted.length),
      ),
      composing: TextRange.empty,
    );
  }
}
