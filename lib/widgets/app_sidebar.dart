import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/core/theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();

    return Obx(() {
      final isExpanded = navController.isSidebarExpanded.value;
      final selectedIndex = navController.selectedIndex.value;
      final width = isExpanded ? 260.0 : 80.0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.sidebarBg,
          gradient: AppColors.sidebarGradient,
          border: const Border(
            right: BorderSide(color: Color(0x1AFFFFFF), width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2A000000),
              blurRadius: 20,
              offset: Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- Clinic Brand Header ---
            _buildBrandHeader(context, isExpanded, navController),

            const Divider(color: Color(0x14FFFFFF), height: 1),
            AppSpacing.vGap16,

            // --- Navigation Menu Items ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    for (int index = 0; index < navController.navItems.length; index++) ...[
                      _SidebarItemWidget(
                        key: ValueKey(navController.navItems[index].route),
                        item: navController.navItems[index],
                        isSelected: selectedIndex == index,
                        isExpanded: isExpanded,
                        onTap: () => navController.changeIndex(index),
                      ),
                      if (index < navController.navItems.length - 1)
                        AppSpacing.vGap8,
                    ],
                  ],
                ),
              ),
            ),

            // --- Footer Area ---
            const Divider(color: Color(0x14FFFFFF), height: 1),
            _buildFooter(isExpanded),
          ],
        ),
      );
    });
  }

  Widget _buildBrandHeader(
    BuildContext context,
    bool isExpanded,
    NavigationController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.borderRadiusXl,
              boxShadow: AppShadows.primaryGlow,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          if (isExpanded) ...[
            AppSpacing.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppConstants.appTagline,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnSidebarMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textOnSidebarMuted,
                size: 20,
              ),
              tooltip: 'Réduire le menu',
              onPressed: controller.toggleSidebar,
            ),
          ] else ...[
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool isExpanded) {
    if (!isExpanded) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        alignment: Alignment.center,
        child: const Icon(
          Icons.verified_user_outlined,
          color: AppColors.textOnSidebarMuted,
          size: 18,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          AppSpacing.hGap10,
          Expanded(
            child: Text(
              'v${AppConstants.appVersion} — Connecté',
              style: AppTypography.caption.copyWith(
                color: AppColors.textOnSidebarMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemWidget extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<_SidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    final iconColor = isSelected
        ? Colors.white
        : _isHovered
            ? Colors.white
            : AppColors.textOnSidebarMuted;

    final textColor = isSelected
        ? Colors.white
        : _isHovered
            ? Colors.white
            : AppColors.textOnSidebar;

    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? AppSpacing.xl : AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected
                ? null
                : _isHovered
                    ? AppColors.sidebarHover
                    : Colors.transparent,
            borderRadius: AppRadius.borderRadiusXl,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? widget.item.selectedIcon : widget.item.icon,
                color: iconColor,
                size: 22,
              ),
              if (widget.isExpanded) ...[
                AppSpacing.hGap14,
                Expanded(
                  child: Text(
                    widget.item.titleFr,
                    style: AppTypography.button.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!widget.isExpanded) {
      return Tooltip(
        message: widget.item.titleFr,
        waitDuration: const Duration(milliseconds: 300),
        child: child,
      );
    }

    return child;
  }
}
