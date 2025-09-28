import 'package:flutter/material.dart';

class GlassBottomNavBar extends StatefulWidget {
  final int selectedIndex;

  const GlassBottomNavBar({required this.selectedIndex});

  @override
  State<GlassBottomNavBar> createState() => _GlassBottomNavBarState();
}

class _GlassBottomNavBarState extends State<GlassBottomNavBar> {
  int _hoverIndex = -1;

  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.desktop_mac_rounded,
    Icons.shopping_bag,
    Icons.support_agent,
    Icons.people,
  ];

  final List<String> _labels = [
    'Dashboard',
    'Management',
    'Orders',
    'Support',
    'Replacements',
  ];

  final List<String> _routes = [
    '/Admin',
    '/ManageProduct',
    '/CustomerOrder',
    '/SupportReq',
    '/ReplacementRequest',
  ];

  void _onHoverChange(int index, bool isHovered) {
    setState(() {
      _hoverIndex = isHovered ? index : -1;
    });
  }

  Widget glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: glassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              final bool isSelected = widget.selectedIndex == index;
              final bool isHovered = _hoverIndex == index;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => _onHoverChange(index, true),
                onExit: (_) => _onHoverChange(index, false),
                child: GestureDetector(
                  onTap: () {
                    if (widget.selectedIndex != index) {
                      Navigator.pushReplacementNamed(
                          context, _routes[index]);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 2, horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected || isHovered
                          ? const Color(0xFF539b69).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icons[index],
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF539b69)
                              : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF539b69)
                                : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
