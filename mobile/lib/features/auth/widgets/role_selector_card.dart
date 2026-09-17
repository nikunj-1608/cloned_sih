import 'package:flutter/material.dart';
import '../../../core/models/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// An accessible role selection item showcasing role icon, localized title,
/// and clear selection state for bright sunlight environments.
class RoleSelectorCard extends StatelessWidget {
  const RoleSelectorCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onSelect,
    this.localizedTitle,
    this.localizedDesc,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onSelect;

  /// Localized title to display. Falls back to [role.title.en] when null.
  final String? localizedTitle;

  /// Localized description. Falls back to [role.description.en] when null.
  final String? localizedDesc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = localizedTitle ?? role.title.en;
    final desc = localizedDesc ?? role.description.en;

    final borderColor = isSelected
        ? AppColors.horizon
        : (isDark ? AppColors.hairlineDark : AppColors.hairline);

    final bgColor = isSelected
        ? AppColors.deepSea.withValues(alpha: isDark ? 0.25 : 0.08)
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return Semantics(
      selected: isSelected,
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.deepSea
                        : (isDark
                            ? AppColors.hairlineDark
                            : AppColors.background),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role.icon,
                    size: 24,
                    color: isSelected ? Colors.white : AppColors.deepSea,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected ? AppColors.deepSea : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.deepSea
                          : (isDark
                              ? AppColors.inkMutedDark
                              : AppColors.hairline),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
