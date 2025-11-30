import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeagueLeaderboardPage extends StatefulWidget {
  const LeagueLeaderboardPage({super.key});

  @override
  State<LeagueLeaderboardPage> createState() => _LeagueLeaderboardPageState();
}

class _LeagueLeaderboardPageState extends State<LeagueLeaderboardPage> {
  String _selectedDivision = 'alpha';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w800,
      fontSize: isMobile ? 15 : 20,
    );

    final headingStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.9),
      fontWeight: FontWeight.w600,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'All 60 participating teams ranked by points',
            style: titleStyle,
          ),
          const SizedBox(height: 16),

          _DivisionToggle(
            selected: _selectedDivision,
            onChanged: (value) {
              setState(() => _selectedDivision = value);
            },
          ),
          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(flex: 2, child: Text('Ranking', style: headingStyle)),
              Expanded(
                flex: 2,
                child: Text('Team Number', style: headingStyle),
              ),
              Expanded(flex: 5, child: Text('Team Name', style: headingStyle)),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Ranking Points', style: headingStyle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('Rankings')
                    .doc(_selectedDivision)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Error loading rankings',
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final doc = snapshot.data;
              if (doc == null || doc.data() == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No rankings added yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              final data = doc.data()!;

              final List<_LeaderboardEntry> rows = [];

              data.forEach((teamKey, value) {
                if (value is Map<String, dynamic>) {
                  final previousRank =
                      (value['previousRank'] as num?)?.toInt() ?? 9999;
                  final points = (value['points'] as num?)?.toInt() ?? 0;
                  final teamNumber = teamKey.toString();

                  rows.add(
                    _LeaderboardEntry(
                      rank: previousRank,
                      teamNumber: teamNumber,
                      teamName: 'Team $teamNumber',
                      points: points,
                    ),
                  );
                }
              });

              rows.sort((a, b) => a.rank.compareTo(b.rank));

              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No rankings added yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  const SizedBox(height: 4),
                  for (int i = 0; i < rows.length; i++) ...[
                    _LeaderboardRow(
                      index: i,
                      rank: rows[i].rank,
                      teamNumber: rows[i].teamNumber,
                      teamName: rows[i].teamName,
                      points: rows[i].points,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LeaderboardEntry {
  final int rank;
  final String teamNumber;
  final String teamName;
  final int points;

  _LeaderboardEntry({
    required this.rank,
    required this.teamNumber,
    required this.teamName,
    required this.points,
  });
}

class _DivisionToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _DivisionToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: _DivisionChip(
              label: 'Alpha',
              value: 'alpha',
              selected: selected == 'alpha',
              onTap: () => onChanged('alpha'),
              isMobile: isMobile,
            ),
          ),
          Expanded(
            child: _DivisionChip(
              label: 'Bravo',
              value: 'bravo',
              selected: selected == 'bravo',
              onTap: () => onChanged('bravo'),
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }
}

class _DivisionChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final bool isMobile;

  const _DivisionChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatefulWidget {
  final int index;
  final int rank;
  final String teamNumber;
  final String teamName;
  final int points;
  final bool isMobile;

  const _LeaderboardRow({
    required this.index,
    required this.rank,
    required this.teamNumber,
    required this.teamName,
    required this.points,
    required this.isMobile,
  });

  @override
  State<_LeaderboardRow> createState() => _LeaderboardRowState();
}

class _LeaderboardRowState extends State<_LeaderboardRow> {
  bool _isHovered = false;

  double _fadeFactor(int index) {
    if (index < 5) return 1.0;

    const fadeLength = 6;
    final over = index - 2;
    if (over >= fadeLength) return 0.0;

    return 1.0 - (over / fadeLength);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const baseColor = Color.fromARGB(48, 58, 11, 41);
    const hoverColor = Color(0xFF2B2B2B);

    final fade = _fadeFactor(widget.index);

    final baseRowColor =
        fade > 0
            ? baseColor.withOpacity(0.15 + 0.35 * fade)
            : Colors.transparent;

    final showBorder = fade > 0;
    final borderOpacity = 0.3 + 0.4 * fade;
    final borderWidth = 1.0 + 1.0 * fade;

    final rowColor = _isHovered ? hoverColor : baseRowColor;

    final rankTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );

    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.92));

    final pointsStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.95),
      fontWeight: FontWeight.w700,
    );

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 0 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 8 : 12,
        vertical: widget.isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(0),
        border: Border(
          left:
              _isHovered || showBorder
                  ? BorderSide(
                    color: cs.primary.withOpacity(
                      _isHovered ? 1.0 : borderOpacity,
                    ),
                    width: _isHovered ? 3 : (3 * fade).clamp(0.0, 3.0),
                  )
                  : const BorderSide(color: Colors.transparent, width: 0),
          top:
              _isHovered || showBorder
                  ? BorderSide(
                    color: cs.primary.withOpacity(
                      _isHovered ? 0.6 : borderOpacity,
                    ),
                    width: _isHovered ? borderWidth : borderWidth,
                  )
                  : const BorderSide(color: Colors.transparent, width: 0),
          bottom:
              _isHovered || showBorder
                  ? BorderSide(
                    color: cs.primary.withOpacity(
                      _isHovered ? 0.6 : borderOpacity,
                    ),
                    width: _isHovered ? borderWidth : borderWidth,
                  )
                  : const BorderSide(color: Colors.transparent, width: 0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('#${widget.rank}', style: rankTextStyle),
          ),
          Expanded(flex: 2, child: Text(widget.teamNumber, style: bodyStyle)),
          Expanded(
            flex: 5,
            child: Text(
              widget.teamName,
              style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(widget.points.toString(), style: pointsStyle),
            ),
          ),
        ],
      ),
    );

    if (widget.isMobile) return content;

    return MouseRegion(
      opaque: true,
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: content,
    );
  }
}
