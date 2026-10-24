import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pinned screen header: brand on the left, actions on the right, and a centred title
/// that starts large below the bar and settles into the bar as the page scrolls.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        title: title,
        leading: leading,
        trailing: trailing,
        topPadding: MediaQuery.paddingOf(context).top,
        titleHeight: MediaQuery.textScalerOf(context).scale(AppText.largeTitle.fontSize!) + 22,
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.title,
    required this.leading,
    required this.trailing,
    required this.topPadding,
    required this.titleHeight,
  });

  static const double barHeight = 52;

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final double topPadding;
  final double titleHeight;

  @override
  double get minExtent => topPadding + barHeight;

  @override
  double get maxExtent => topPadding + barHeight + titleHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 0 = expanded (big title visible), 1 = collapsed (title in the bar).
    final t = (shrinkOffset / titleHeight).clamp(0.0, 1.0);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24 * t, sigmaY: 24 * t),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.background, AppColors.background.withValues(alpha: 0.8), t),
            border: Border(
              bottom: BorderSide(color: AppColors.border.withValues(alpha: t), width: 0.5),
            ),
          ),
          child: Stack(
            children: [
              // Bar: leading · centred small title · trailing.
              Positioned(
                top: topPadding,
                left: 0,
                right: 0,
                height: barHeight,
                child: CustomMultiChildLayout(
                  delegate: _BarLayout(),
                  children: [
                    LayoutId(
                      id: _BarSlot.title,
                      child: Opacity(
                        opacity: Curves.easeIn.transform(t),
                        child: Semantics(
                          header: t > 0.5,
                          child: Text(title, maxLines: 1, style: AppText.headline.copyWith(fontSize: 14)),
                        ),
                      ),
                    ),
                    if (leading != null) LayoutId(id: _BarSlot.leading, child: leading!),
                    if (trailing != null) LayoutId(id: _BarSlot.trailing, child: trailing!),
                  ],
                ),
              ),
              // Large centred title, fading and lifting as it scrolls away.
              Positioned(
                top: topPadding + barHeight - shrinkOffset * 0.6,
                left: AppSpace.gutter,
                right: AppSpace.gutter,
                height: titleHeight,
                child: Opacity(
                  opacity: 1 - Curves.easeOut.transform(t),
                  child: Semantics(
                    header: t <= 0.5,
                    child: Center(
                      child: Text(title, style: AppText.largeTitle, maxLines: 1, textAlign: TextAlign.center),
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

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.title != title ||
      old.leading != leading ||
      old.trailing != trailing ||
      old.topPadding != topPadding ||
      old.titleHeight != titleHeight;
}

enum _BarSlot { leading, title, trailing }

/// Leading at the gutter, trailing at the right, title centred on the bar. On a narrow bar where the
/// centred title would run into either side, the title is hidden (the large title already names the screen).
class _BarLayout extends MultiChildLayoutDelegate {
  static const double _gap = AppSpace.sm;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    var left = 0.0;
    var right = size.width;
    if (hasChild(_BarSlot.leading)) {
      final s = layoutChild(_BarSlot.leading, loose);
      positionChild(_BarSlot.leading, Offset(AppSpace.gutter, (size.height - s.height) / 2));
      left = AppSpace.gutter + s.width;
    }
    if (hasChild(_BarSlot.trailing)) {
      final s = layoutChild(_BarSlot.trailing, loose);
      positionChild(_BarSlot.trailing, Offset(size.width - AppSpace.sm - s.width, (size.height - s.height) / 2));
      right = size.width - AppSpace.sm - s.width;
    }
    final title = layoutChild(_BarSlot.title, BoxConstraints(maxWidth: size.width, maxHeight: size.height));
    final x = (size.width - title.width) / 2;
    final fits = x >= left + _gap && x + title.width <= right - _gap;
    positionChild(_BarSlot.title, fits ? Offset(x, (size.height - title.height) / 2) : Offset(-size.width * 2, 0));
  }

  @override
  bool shouldRelayout(_BarLayout oldDelegate) => false;
}
