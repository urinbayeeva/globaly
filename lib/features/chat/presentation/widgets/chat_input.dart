import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

typedef ChatSubmit = void Function(String text, {String? imagePath});

class ChatInput extends StatefulWidget {
  const ChatInput({super.key, required this.onSubmit, this.canSend = true});
  final ChatSubmit onSubmit;

  final bool canSend;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _c = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  bool _hasText = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final bool next = _c.text.trim().isNotEmpty;
      if (next != _hasText) setState(() => _hasText = next);
    });
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _imagePath = file.path);
    } catch (_) {}
  }

  void _clearImage() => setState(() => _imagePath = null);

  void _send() {
    final String t = _c.text.trim();
    final bool canSend = (t.isNotEmpty || _imagePath != null) && widget.canSend;
    if (!canSend) return;
    widget.onSubmit(t, imagePath: _imagePath);
    _c.clear();
    setState(() => _imagePath = null);
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = (_hasText || _imagePath != null) && widget.canSend;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_imagePath != null)
            _AttachmentPreview(
              path: _imagePath!,
              onRemove: _clearImage,
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _focus.hasFocus ? AppColors.brand : AppColors.gray200,
                width: _focus.hasFocus ? 1.4 : 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x140D1424),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _AttachButton(onTap: _pickImage),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _c,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: AppTypography.bodyL.copyWith(
                      color: AppColors.ink,
                      height: 22 / 15,
                    ),
                    cursorColor: AppColors.brand,
                    decoration: InputDecoration(
                      hintText: T.of(context, 'chat.ask'),
                      hintStyle: AppTypography.bodyL.copyWith(
                        color: AppColors.gray500,
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(enabled: canSend, onTap: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.path, required this.onRemove});
  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            PhosphorIconsRegular.image,
            color: AppColors.brand,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = enabled ? AppColors.brand : AppColors.gray200;
    final Color fg = enabled ? Colors.white : AppColors.gray500;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_upward_rounded,
            color: fg,
            size: 20,
          ),
        ),
      ),
    );
  }
}
