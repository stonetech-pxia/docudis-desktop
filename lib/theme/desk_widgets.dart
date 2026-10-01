import 'package:flutter/material.dart';

import 'clay_theme.dart';

// Desktop chrome in the Clay colours: tool bar, notice line, editor pane.

/// One toolbar action.
class DeskTool {
  const DeskTool({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String shortcut;
  final VoidCallback? onPressed;
  final bool primary;
}

/// The cream bar of tool buttons along the top: [leading] on the left,
/// [trailing] on the right. Where the labels do not fit, the buttons keep
/// only their icons and the tooltip names them.
class DeskToolbar extends StatelessWidget {
  const DeskToolbar({
    super.key,
    required this.leading,
    this.trailing = const [],
  });

  final List<DeskTool> leading;
  final List<DeskTool> trailing;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Clay.surface,
      border: Border(bottom: BorderSide(color: Clay.divider)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: LayoutBuilder(
        builder: (context, box) {
          final compact = _labelledWidth(context) > box.maxWidth;
          List<Widget> buttons(List<DeskTool> tools) => [
            for (final (i, tool) in tools.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              _DeskToolButton(tool: tool, compact: compact),
            ],
          ];
          return Row(
            children: [
              ...buttons(leading),
              const Spacer(),
              ...buttons(trailing),
            ],
          );
        },
      ),
    ),
  );
}

/// Label text style of [_DeskToolButton].
final _toolLabel = Clay.body(12.5, weight: FontWeight.w700);

extension on DeskToolbar {
  /// How wide the bar is with every label shown: icon, gap and padding
  /// (about 47 px per button), the labels as laid out, the gaps between,
  /// and some room for the spacer.
  double _labelledWidth(BuildContext context) {
    final tools = [...leading, ...trailing];
    var width = 47.0 * tools.length + 6.0 * (tools.length - 2) + 24;
    for (final tool in tools) {
      final painter = TextPainter(
        text: TextSpan(text: tool.label, style: _toolLabel),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      width += painter.width;
      painter.dispose();
    }
    return width;
  }
}

/// A small outlined (or, for the main action, terracotta) button with an
/// icon and, unless [compact], a label; the tooltip names its shortcut.
class _DeskToolButton extends StatelessWidget {
  const _DeskToolButton({required this.tool, required this.compact});

  final DeskTool tool;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = tool.primary;
    final style = (primary ? FilledButton.styleFrom : OutlinedButton.styleFrom)(
      minimumSize: const Size(28, 28),
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: _toolLabel,
      side: primary ? null : const BorderSide(color: Clay.divider),
      backgroundColor: primary ? null : Clay.surface,
      foregroundColor: primary ? null : Clay.ink,
    );
    final icon = Icon(tool.icon, size: 15);
    final Widget button = compact
        ? (primary
              ? FilledButton(
                  onPressed: tool.onPressed,
                  style: style,
                  child: icon,
                )
              : OutlinedButton(
                  onPressed: tool.onPressed,
                  style: style,
                  child: icon,
                ))
        : (primary
              ? FilledButton.icon(
                  onPressed: tool.onPressed,
                  style: style,
                  icon: icon,
                  label: Text(tool.label),
                )
              : OutlinedButton.icon(
                  onPressed: tool.onPressed,
                  style: style,
                  icon: icon,
                  label: Text(tool.label),
                ));
    return Tooltip(
      message: compact ? '${tool.label}  ${tool.shortcut}' : tool.shortcut,
      waitDuration: const Duration(milliseconds: 500),
      child: button,
    );
  }
}

/// A warning line across the workspace, under the toolbar.
class DeskNoteBar extends StatelessWidget {
  const DeskNoteBar({super.key, required this.text, this.actions = const []});

  final String text;

  /// Buttons at the end of the line, such as "Show anyway".
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    color: Clay.warningBg,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 15,
          color: Clay.warningText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Clay.body(12.5, color: Clay.warningText)),
        ),
        ...actions,
      ],
    ),
  );
}

/// A bordered cream pane with a small caption row, as in a desktop editor.
class DocumentPane extends StatelessWidget {
  const DocumentPane({
    super.key,
    required this.caption,
    required this.child,
    this.trailing,
  });

  final String caption;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Clay.surface,
      border: Border.all(color: Clay.divider),
      borderRadius: BorderRadius.circular(Clay.controlRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              Text(
                caption,
                style: Clay.body(
                  12,
                  weight: FontWeight.w700,
                  color: Clay.inkCaption,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    ),
  );
}
