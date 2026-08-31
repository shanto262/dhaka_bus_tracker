import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_provider.dart';
import 'generic_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Navigation Helper
  void _navigateTo(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenericInfoScreen(title: title)),
    );
  }

  // Clear Cache Action
  void _handleClearCache(LanguageProvider langProvider) {
    final transitProvider = Provider.of<TransitProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(langProvider.t('Clear Cache')),
          content: Text(langProvider.t('Delete locally stored offline data') + '?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                transitProvider.clearStopSelection();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(langProvider.t('Settings'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(langProvider.t('Dhaka Bus Tracker'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              side: const BorderSide(color: Colors.white54),
              avatar: const Icon(Icons.language, color: Colors.white, size: 16),
              label: Text(
                langProvider.isBangla ? 'English' : 'বাংলা',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () => langProvider.toggleLanguage(),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _buildSectionTitle(langProvider.t('PREFERENCES')),
          _buildCard([
            _buildSwitchTile(
              langProvider.t('Dark Mode'), langProvider.t('Easier on the eyes at night'), Icons.dark_mode, 
              themeProvider.isDarkMode,
              (val) => themeProvider.toggleTheme(val),
            ),
            const Divider(height: 1, indent: 56),
            _buildSwitchTile(
              langProvider.t('Background Data Sync'), langProvider.t('Keep route data fresh in background'), Icons.wifi, 
              settingsProvider.backgroundDataSync,
              (val) => settingsProvider.toggleBackgroundDataSync(val),
            ),
            const Divider(height: 1, indent: 56),
            _buildSwitchTile(
              langProvider.t('Location Access'), langProvider.t('Used to find nearby stops'), Icons.location_on, 
              settingsProvider.locationAccess,
              (val) => settingsProvider.toggleLocationAccess(val),
            ),
          ]),

          _buildSectionTitle(langProvider.t('LANGUAGE')),
          _buildCard([
            _buildNavTile(langProvider.t('App Language'), Icons.language, 
              trailingText: langProvider.t('English'),
              onTap: () => langProvider.toggleLanguage(),
            ),
          ]), 

          _buildSectionTitle(langProvider.t('SUPPORT & INFO')),
          _buildCard([
            _buildNavTile(langProvider.t('Help Center'), Icons.help_outline, subtitle: langProvider.t('FAQs and usage guides'), 
              onTap: () => _navigateTo(langProvider.t('Help Center'))),
            const Divider(height: 1, indent: 56),
            _buildNavTile(langProvider.t('Contact Us'), Icons.mail_outline, subtitle: 'support@brta.gov.bd', 
              onTap: () => _navigateTo(langProvider.t('Contact Us'))),
            const Divider(height: 1, indent: 56),
            _buildNavTile(langProvider.t('Privacy Policy'), Icons.privacy_tip_outlined, 
              onTap: () => _navigateTo(langProvider.t('Privacy Policy'))),
            const Divider(height: 1, indent: 56),
            _buildNavTile(langProvider.t('Terms of Service'), Icons.description_outlined, 
              onTap: () => _navigateTo(langProvider.t('Terms of Service'))),
          ]),

          _buildSectionTitle(langProvider.t('APP INFO')),
          _buildCard([
            _buildInfoTile(langProvider.t('Version'), '2.4.1'),
            const Divider(height: 1, indent: 16),
            _buildInfoTile(langProvider.t('Data Source'), 'BRTA Open API'),
            const Divider(height: 1, indent: 16),
            _buildInfoTile(langProvider.t('Last Sync'), langProvider.t('Just now')),
            const Divider(height: 1, indent: 16),
            _buildInfoTile(langProvider.t('Build'), '2026.07.26'),
          ]),

          const SizedBox(height: 16),
          _buildCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              title: Text(langProvider.t('Clear Cache'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: Text(langProvider.t('Delete locally stored offline data'), style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _handleClearCache(langProvider),
            ),
          ]),

          const SizedBox(height: 32),
          _buildFooter(langProvider),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  Widget _buildNavTile(String title, IconData icon, {String? subtitle, String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFooter(LanguageProvider langProvider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.directions_bus, color: Theme.of(context).colorScheme.primary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(langProvider.t('Dhaka Bus Tracker'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(langProvider.t('Built for Dhaka · BRTA Approved'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}