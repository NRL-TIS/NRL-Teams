import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveTrackerPage extends StatefulWidget {
  const LiveTrackerPage({super.key});

  @override
  State<LiveTrackerPage> createState() => _LiveTrackerPageState();
}

class _LiveTrackerPageState extends State<LiveTrackerPage> {
  final List<String> _tasks = const [
    'Registration',
    'Robot Inspection',
    'Visit at Robot Clinic',
    'Visit at First Aid Booth',
    'Qualification Match 1',
    'Qualification Match 2',
    'Qualification Match 3',
    'Qualification Match 4',
  ];

  late List<bool> _done;

  static const _prefsKey = 'nrl_championship_checklist_v1';

  @override
  void initState() {
    super.initState();
    _done = List<bool>.filled(_tasks.length, false);
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey);

    if (stored != null && stored.length == _tasks.length) {
      setState(() {
        _done = stored.map((s) => s == '1').toList();
      });
    }
  }

  Future<void> _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _done.map((b) => b ? '1' : '0').toList();
    await prefs.setStringList(_prefsKey, encoded);
  }

  Future<void> _toggleTask(int index) async {
    setState(() {
      _done[index] = !_done[index];
    });
    await _saveChecklist();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w800,
    );

    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.8));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Championship Checklist', style: titleStyle),
        const SizedBox(height: 4),
        Text('Important tasks for the championship', style: subtitleStyle),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.separated(
            itemCount: _tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final checked = _done[index];
              return _ChecklistTile(
                label: _tasks[index],
                checked: checked,
                onTap: () => _toggleTask(index),
                isMobile: isMobile,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;
  final bool isMobile;

  const _ChecklistTile({
    required this.label,
    required this.checked,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? cs.primary : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child:
                  checked
                      ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                          ),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: checked ? Colors.white.withOpacity(0.6) : Colors.white,
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
