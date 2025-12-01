// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Individual_team_page.dart';

class MatchSchedulePage extends StatefulWidget {
  const MatchSchedulePage({super.key});

  @override
  State<MatchSchedulePage> createState() => _MatchSchedulePageState();
}

void _parseMatchMapIntoList(
  Map<String, dynamic> inner,
  List<Map<String, dynamic>> matches,
) {
  final matchNumber = inner['matchNumber']?.toString() ?? '';

  final redTeams =
      (inner['red'] as List?)
          ?.map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList() ??
      <String>[];

  final blueTeams =
      (inner['blue'] as List?)
          ?.map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList() ??
      <String>[];

  final score = inner['score'];
  int redScore = 0;
  int blueScore = 0;
  if (score is Map<String, dynamic>) {
    redScore = (score['red'] as num?)?.toInt() ?? 0;
    blueScore = (score['blue'] as num?)?.toInt() ?? 0;
  }

  String status;
  if (redScore == 0 && blueScore == 0) {
    status = 'Scheduled';
  } else {
    status = 'Completed';
  }

  matches.add({
    'matchId': matchNumber,
    'time': inner['time']?.toString() ?? '-',
    'redTeams': redTeams,
    'blueTeams': blueTeams,
    'redScore': redScore,
    'blueScore': blueScore,
    'status': status,
  });
}

String _buildMatchesDocPrefix(String division, String phase) {
  if (phase == 'championofchampions') {
    return 'Champion_of_champions_Match_';
  }

  final lower = division.toLowerCase();
  final cap = '${lower[0].toUpperCase()}${lower.substring(1)}';

  switch (phase) {
    case 'final':
      return '${cap}_final_Match_';
    case 'semifinal':
      return '${cap}_semifinal_Match_';
    case 'quarterfinal':
      return '${cap}_quarterfinals_Match_';
    case 'qualification':
    default:
      return '${cap}_Qualification_Match_';
  }
}

String _buildScheduleDocId(String division, String phase) {
  if (phase == 'championofchampions') {
    return 'Championofchampions';
  }

  final lower = division.toLowerCase();
  final cap = '${lower[0].toUpperCase()}${lower.substring(1)}';

  switch (phase) {
    case 'final':
      return '${cap}_final';
    case 'semifinal':
      return '${cap}_semifinal';
    case 'quarterfinal':
      return '${cap}_quarterfinal';
    case 'qualification':
    default:
      return lower;
  }
}

class _MatchSchedulePageState extends State<MatchSchedulePage> {
  String selectedDivision = 'alpha';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchScheduleHeader(
          isMobile: isMobile,
          selectedDivision: selectedDivision,
          onDivisionChanged: (value) {
            setState(() {
              selectedDivision = value;
            });
          },
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
        ),
        const SizedBox(height: 12),
        Divider(color: Colors.white.withOpacity(0.16), thickness: 1, height: 1),
        const SizedBox(height: 4),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('Match Schedule')
                    .snapshots(),
            builder: (context, scheduleSnap) {
              if (scheduleSnap.connectionState == ConnectionState.waiting &&
                  !scheduleSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (scheduleSnap.hasError) {
                return Center(
                  child: Text(
                    'Error loading schedule',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                  ),
                );
              }

              if (!scheduleSnap.hasData || scheduleSnap.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No schedule found.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                );
              }

              final scheduleDocs = scheduleSnap.data!.docs;

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('Matches')
                        .snapshots(),
                builder: (context, matchesSnap) {
                  final matchesDocs =
                      matchesSnap.data?.docs ?? <QueryDocumentSnapshot>[];

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _DivisionPhasesView(
                      key: ValueKey(
                        '$selectedDivision|$_searchQuery|${scheduleDocs.length}|${matchesDocs.length}',
                      ),
                      division: selectedDivision,
                      searchQuery: _searchQuery,
                      scheduleDocs: scheduleDocs,
                      matchesDocs: matchesDocs,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MatchScheduleHeader extends StatelessWidget {
  final bool isMobile;
  final String selectedDivision;
  final ValueChanged<String> onDivisionChanged;
  final ValueChanged<String> onSearchChanged;

  const _MatchScheduleHeader({
    required this.isMobile,
    required this.selectedDivision,
    required this.onDivisionChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleMainStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
      fontSize: isMobile ? 16 : 18,
    );

    final titleSubStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white.withOpacity(0.80),
      fontWeight: FontWeight.w500,
      fontSize: isMobile ? 14 : 16,
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('60 Qualification Matches', style: titleMainStyle),
            Text('4 Teams per Match', style: titleSubStyle),
          ],
        ),
      ],
    );

    final searchField = TextField(
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search team number...',
        prefixIcon: const Icon(Icons.search, size: 18),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF101010),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: cs.primary, width: 1.2),
        ),
      ),
      onChanged: onSearchChanged,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 220 : 320),
              child: searchField,
            ),
          ],
        ),
        const SizedBox(height: 12),

        _DivisionSegmentedControl(
          selectedDivision: selectedDivision,
          onChanged: onDivisionChanged,
        ),
      ],
    );
  }
}

