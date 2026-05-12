import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/providers/app_providers.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isSw = localeProvider.isSwahili;
    final effectiveDark = themeProvider.effectiveIsDark(context);

    final options = [
      {
        'icon': Icons.brightness_auto_rounded,
        'title': isSw ? 'Mwongozo wa Mfumo' : 'System Default',
        'sub': isSw
            ? 'Fuata mwongozo wa kifaa chako (${effectiveDark ? "Giza" : "Mwanga"} sasa hivi)'
            : 'Follow your device setting (${effectiveDark ? "Dark" : "Light"} now)',
        'mode': ThemeMode.system,
        'color': SColors.textSub,
      },
      {
        'icon': Icons.dark_mode_rounded,
        'title': isSw ? 'Hali ya Giza' : 'Dark Mode',
        'sub': isSw
            ? 'Mandhari nyeusi - rahisi kwa macho usiku'
            : 'Easy on the eyes at night',
        'mode': ThemeMode.dark,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.light_mode_rounded,
        'title': isSw ? 'Hali ya Mwanga' : 'Light Mode',
        'sub': isSw
            ? 'Mandhari nyeupe - wazi na safi'
            : 'Clean and bright appearance',
        'mode': ThemeMode.light,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Scaffold(
      backgroundColor: SColors.bg,
      appBar: AppBar(
        backgroundColor: SColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: SColors.textSub,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSw ? 'Mandhari' : 'Appearance',
          style: const TextStyle(
            color: SColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSw
                    ? 'Chagua mandhari unayopendelea'
                    : 'Choose your preferred appearance',
                style: SText.caption,
              ),
              const SizedBox(height: 24),

              ...options.map((opt) {
                final isSelected = themeProvider.mode == opt['mode'];
                final color = opt['color'] as Color;

                return GestureDetector(
                  onTap: () => themeProvider.setMode(opt['mode'] as ThemeMode),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.10)
                          : SColors.navyCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : SColors.navyLight,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            opt['icon'] as IconData,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['title'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : SColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(opt['sub'] as String, style: SText.tiny),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: SColors.navyLight,
                                width: 1.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Preview card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SColors.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SColors.navyLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      effectiveDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: SColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSw
                            ? 'Sasa hivi: ${effectiveDark ? "Hali ya Giza" : "Hali ya Mwanga"}'
                            : 'Currently showing: ${effectiveDark ? "Dark Mode" : "Light Mode"}',
                        style: const TextStyle(
                          color: SColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
