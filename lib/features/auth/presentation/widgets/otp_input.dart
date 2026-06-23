import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.autofocus = true,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final int length;
  final bool enabled;
  final bool autofocus;

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange() {
    final String text = _controller.text;
    setState(() {});
    widget.onChanged(text);
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  void clear() => _controller.clear();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.oneTimeCode],
              maxLength: widget.length,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.enabled) _focus.requestFocus();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(widget.length, _cell),
          ),
        ),
      ],
    );
  }

  Widget _cell(int i) {
    final String text = _controller.text;
    final bool filled = i < text.length;
    final bool active = _focus.hasFocus && i == text.length;

    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.brand100 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.brand
              : (filled ? AppColors.brand200 : AppColors.gray300),
          width: active ? 2 : 1,
        ),
      ),
      child: Text(
        filled ? text[i] : '',
        style: AppTypography.h2.copyWith(color: AppColors.ink),
      ),
    );
  }
}