class _DivisionSegmentedControl extends StatelessWidget {
  final String selectedDivision;
  final ValueChanged<String> onChanged;

  const _DivisionSegmentedControl({
    required this.selectedDivision,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isAlpha = selectedDivision == 'alpha';

    Widget buildSegment({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: selected ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
      ),
      child: Row(
        children: [
          buildSegment(
            label: 'Alpha',
            selected: isAlpha,
            onTap: () => onChanged('alpha'),
          ),
          buildSegment(
            label: 'Bravo',
            selected: !isAlpha,
            onTap: () => onChanged('bravo'),
          ),
        ],
      ),
    );
  }
}

class _DivisionPhasesView extends StatelessWidget {
  final String division;
  final String searchQuery;
  final List<QueryDocumentSnapshot> scheduleDocs;
  final List<QueryDocumentSnapshot> matchesDocs;

  const _DivisionPhasesView({
    Key? key,
    required this.division,
    required this.searchQuery,
    required this.scheduleDocs,
    required this.matchesDocs,
  }) : super(key: key);

  List<Map<String, dynamic>> _extractMatchesFromScheduleDoc(
    DocumentSnapshot? doc,
  ) {
    if (doc == null || !doc.exists) return <Map<String, dynamic>>[];

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final matchesField = data['matches'];

    final List<Map<String, dynamic>> matches = [];

    if (matchesField is Map<String, dynamic>) {
      matchesField.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _parseMatchMapIntoList(value, matches);
        }
      });
    } else if (matchesField is List) {
      for (final element in matchesField) {
        if (element is Map<String, dynamic>) {
          if (element.containsKey('matchNumber')) {
            _parseMatchMapIntoList(element, matches);
          } else if (element.isNotEmpty) {
            final inner = element.values.first;
            if (inner is Map<String, dynamic>) {
              _parseMatchMapIntoList(inner, matches);
            }
          }
        }
      }
    }

    return matches;
  }

  List<Map<String, dynamic>> _filterMatches(
    List<Map<String, dynamic>> matches,
    String query,
  ) {
    if (query.isEmpty) return matches;

    final q = query;
    return matches.where((m) {
      final redTeams =
          (m['redTeams'] as List).map((e) => e.toString()).toList();
      final blueTeams =
          (m['blueTeams'] as List).map((e) => e.toString()).toList();
      final matchId = m['matchId'].toString();

      final inRed = redTeams.any((t) => t.contains(q));
      final inBlue = blueTeams.any((t) => t.contains(q));
      final inMatchId = matchId.contains(q);

      return inRed || inBlue || inMatchId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<Widget> sections = [];
    bool anyFilteredMatch = false;

    void addPhaseSection({
      required String phase,
      required String label,
      required bool requireMatchesDocsForVisibility,
    }) {
      final scheduleDocId = _buildScheduleDocId(division, phase);
      final scheduleDoc = scheduleDocs
          .cast<DocumentSnapshot>()
          .where((d) => d.id == scheduleDocId)
          .cast<DocumentSnapshot?>()
          .firstWhere((d) => d != null, orElse: () => null);

      if (scheduleDoc == null) {
        return;
      }

      if (requireMatchesDocsForVisibility) {
        final matchPrefix = _buildMatchesDocPrefix(division, phase);
        final bool hasAnyMatchDoc = matchesDocs.any(
          (d) => d.id.startsWith(matchPrefix),
        );
        if (!hasAnyMatchDoc) {
          return;
        }
      }

      final allMatches = _extractMatchesFromScheduleDoc(scheduleDoc);
      var filtered = _filterMatches(allMatches, searchQuery);

      if (filtered.isEmpty) {
        return;
      }

      anyFilteredMatch = true;

      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              _MatchScheduleTable(
                matches: filtered,
                division: division,
                phase: phase,
              ),
            ],
          ),
        ),
      );
    }

    addPhaseSection(
      phase: 'championofchampions',
      label: 'Champion of Champions',
      requireMatchesDocsForVisibility: false,
    );

    addPhaseSection(
      phase: 'final',
      label: 'Final',
      requireMatchesDocsForVisibility: false,
    );

    addPhaseSection(
      phase: 'semifinal',
      label: 'Semifinals',
      requireMatchesDocsForVisibility: false,
    );

    addPhaseSection(
      phase: 'quarterfinal',
      label: 'Quarterfinals',
      requireMatchesDocsForVisibility: false,
    );

    addPhaseSection(
      phase: 'qualification',
      label: 'Qualification Matches',
      requireMatchesDocsForVisibility: false,
    );

    if (sections.isEmpty) {
      if (searchQuery.isNotEmpty) {
        return Center(
          child: Text(
            'No matches found for "$searchQuery".',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        );
      }
      return Center(
        child: Text(
          'No matches added yet.',
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      ),
    );
  }
}

