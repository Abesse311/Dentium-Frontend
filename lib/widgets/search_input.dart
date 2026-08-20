import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme.dart';

class SearchInput extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final Duration debounceDuration;

  const SearchInput({
    super.key,
    this.hintText = 'Rechercher...',
    required this.onChanged,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: AppDecorations.panel,
      child: TextField(
        controller: _controller,
        onChanged: _onTextChanged,
        style: AppTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTypography.formHint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: _clear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}






