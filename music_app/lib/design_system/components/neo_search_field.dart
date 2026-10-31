import 'package:flutter/material.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_icons.dart';
import 'package:muzee/theme/neo/neo_layout.dart';

/// Search input. Fill, radius, focus ring and hint color all come from the
/// theme's input decoration; this widget only adds the search affordances.
class NeoSearchField extends StatefulWidget {
  const NeoSearchField({
    required this.controller,
    required this.hintText,
    required this.clearLabel,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.isLoading = false,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  /// Tooltip / screen-reader label for the clear button.
  final String clearLabel;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isLoading;
  final bool autofocus;

  @override
  State<NeoSearchField> createState() => _NeoSearchFieldState();
}

class _NeoSearchFieldState extends State<NeoSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(NeoSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final c = NeoColors.of(context);
    final layout = NeoLayout.of(context);

    Widget? suffix;
    if (widget.isLoading) {
      suffix = Padding(
        padding: EdgeInsets.all(layout.space12),
        child: SizedBox.square(
          dimension: layout.iconMedium,
          child: CircularProgressIndicator(
            strokeWidth: layout.focusWidth,
            color: c.accent,
          ),
        ),
      );
    } else if (widget.controller.text.isNotEmpty) {
      suffix = IconButton(
        tooltip: widget.clearLabel,
        onPressed: _clear,
        icon: Icon(NeoIcons.clear, size: layout.iconMedium),
      );
    }

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(NeoIcons.search, size: layout.iconMedium),
        suffixIcon: suffix,
      ),
    );
  }
}
