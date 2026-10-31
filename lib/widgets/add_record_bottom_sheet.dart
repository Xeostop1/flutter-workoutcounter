import 'package:flutter/material.dart';

class AddRecordBottomSheet extends StatefulWidget {
  const AddRecordBottomSheet({
    super.key,
    required this.onSubmit,
    this.initialTitle,
    this.initialContent,
    this.headerLabel = '직접 기록',
    this.submitLabel = '등록하기',
  });

  final Future<void> Function(String title, String content) onSubmit;
  final String? initialTitle;
  final String? initialContent;
  final String headerLabel;
  final String submitLabel;

  @override
  State<AddRecordBottomSheet> createState() => _AddRecordBottomSheetState();
}

class _AddRecordBottomSheetState extends State<AddRecordBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;

  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final height = (media.size.height - media.padding.top - keyboard - 108)
        .clamp(420.0, 680.0);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF4B4B4B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Text(
                widget.headerLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 37),
              SizedBox(
                height: 68,
                child: TextField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF272727),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _decoration(
                    hint: '운동명을 입력해주세요.',
                    color: const Color(0xFFFAFAFA),
                    radius: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 155,
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 17,
                  ),
                  decoration: _decoration(
                    hint: '상세 내용을 입력해주세요.',
                    color: const Color(0xFFD0D0D0),
                    radius: 11,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 137,
                height: 54,
                child: FilledButton(
                  onPressed: _canSubmit && !_saving ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6335),
                    disabledBackgroundColor: const Color(0xFF686868),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.submitLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required Color color,
    required double radius,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA9A9A9),
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록을 저장하지 못했습니다. 다시 시도해주세요.')),
      );
    }
  }
}
