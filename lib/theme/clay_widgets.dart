import 'package:flutter/material.dart';

import 'clay_theme.dart';

/// Page scaffold for the desktop: a cream header bar with an optional back
/// button, the title on the left and actions on the right, then the body,
/// and an optional pinned bottom bar.
class ClayPage extends StatelessWidget {
  const ClayPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Clay.surface,
              border: Border(bottom: BorderSide(color: Clay.divider)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(showBack ? 4 : 16, 4, 8, 4),
              child: SizedBox(
                height: 34,
                child: Row(
                  children: [
                    if (showBack)
                      ClayIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Clay.heading(14, weight: FontWeight.w600),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottom == null ? null : ClayBottomBar(child: bottom),
    );
  }
}

/// 44px square icon button.
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = Clay.ink,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: color),
      constraints: const BoxConstraints.tightFor(
        width: Clay.tapTarget,
        height: Clay.tapTarget,
      ),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}

/// Cream bar with a hairline on top, pinned under the body.
class ClayBottomBar extends StatelessWidget {
  const ClayBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Clay.surface,
      border: Border(top: BorderSide(color: Clay.divider)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: child,
      ),
    ),
  );
}

/// Cream card, radius 22, soft warm shadow.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = Clay.surface,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final BoxBorder? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Clay.radius);
    return ClayPressScale(
      enabled: onTap != null,
      // Only the colour is tweened: a Container would also pad for the
      // border and shift the content.
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: Clay.motion,
        curve: Clay.motionCurve,
        builder: (_, tweened, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: tweened ?? color,
            borderRadius: radius,
            border: border,
            boxShadow: shadow ? Clay.shadow : null,
          ),
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Shrinks its child slightly while a finger is down and springs back on
/// release: the tactile feedback for cards and chips.
class ClayPressScale extends StatefulWidget {
  const ClayPressScale({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<ClayPressScale> createState() => _ClayPressScaleState();
}

class _ClayPressScaleState extends State<ClayPressScale> {
  bool _down = false;

  void _set(bool down) {
    if (down && !widget.enabled) return;
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// 46px coloured icon tile with the Clay asymmetric corner.
class ClayIconTile extends StatelessWidget {
  const ClayIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.foreground = Colors.white,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Clay.motion,
    curve: Clay.motionCurve,
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, borderRadius: Clay.iconTileRadius),
    child: Icon(icon, size: size * 0.48, color: foreground),
  );
}

/// Sage pill: "On this phone only".
class ClayPill extends StatelessWidget {
  const ClayPill({
    super.key,
    required this.label,
    this.icon,
    this.background = Clay.secondaryTint,
    this.foreground = Clay.secondaryText,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: Clay.body(12, weight: FontWeight.w700, color: foreground),
        ),
      ],
    ),
  );
}

/// Filter chip with a coloured dot and a count.
class ClayCountChip extends StatelessWidget {
  const ClayCountChip({
    super.key,
    required this.label,
    required this.count,
    required this.dot,
  });

  final String label;
  final int count;
  final Color dot;

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
    decoration: BoxDecoration(
      color: Clay.surface,
      border: Border.all(color: Clay.divider),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Clay.body(13, weight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: Clay.body(13, weight: FontWeight.w500, color: Clay.inkCaption),
        ),
      ],
    ),
  );
}

