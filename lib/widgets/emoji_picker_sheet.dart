import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../app.dart';

Future<String?> showEmojiPickerSheet(
  BuildContext context, {
  required List<String> palette,
  String title = 'Pick an icon',
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final size = MediaQuery.of(ctx).size;
      return SafeArea(
        child: SizedBox(
          height: size.height * 0.78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (palette.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: palette.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final e = palette[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(ctx, e),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 20),
              ],
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (cat, emoji) =>
                      Navigator.pop(ctx, emoji.emoji),
                  config: Config(
                    height: size.height * 0.78,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: cs.surface,
                      columns: 8,
                      emojiSizeMax: 28,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: cs.surface,
                      iconColor: cs.onSurface.withValues(alpha: 0.4),
                      iconColorSelected: cs.primary,
                      indicatorColor: cs.primary,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: cs.surface,
                      buttonColor: cs.primary,
                      buttonIconColor: cs.onPrimary,
                      showBackspaceButton: false,
                      showSearchViewButton: true,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: cs.surface,
                      buttonIconColor: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class EmojiPlaceholderBox extends StatelessWidget {
  final String value;
  final Color tint;
  final double size;

  const EmojiPlaceholderBox({
    super.key,
    required this.value,
    required this.tint,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final empty = value.isEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: empty
            ? cs.surfaceContainerHighest
            : tint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: empty
            ? Border.all(color: cs.outline.withValues(alpha: 0.6), width: 1.2)
            : null,
      ),
      alignment: Alignment.center,
      child: empty
          ? Icon(
              Icons.add_reaction_outlined,
              size: size * 0.55,
              color: cs.onSurface.withValues(alpha: 0.45),
            )
          : Text(value, style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

class InlineEmojiPalette extends StatelessWidget {
  final List<String> palette;
  final String selected;
  final Color tint;
  final ValueChanged<String> onPicked;
  final double tileSize;

  const InlineEmojiPalette({
    super.key,
    required this.palette,
    required this.selected,
    required this.tint,
    required this.onPicked,
    this.tileSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<String>(
      valueListenable: handednessNotifier,
      builder: (_, hand, _) {
        final reverse = hand != 'left';
        return SizedBox(
          height: tileSize + 6,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: reverse,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            itemCount: palette.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final e = palette[i];
              final sel = e == selected;
              return GestureDetector(
                onTap: () => onPicked(e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: sel
                        ? tint.withValues(alpha: 0.22)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? tint : cs.outline.withValues(alpha: 0.25),
                      width: sel ? 1.8 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class EmojiPickerButton extends StatelessWidget {
  final String value;
  final Color tint;
  final List<String> palette;
  final ValueChanged<String> onPicked;
  final double size;

  const EmojiPickerButton({
    super.key,
    required this.value,
    required this.tint,
    required this.palette,
    required this.onPicked,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final empty = value.isEmpty;
    return GestureDetector(
      onTap: () async {
        final picked = await showEmojiPickerSheet(context, palette: palette);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: empty
              ? cs.surfaceContainerHighest
              : tint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: empty
              ? Border.all(color: cs.outline.withValues(alpha: 0.6), width: 1.2)
              : null,
        ),
        alignment: Alignment.center,
        child: empty
            ? Icon(
                Icons.add_reaction_outlined,
                size: size * 0.55,
                color: cs.onSurface.withValues(alpha: 0.45),
              )
            : Text(value, style: TextStyle(fontSize: size * 0.55)),
      ),
    );
  }
}
