import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Resolves a photo reference (network URL or local file path) to an
/// [ImageProvider], or null when empty.
ImageProvider? mediaImage(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return NetworkImage(url);
  return FileImage(File(url));
}

/// A white rounded card with the app's soft shadow.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.rLg),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.rLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Section title with an optional trailing action ("View All").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(actionLabel!,
                    style: GoogleFonts.lexend(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

/// Rounded icon in a pastel tinted square.
class TintedIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double box;

  const TintedIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.bg,
    this.size = 22,
    this.box = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppColors.rMd),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Pill-shaped status chip.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const StatusChip(
      {super.key, required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: GoogleFonts.lexend(
              color: color, fontWeight: FontWeight.w600, fontSize: 11.5)),
    );
  }
}

/// Segmented filter tabs (All / Active / Inactive ...).
class FilterTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  const FilterTabs(
      {super.key,
      required this.tabs,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.rMd),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(tabs[i],
                  style: GoogleFonts.lexend(
                      color: active ? Colors.white : AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}

/// Circle avatar with initials fallback.
class Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double radius;
  const Avatar({super.key, required this.name, this.url, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join();
    final img = mediaImage(url);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: img,
      child: img == null
          ? Text(initials.toUpperCase(),
              style: GoogleFonts.lexend(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: radius * 0.7))
          : null,
    );
  }
}

/// Empty-state placeholder for lists.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppColors.rXl),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: AppColors.inkSoft)),
            ],
          ],
        ),
      ),
    );
  }
}

/// FutureBuilder wrapper with consistent loading / error / empty handling.
class AsyncList<T> extends StatelessWidget {
  final Future<List<T>> future;
  final Widget Function(List<T> data) builder;
  final EmptyState empty;
  const AsyncList(
      {super.key,
      required this.future,
      required this.builder,
      required this.empty});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snap.hasError) {
          return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load',
              subtitle: '${snap.error}');
        }
        final data = snap.data ?? [];
        if (data.isEmpty) return empty;
        return builder(data);
      },
    );
  }
}

/// A tappable field that looks like a dropdown — shows the selected [value]
/// (or [hint]) and opens a picker when tapped.
class PickerField extends StatelessWidget {
  final String hint;
  final String? value;
  final String? sub;
  final IconData icon;
  final VoidCallback onTap;
  const PickerField({
    super.key,
    required this.hint,
    required this.onTap,
    this.value,
    this.sub,
    this.icon = Icons.expand_more_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppColors.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.rMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.rMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(has ? value! : hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                            color: has ? AppColors.ink : AppColors.inkFaint)),
                    if (has && sub != null && sub!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ],
                ),
              ),
              Icon(icon, color: AppColors.inkSoft, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a bottom sheet with a search bar and a filterable list. Returns the
/// selected item (or null if dismissed). Works for any type [T].
Future<T?> showSearchablePicker<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  String Function(T)? subtitle,
  String searchHint = 'Search…',
  String emptyText = 'Nothing found',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.rXl))),
    builder: (_) => _SearchPickerSheet<T>(
      title: title,
      items: items,
      label: label,
      subtitle: subtitle,
      searchHint: searchHint,
      emptyText: emptyText,
    ),
  );
}

class _SearchPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) label;
  final String Function(T)? subtitle;
  final String searchHint;
  final String emptyText;
  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.label,
    required this.subtitle,
    required this.searchHint,
    required this.emptyText,
  });

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.items
        : widget.items.where((it) {
            final l = widget.label(it).toLowerCase();
            final s = widget.subtitle?.call(it).toLowerCase() ?? '';
            return l.contains(q) || s.contains(q);
          }).toList();
    return Padding(
      padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.title,
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.44,
            child: list.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded, title: widget.emptyText)
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final it = list[i];
                      final name = widget.label(it);
                      final sub = widget.subtitle?.call(it);
                      return Material(
                        color: AppColors.scaffold,
                        borderRadius: BorderRadius.circular(AppColors.rMd),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppColors.rMd),
                          onTap: () => Navigator.pop(context, it),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Avatar(name: name, radius: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.lexend(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      if (sub != null && sub.isNotEmpty)
                                        Text(sub,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.lexend(
                                                fontSize: 12,
                                                color: AppColors.inkSoft)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.inkFaint),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Standard confirm dialog. Returns true if the user confirms.
Future<bool?> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    String confirmLabel = 'Delete',
    bool danger = true}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.rLg)),
      title: Text(title,
          style: GoogleFonts.lexend(
              fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
      content: Text(message,
          style: GoogleFonts.lexend(fontSize: 14, color: AppColors.inkSoft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style: GoogleFonts.lexend(color: AppColors.inkSoft)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: danger ? AppColors.danger : AppColors.primary,
              minimumSize: const Size(88, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Small pill button used in app bars ("Add", etc.).
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const PillButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppColors.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.rMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
