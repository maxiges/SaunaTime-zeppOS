import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/profile/user_profile.dart';
import '../../../core/profile/user_profile_controller.dart';
import '../../sessions/domain/models/sauna_type.dart';

/// Settings sub-section: user profile (sex, weight, age) used
/// for calorie burn calculation and app preferences.
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
      body: AnimatedBuilder(
        animation: userProfileController,
        builder: (context, _) {
          final profile = userProfileController.profile;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // --- SECTION 1: PERSONAL DATA ---
              _buildHeader(context, l['profile_personal_header'], Icons.person_rounded),
              const SizedBox(height: 12),
              _SettingsGroup(
                children: [
                  // Sex
                  _buildLabel(context, l['profile_sex']),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<UserSex>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: UserSex.male,
                          label: Text(l['profile_male']),
                          icon: const Icon(Icons.male_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: UserSex.female,
                          label: Text(l['profile_female']),
                          icon: const Icon(Icons.female_rounded, size: 18),
                        ),
                      ],
                      selected: {profile.sex},
                      onSelectionChanged: (selection) => userProfileController.setSex(selection.first),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weight
                  _buildStatHeader(context, l['profile_weight'], '${profile.weightKg.toStringAsFixed(0)} kg'),
                  Slider(
                    value: profile.weightKg.clamp(30, 250),
                    min: 30,
                    max: 250,
                    divisions: 220,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) => userProfileController.setWeightKg(value),
                  ),
                  const SizedBox(height: 12),

                  // Age
                  _buildStatHeader(context, l['profile_age'], '${profile.ageYears} ${l['profile_age_unit']}'),
                  Slider(
                    value: profile.ageYears.toDouble().clamp(10, 120),
                    min: 10,
                    max: 120,
                    divisions: 110,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) => userProfileController.setAgeYears(value.round()),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- SECTION 2: APP PREFERENCES ---
              _buildHeader(context, l['profile_app_header'], Icons.settings_suggest_rounded),
              const SizedBox(height: 12),
              _SettingsGroup(
                children: [
                  // Preferred sauna type
                  _buildLabel(context, l['profile_preferred_sauna_type']),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<SaunaType>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: SaunaType.dry,
                          label: Text(l['sauna_type_dry']),
                          icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: SaunaType.steam,
                          label: Text(l['sauna_type_steam']),
                          icon: const Icon(Icons.cloud_outlined, size: 18),
                        ),
                      ],
                      selected: {profile.preferredSaunaType},
                      onSelectionChanged: (selection) => userProfileController.setPreferredSaunaType(selection.first),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Activity Display Mode
                  _buildLabel(context, l['profile_activity_display']),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ActivityDisplayMode.values.map((mode) {
                          final isSelected = profile.activityDisplayMode == mode;
                          IconData icon;
                          String labelKey;
                          
                          switch (mode) {
                            case ActivityDisplayMode.none:
                              icon = Icons.remove_circle_outline_rounded;
                              labelKey = 'activity_mode_none';
                              break;
                            case ActivityDisplayMode.totalOnly: 
                              icon = Icons.stacked_bar_chart_rounded; 
                              labelKey = 'activity_mode_total';
                              break;
                            case ActivityDisplayMode.sideBySide: 
                              icon = Icons.align_horizontal_left_rounded; 
                              labelKey = 'activity_mode_side_by_side';
                              break;
                            case ActivityDisplayMode.stacked: 
                              icon = Icons.view_agenda_rounded; 
                              labelKey = 'activity_mode_stacked';
                              break;
                            case ActivityDisplayMode.intensity: 
                              icon = Icons.grid_view_rounded; 
                              labelKey = 'activity_mode_intensity';
                              break;
                            case ActivityDisplayMode.rings: 
                              icon = Icons.donut_large_rounded; 
                              labelKey = 'activity_mode_rings';
                              break;
                            case ActivityDisplayMode.line: 
                              icon = Icons.show_chart_rounded; 
                              labelKey = 'activity_mode_line';
                              break;
                          }

                          return ChoiceChip(
                            label: Text(l[labelKey], style: const TextStyle(fontSize: 12)),
                            avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : theme.colorScheme.primary),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) userProfileController.setActivityDisplayMode(mode);
                            },
                          );
                        }).toList(),
                      );
                    }
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatHeader(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
