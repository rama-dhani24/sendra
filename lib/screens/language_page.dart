import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/providers/app_providers.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    final languages = [
      {'flag': '🇬🇧', 'name': 'English', 'sub': 'English', 'code': 'en'},
      {'flag': '🇹🇿', 'name': 'Kiswahili', 'sub': 'Swahili', 'code': 'sw'},
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
          localeProvider.isSwahili ? 'Chagua Lugha' : 'Select Language',
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
                localeProvider.isSwahili
                    ? 'Chagua lugha unayopendelea'
                    : 'Choose your preferred language',
                style: SText.caption,
              ),
              const SizedBox(height: 24),

              ...languages.map((lang) {
                final isSelected =
                    localeProvider.locale.languageCode == lang['code'];

                return GestureDetector(
                  onTap: () async {
                    await localeProvider.setLocale(Locale(lang['code']!));
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SColors.gold.withOpacity(0.10)
                          : SColors.navyCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? SColors.gold : SColors.navyLight,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          lang['flag']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang['name']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? SColors.gold
                                      : SColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(lang['sub']!, style: SText.tiny),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: SColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: SColors.navy,
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

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SColors.gold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: SColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        localeProvider.isSwahili
                            ? 'Mabadiliko ya lugha yataathiri programu nzima mara moja.'
                            : 'Language changes take effect immediately across the entire app.',
                        style: SText.tiny.copyWith(color: SColors.textSub),
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
