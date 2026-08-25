import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/profile/user_profile.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../sessions/domain/models/sauna_type.dart';

/// Settings sub-section: user profile (sex, weight, age) used
/// for calorie burn calculation.
class ProfileSettingsScreen extends StatelessWidget {
  final UserProfileController userProfileController;

  const ProfileSettingsScreen({super.key, required this.userProfileController});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l['settings_profile_section']),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: userProfileController,
              builder: (context, _) {
                final profile = userProfileController.profile;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sex
                      Text(
                        l['profile_sex'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<UserSex>(
                        segments: [
                          ButtonSegment(
                            value: UserSex.male,
                            label: Text(l['profile_male']),
                            icon: const Icon(Icons.male_rounded),
                          ),
                          ButtonSegment(
                            value: UserSex.female,
                            label: Text(l['profile_female']),
                            icon: const Icon(Icons.female_rounded),
                          ),
                        ],
                        selected: {profile.sex},
                        onSelectionChanged: (selection) {
                          userProfileController.setSex(selection.first);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Preferred sauna type
                      Text(
                        l['profile_preferred_sauna_type'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<SaunaType>(
                        segments: [
                          ButtonSegment(
                            value: SaunaType.dry,
                            label: Text(l['sauna_type_dry']),
                            icon: const Icon(Icons.wb_sunny_outlined),
                          ),
                          ButtonSegment(
                            value: SaunaType.steam,
                            label: Text(l['sauna_type_steam']),
                            icon: const Icon(Icons.cloud_outlined),
                          ),
                        ],
                        selected: {profile.preferredSaunaType},
                        onSelectionChanged: (selection) {
                          userProfileController.setPreferredSaunaType(
                            selection.first,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Waga
                      Row(
                        children: [
                          Text(
                            l['profile_weight'],
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '${profile.weightKg.toStringAsFixed(0)} kg',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: profile.weightKg.clamp(30, 250),
                        min: 30,
                        max: 250,
                        divisions: 220,
                        label: '${profile.weightKg.toStringAsFixed(0)} kg',
                        onChanged: (value) =>
                            userProfileController.setWeightKg(value),
                      ),

                      // Wiek
                      Row(
                        children: [
                          Text(
                            l['profile_age'],
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '${profile.ageYears} ${l['profile_age_unit']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: profile.ageYears.toDouble().clamp(10, 120),
                        min: 10,
                        max: 120,
                        divisions: 110,
                        label: '${profile.ageYears} ${l['profile_age_unit']}',
                        onChanged: (value) =>
                            userProfileController.setAgeYears(value.round()),
                      ),
                    ],
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