class _MatchScheduleTable extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final String division;
  final String phase;

  const _MatchScheduleTable({
    Key? key,
    required this.matches,
    required this.division,
    required this.phase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.90),
    );

    final dataStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.90));

    Widget _header(String text) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: headingStyle),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTableWidth = 900;
        final double tableWidth =
            constraints.maxWidth < minTableWidth
                ? minTableWidth
                : constraints.maxWidth;

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: DataTable(
                columnSpacing: 32,
                headingRowHeight: 40,
                dataRowHeight: 52,
                headingTextStyle: headingStyle,
                dataTextStyle: dataStyle,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                columns: [
                  DataColumn(label: _header('Match #')),
                  DataColumn(label: _header('Time')),
                  DataColumn(label: _header('Red Squad')),
                  DataColumn(label: _header('Blue Squad')),
                  DataColumn(label: _header('Score')),
                  DataColumn(label: _header('Status')),
                  DataColumn(label: _header('Winner')),
                ],
                rows:
                    matches.map((m) {
                      final redTeams =
                          (m['redTeams'] as List)
                              .map((e) => e.toString())
                              .toList();
                      final blueTeams =
                          (m['blueTeams'] as List)
                              .map((e) => e.toString())
                              .toList();
                      final String status = m['status'] as String;

                      final dataStyleLocal = dataStyle;
                      final matchId = m['matchId'].toString();

                      return DataRow(
                        cells: [
                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                matchId,
                                style: dataStyleLocal?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                m['time'].toString(),
                                style: dataStyleLocal,
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                children:
                                    redTeams
                                        .map(
                                          (t) => _TeamChip(
                                            teamNumber: t,
                                            background: const Color(0xFFE53935),
                                            onTap:
                                                () => _openTeamPage(context, t),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                children:
                                    blueTeams
                                        .map(
                                          (t) => _TeamChip(
                                            teamNumber: t,
                                            background: const Color(0xFF1E88E5),
                                            onTap:
                                                () => _openTeamPage(context, t),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _ScoreCell(
                                division: division,
                                phase: phase,
                                matchId: matchId,
                                baseStyle: dataStyleLocal,
                                initialRedScore: m['redScore'] as int, // NEW
                                initialBlueScore: m['blueScore'] as int, // NEW
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _StatusFromMatches(
                                division: division,
                                phase: phase,
                                matchId: matchId,
                                fallbackStatus: status,
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _WinnerFromMatches(
                                division: division,
                                phase: phase,
                                matchId: matchId,
                                redTeams: redTeams,
                                blueTeams: blueTeams,
                                baseStyle: dataStyleLocal,
                                initialRedScore: m['redScore'] as int, // NEW
                                initialBlueScore: m['blueScore'] as int, // NEW
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String teamNumber;
  final Color background;
  final VoidCallback onTap;

  const _TeamChip({
    required this.teamNumber,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 10,
          vertical: isMobile ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          teamNumber,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 9 : 13,
          ),
        ),
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  final String division;
  final String phase;
  final String matchId;
  final TextStyle? baseStyle;

  // NEW
  final int initialRedScore;
  final int initialBlueScore;

  const _ScoreCell({
    required this.division,
    required this.phase,
    required this.matchId,
    required this.baseStyle,
    required this.initialRedScore, // NEW
    required this.initialBlueScore, // NEW
  });

  @override
  Widget build(BuildContext context) {
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Matches')
              .doc(docId)
              .snapshots(),
      builder: (context, snapshot) {
        // start with schedule data (immediate)
        int redScore = initialRedScore;
        int blueScore = initialBlueScore;

        // override if Matches doc is available
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          redScore = (data['red_final_score'] as num?)?.toInt() ?? redScore;
          blueScore = (data['blue_final_score'] as num?)?.toInt() ?? blueScore;
        }

        final bool redWins = redScore > blueScore;
        final bool blueWins = blueScore > redScore;

        TextStyle style(bool isWinner) =>
            (baseStyle ?? const TextStyle()).copyWith(
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              decoration:
                  isWinner ? TextDecoration.underline : TextDecoration.none,
            );

        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: redScore.toString(), style: style(redWins)),
              TextSpan(text: '  -  ', style: baseStyle),
              TextSpan(text: blueScore.toString(), style: style(blueWins)),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFF333333);
        break;
      case 'running':
        bg = const Color(0xFFFFB300);
        break;
      case 'tie':
        bg = const Color(0xFF6A1B9A);
        break;
      case 'scheduled':
      default:
        bg = const Color(0xFF424242);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,

        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusFromMatches extends StatelessWidget {
  final String division;
  final String phase;
  final String matchId;
  final String fallbackStatus;

  const _StatusFromMatches({
    required this.division,
    required this.phase,
    required this.matchId,
    required this.fallbackStatus,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Matches')
              .doc(docId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _StatusChip(status: fallbackStatus);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final redScore = (data['red_final_score'] as num?)?.toInt() ?? 0;
        final blueScore = (data['blue_final_score'] as num?)?.toInt() ?? 0;

        String status;
        if (redScore == 0 && blueScore == 0) {
          status = 'Scheduled';
        } else if (redScore == blueScore) {
          status = 'Tie';
        } else {
          status = 'Completed';
        }

        return _StatusChip(status: status);
      },
    );
  }
}

class _WinnerFromMatches extends StatelessWidget {
  final String division;
  final String phase;
  final String matchId;
  final List<String> redTeams;
  final List<String> blueTeams;
  final TextStyle? baseStyle;

  // NEW
  final int initialRedScore;
  final int initialBlueScore;

  const _WinnerFromMatches({
    required this.division,
    required this.phase,
    required this.matchId,
    required this.redTeams,
    required this.blueTeams,
    required this.baseStyle,
    required this.initialRedScore, // NEW
    required this.initialBlueScore, // NEW
  });

  @override
  Widget build(BuildContext context) {
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Matches')
              .doc(docId)
              .snapshots(),
      builder: (context, snapshot) {
        // start with schedule scores
        int redScore = initialRedScore;
        int blueScore = initialBlueScore;

        // override if Matches doc has data
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          redScore = (data['red_final_score'] as num?)?.toInt() ?? redScore;
          blueScore = (data['blue_final_score'] as num?)?.toInt() ?? blueScore;
        }

        final bool redWins = redScore > blueScore;
        final bool blueWins = blueScore > redScore;

        final winnerTeams =
            redWins ? redTeams : (blueWins ? blueTeams : <String>[]);

        if (winnerTeams.isEmpty) {
          return Text('-', style: baseStyle);
        }

        return Wrap(
          spacing: 8,
          children:
                  winnerTeams
                      .map(
                        (t) => _TeamChip(
                          teamNumber: t,
                          background:
                              redWins
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF1E88E5),
                          onTap: () => _openTeamPage(context, t),
                        ),
                      )
                      .toList(),
        );
      },
    );
  }
}

void _openTeamPage(BuildContext context, String teamNumber) {
  final normalized = teamNumber.trim();
  final docId = teamNumber.padLeft(3, '0');

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TeamDetailPage(teamNumber: teamNumber, teamDocId: docId),
    ),
  );
}
