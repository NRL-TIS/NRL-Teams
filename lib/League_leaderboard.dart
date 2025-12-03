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
      fontSize: isMobile ? 10 : 12, // smaller on mobile
    );

    // Table (header + data)
    Widget tableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Rank',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'Team',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Ranking Points\n(RP) (Avg)',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Match Score\n(Avg)',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Charge Station\n(Avg)',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Golden Charge\n(Avg)',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Charge Points\n(Avg)',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Record\n(W-L-T)',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'Played',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'Points',
                  style: headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // DATA
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
                final currentRank =
                    (value['currentRank'] as num?)?.toInt() ?? 9999;
                final previousRank =
                    (value['previousRank'] as num?)?.toInt() ?? currentRank;

                final rankingScoreAvg =
                    (value['rankingScoreAvg'] as num?)?.toDouble() ?? 0.0;
                final matchScoreAvg =
                    (value['matchScoreAvg'] as num?)?.toDouble() ?? 0.0;
                final chargeStationAvg =
                    (value['chargeStationAvg'] as num?)?.toDouble() ?? 0.0;
                final goldenChargeAvg =
                    (value['goldenChargeAvg'] as num?)?.toDouble() ?? 0.0;
                final chargePointsAvg =
                    (value['chargePointsAvg'] as num?)?.toDouble() ?? 0.0;

                final wins = (value['wins'] as num?)?.toInt() ?? 0;
                // support both "losses" and (typo) "lossses"
                final losses =
                    ((value['losses'] ?? value['lossses']) as num?)?.toInt() ??
                    0;
                final ties = (value['tie'] as num?)?.toInt() ?? 0;

                final played = (value['played'] as num?)?.toInt() ?? 0;
                final points = (value['points'] as num?)?.toInt() ?? 0;

                final teamNumber = teamKey.toString();

                rows.add(
                  _LeaderboardEntry(
                    currentRank: currentRank,
                    previousRank: previousRank,
                    teamNumber: teamNumber,
                    rankingScoreAvg: rankingScoreAvg,
                    matchScoreAvg: matchScoreAvg,
                    chargeStationAvg: chargeStationAvg,
                    goldenChargeAvg: goldenChargeAvg,
                    chargePointsAvg: chargePointsAvg,
                    wins: wins,
                    losses: losses,
                    ties: ties,
                    played: played,
                    points: points,
                  ),
                );
              }
            });

            // Sort by currentRank
            rows.sort((a, b) => a.currentRank.compareTo(b.currentRank));

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
                  _LeaderboardRow(index: i, entry: rows[i], isMobile: isMobile),
                  const SizedBox(height: 1),
                ],
              ],
            );
          },
        ),
      ],
    );

    // Wrap entire table in horizontal scroll for mobile to avoid overflow
    final tableWrapper =
        isMobile
            ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1000, // enough width for all columns on mobile
                child: tableContent,
              ),
            )
            : tableContent;

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
          tableWrapper,
        ],
      ),
    );
  }
}

class _LeaderboardEntry {
  final int currentRank;
  final int previousRank;
  final String teamNumber;

  final double rankingScoreAvg;
  final double matchScoreAvg;
  final double chargeStationAvg;
  final double goldenChargeAvg;
  final double chargePointsAvg;

  final int wins;
  final int losses;
  final int ties;
  final int played;
  final int points;

  _LeaderboardEntry({
    required this.currentRank,
    required this.previousRank,
    required this.teamNumber,
    required this.rankingScoreAvg,
    required this.matchScoreAvg,
    required this.chargeStationAvg,
    required this.goldenChargeAvg,
    required this.chargePointsAvg,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.played,
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
  final _LeaderboardEntry entry;
  final bool isMobile;

  const _LeaderboardRow({
    required this.index,
    required this.entry,
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

    // Arrow logic
    final delta =
        widget.entry.previousRank - widget.entry.currentRank; // +ve = went up
    IconData arrowIcon;
    Color arrowColor;

    if (delta > 0) {
      arrowIcon = Icons.arrow_upward;
      arrowColor = Colors.greenAccent;
    } else if (delta < 0) {
      arrowIcon = Icons.arrow_downward;
      arrowColor = Colors.redAccent;
    } else {
      arrowIcon = Icons.remove;
      arrowColor = Colors.grey;
    }

    final recordText =
        '${widget.entry.wins}-${widget.entry.losses}-${widget.entry.ties}';

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
          // Rank + arrow
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('#${widget.entry.currentRank}', style: rankTextStyle),
                const SizedBox(width: 4),
                Icon(arrowIcon, size: 16, color: arrowColor),
              ],
            ),
          ),

          // Team number
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                widget.entry.teamNumber,
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // RankingScoreAvg
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                widget.entry.rankingScoreAvg.toStringAsFixed(2),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // MatchScoreAvg
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                widget.entry.matchScoreAvg.toStringAsFixed(2),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // ChargeStationAvg
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                widget.entry.chargeStationAvg.toStringAsFixed(2),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // GoldenChargeAvg
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                widget.entry.goldenChargeAvg.toStringAsFixed(2),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // ChargePointsAvg
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                widget.entry.chargePointsAvg.toStringAsFixed(2),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Record W-L-T
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                recordText,
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Played
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                widget.entry.played.toString(),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Points
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                widget.entry.points.toString(),
                style: pointsStyle,
                textAlign: TextAlign.center,
              ),
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