/// Two-way segmented control (Anonymized / Original).
class ClaySegmented extends StatelessWidget {
  const ClaySegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Clay.divider,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index ? Clay.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: i == index
                      ? const [
                          BoxShadow(
                            color: Color(0x14785A3C),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: Clay.heading(
                    14,
                    weight: FontWeight.w600,
                    color: i == index ? Clay.ink : Clay.inkCaption,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Uppercase tracked caption.
class ClayLabel extends StatelessWidget {
  const ClayLabel(this.text, {super.key, this.color = Clay.inkCaption});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Clay.label(color: color),
  );
}

/// Card that frames a document: caption row on top, body text below.
class ClayDocumentCard extends StatelessWidget {
  const ClayDocumentCard({
    super.key,
    required this.caption,
    required this.child,
    this.trailing,
  });

  final String caption;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ClayCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: ClayLabel(caption)),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// Sage success banner with a round check.
class ClaySuccessBanner extends StatelessWidget {
  const ClaySuccessBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Clay.secondaryTint,
      borderRadius: BorderRadius.circular(Clay.controlRadius),
    ),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Clay.secondary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Clay.body(
              14,
              weight: FontWeight.w500,
              color: Clay.secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Ochre warning note.
class ClayWarningNote extends StatelessWidget {
  const ClayWarningNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Clay.warningBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: Clay.warningText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Clay.body(12.5, color: Clay.warningText, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Small caption row with a lock icon, under primary actions.
class ClayLockNote extends StatelessWidget {
  const ClayLockNote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.lock_outline_rounded, size: 14, color: Clay.inkCaption),
      const SizedBox(width: 6),
      Flexible(child: child),
    ],
  );
}

/// Blocking "working…" dialog. Close with `Navigator.pop` on the root
/// navigator once the work is done.
Future<void> showClayProgressDialog(BuildContext context, String message) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: const Color(0x66_2A2420),
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Clay.body(
                    15,
                    weight: FontWeight.w500,
                    color: Clay.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

/// Bottom bar of the signed-in shell: icon + label per tab, active in
/// terracotta.
class ClayNavBar extends StatelessWidget {
  const ClayNavBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Clay.surface,
      border: Border(top: BorderSide(color: Clay.divider)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                icon: items[i].$1,
                label: items[i].$2,
                selected: i == index,
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Clay.primary : Clay.inkPlaceholder;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Clay.controlRadius),
        child: SizedBox(
          width: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: Clay.body(11, weight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop counterpart of [ClayNavBar]: a cream column on the left with the
/// app name on top, one compact row per section (the active one on a
/// terracotta tint), and an optional [footer] under them, such as recent
/// documents. [compact] narrows it to a rail of icons, for small windows.
class ClaySideNav extends StatelessWidget {
  const ClaySideNav({
    super.key,
    required this.title,
    required this.index,
    required this.onChanged,
    required this.items,
    this.footer,
    this.compact = false,
  });

  static const width = 200.0;
  static const compactWidth = 52.0;

  final bool compact;

  final String title;
  final int index;
  final ValueChanged<int> onChanged;
  final List<(IconData, String)> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Clay.surface,
      border: Border(right: BorderSide(color: Clay.divider)),
    ),
    child: SizedBox(
      width: compact ? compactWidth : width,
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 14, compact ? 6 : 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 0 : 10,
                0,
                compact ? 0 : 10,
                14,
              ),
              child: Text(
                compact ? title.characters.first : title,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: Clay.heading(15),
              ),
            ),
            for (var i = 0; i < items.length; i++)
              ClaySideNavRow(
                icon: items[i].$1,
                label: items[i].$2,
                selected: i == index,
                iconOnly: compact,
                onTap: () => onChanged(i),
              ),
            if (footer case final footer? when !compact)
              Expanded(child: footer),
          ],
        ),
      ),
    ),
  );
}

/// One side bar row: icon and label, terracotta on a tint when selected,
/// a light wash under the pointer.
class ClaySideNavRow extends StatelessWidget {
  const ClaySideNavRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.iconOnly = false,
  });

  /// Only the icon, the label as a tooltip: the compact rail.
  final bool iconOnly;

  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Clay.primary : Clay.inkMuted;
    final icon = this.icon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? Clay.primaryTint : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            hoverColor: Clay.bg,
            child: SizedBox(
              height: iconOnly ? 36 : 30,
              child: iconOnly && icon != null
                  ? Tooltip(
                      message: label,
                      child: Center(child: Icon(icon, size: 18, color: color)),
                    )
                  : Row(
                      children: [
                        const SizedBox(width: 10),
                        if (icon != null) ...[
                          Icon(icon, size: 17, color: color),
                          const SizedBox(width: 9),
                        ],
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Clay.body(
                              13,
                              weight: icon == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: color,
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

/// Grows / shrinks its child into place with a fade. Keeps the last child
/// while collapsing so what disappears is what was there, not a blank.
class ClayReveal extends StatefulWidget {
  const ClayReveal({super.key, required this.visible, this.child});

  final bool visible;
  final Widget? child;

  @override
  State<ClayReveal> createState() => _ClayRevealState();
}

class _ClayRevealState extends State<ClayReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Clay.motion,
    value: widget.visible ? 1 : 0,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Clay.motionCurve,
  );
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
  }

  @override
  void didUpdateWidget(ClayReveal old) {
    super.didUpdateWidget(old);
    if (widget.child != null) _child = widget.child;
    if (widget.visible != old.visible) {
      widget.visible ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !widget.visible,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => ClipRect(
        // Clip tightly while animating; at rest leave room for the shadow.
        clipper: _RevealClipper(margin: _controller.value == 1 ? 48 : 0),
        child: child,
      ),
      child: SizeTransition(
        sizeFactor: _curve,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _curve,
          child: SizedBox(
            width: double.infinity,
            child: _child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper({required this.margin});

  final double margin;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -margin,
    -margin,
    size.width + margin,
    size.height + margin,
  );

  @override
  bool shouldReclip(_RevealClipper old) => old.margin != margin;
}
