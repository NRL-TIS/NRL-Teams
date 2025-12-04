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
    return 'Champion_Match_';
  }

  final lower = division.toLowerCase();
  final cap = '${lower[0].toUpperCase()}${lower.substring(1)}';

  switch (phase) {
    case 'final':
      return '${cap}_Final_Match_';
    case 'semifinal':
      return '${cap}_Semifinal_Match_';
    case 'quarterfinal':
      return '${cap}_Quaterfinal_Match_';
    case 'qualification':
    default:
      return '${cap}_Qualification_Match_';
  }
}

String _buildScheduleDocId(String division, String phase) {
  if (phase == 'championofchampions') {
    return 'champions';
  }

  final lower = division.toLowerCase();
  final cap = '${lower[0].toUpperCase()}${lower.substring(1)}';

  switch (phase) {
    case 'final':
      return '${lower}_finals';
    case 'semifinal':
      return '${cap}_semifinals';
    case 'quarterfinal':
      return '${cap}_quarterfinals';
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
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('Match Schedule')
                .doc('current_match')
                .snapshots(),
            builder: (context, currentMatchSnap) {
              // Get current stage
              String? currentStage;
              if (currentMatchSnap.hasData && currentMatchSnap.data!.exists) {
                final data = currentMatchSnap.data!.data();
                currentStage = data?['current_stage']?.toString();
              }

              return StreamBuilder<QuerySnapshot>(
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

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('Matches')
                            .snapshots(),
                    builder: (context, matchesSnap) {
                      final matchesDocs =
                          matchesSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

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
                          currentStage: currentStage,
                        ),
                      );
                    },
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
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> matchesDocs;
  final String? currentStage;

  const _DivisionPhasesView({
    Key? key,
    required this.division,
    required this.searchQuery,
    required this.scheduleDocs,
    required this.matchesDocs,
    required this.currentStage,
  }) : super(key: key);

  // Create a map of match document IDs to their scores for quick lookup
  // Prioritizes red_final_score_with_penalties and blue_final_score_with_penalties
  Map<String, Map<String, int>> _buildScoresMap() {
    final Map<String, Map<String, int>> scoresMap = {};
    
    for (final doc in matchesDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      
      // Use red_final_score_with_penalties and blue_final_score_with_penalties (primary)
      // Fallback to red_final_score and blue_final_score if penalties not available
      int? redScore = (data['red_final_score_with_penalties'] as num?)?.toInt();
      int? blueScore = (data['blue_final_score_with_penalties'] as num?)?.toInt();
      
      // If penalties scores don't exist, try regular scores
      if (redScore == null) {
        redScore = (data['red_final_score'] as num?)?.toInt();
      }
      if (blueScore == null) {
        blueScore = (data['blue_final_score'] as num?)?.toInt();
      }
      
      // Only add to map if at least one score exists
      if (redScore != null || blueScore != null) {
        scoresMap[doc.id] = {
          'red': redScore ?? 0,
          'blue': blueScore ?? 0,
        };
      }
    }
    
    return scoresMap;
  }

  // Create a map of match document IDs to their finalized status
  Map<String, bool> _buildFinalizedMap() {
    final Map<String, bool> finalizedMap = {};
    
    for (final doc in matchesDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final finalized = (data['finalized'] as bool?) ?? false;
      finalizedMap[doc.id] = finalized;
    }
    
    return finalizedMap;
  }

  // Create a map of match document IDs to their winner field
  Map<String, String?> _buildWinnerMap() {
    final Map<String, String?> winnerMap = {};
    
    for (final doc in matchesDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final winner = data['winner'] as String?;
      winnerMap[doc.id] = winner; // Can be 'Red', 'Blue', or null (tie)
    }
    
    return winnerMap;
  }

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

    // Build maps once for all phases
    final scoresMap = _buildScoresMap();
    final finalizedMap = _buildFinalizedMap();
    final winnerMap = _buildWinnerMap();

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

      final allMatches = _extractMatchesFromScheduleDoc(scheduleDoc);
      
      // Only show section if it has matches (not empty)
      if (allMatches.isEmpty) {
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
                currentStage: currentStage,
                scoresMap: scoresMap,
                finalizedMap: finalizedMap,
                matchesDocs: matchesDocs,
                winnerMap: winnerMap,
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
  final String? currentStage;
  final Map<String, Map<String, int>> scoresMap;
  final Map<String, bool> finalizedMap;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> matchesDocs;
  final Map<String, String?> winnerMap;

  const _MatchScheduleTable({
    Key? key,
    required this.matches,
    required this.division,
    required this.phase,
    required this.currentStage,
    required this.scoresMap,
    required this.finalizedMap,
    required this.matchesDocs,
    required this.winnerMap,
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
                                initialRedScore: m['redScore'] as int,
                                initialBlueScore: m['blueScore'] as int,
                                scoresMap: scoresMap,
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
                                currentStage: currentStage,
                                allMatches: matches,
                                matchesDocs: matchesDocs,
                                finalizedMap: finalizedMap,
                                scoresMap: scoresMap,
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
                                winnerMap: winnerMap,
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

    // 1.25x scale for mobile
    const double mobileScale = 1.5;

    // base mobile values (your old ones)
    const double baseMobileH = 4;
    const double baseMobileV = 4;
    const double baseMobileFont = 9;

    final double horizontalPadding = isMobile ? baseMobileH * mobileScale : 10;
    final double verticalPadding = isMobile ? baseMobileV * mobileScale : 6;
    final double fontSize = isMobile ? baseMobileFont * mobileScale : 13;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
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
            fontSize: fontSize,
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
  final int initialRedScore;
  final int initialBlueScore;
  final Map<String, Map<String, int>> scoresMap;

  const _ScoreCell({
    required this.division,
    required this.phase,
    required this.matchId,
    required this.baseStyle,
    required this.initialRedScore,
    required this.initialBlueScore,
    required this.scoresMap,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';

    // Look up scores from the map (much faster than individual StreamBuilder)
    int redScore = initialRedScore;
    int blueScore = initialBlueScore;

    final scores = scoresMap[docId];
    if (scores != null) {
      redScore = scores['red'] ?? initialRedScore;
      blueScore = scores['blue'] ?? initialBlueScore;
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
        // Green for completed
        bg = const Color(0xFF2E7D32); // or 0xFF00C853 for brighter
        break;

      case 'running':
        // Keep amber for in-progress
        bg = const Color(0xFFFFB300);
        break;

      case 'tie':
        // Your existing purple
        bg = const Color(0xFF6A1B9A);
        break;

      case 'scheduled':
      default:
        // Muted blue-grey for scheduled
        bg = const Color(0xFF546E7A);
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
  final String? currentStage;
  final List<Map<String, dynamic>> allMatches;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> matchesDocs;
  final Map<String, bool> finalizedMap;
  final Map<String, Map<String, int>> scoresMap;

  const _StatusFromMatches({
    required this.division,
    required this.phase,
    required this.matchId,
    required this.fallbackStatus,
    required this.currentStage,
    required this.allMatches,
    required this.matchesDocs,
    required this.finalizedMap,
    required this.scoresMap,
  });

  bool _isCurrentStage() {
    if (currentStage == null) return false;
    
    final normalizedCurrentStage = currentStage!.toLowerCase().replaceAll(' ', '_');
    final normalizedPhase = phase.toLowerCase();
    
    // Check if this phase matches current stage
    if (normalizedCurrentStage == normalizedPhase) return true;
    
    // Handle qualification matches (alpha/bravo -> qualification)
    if ((normalizedCurrentStage == 'alpha' || normalizedCurrentStage == 'bravo' || normalizedCurrentStage == 'qualification') &&
        normalizedPhase == 'qualification') {
      return true;
    }
    
    // Check if current stage contains this phase or vice versa
    if (normalizedCurrentStage.contains(normalizedPhase) || normalizedPhase.contains(normalizedCurrentStage)) {
      return true;
    }
    
    return false;
  }

  String? _getQueuedMatchId() {
    if (!_isCurrentStage()) return null;
    
    // Find the first match that is scheduled (not running, not completed)
    // This will be the "queued" match (next to be played)
    // Sort matches by matchId to get the next one in order
    final sortedMatches = List<Map<String, dynamic>>.from(allMatches);
    sortedMatches.sort((a, b) {
      final aId = int.tryParse(a['matchId'].toString()) ?? 0;
      final bId = int.tryParse(b['matchId'].toString()) ?? 0;
      return aId.compareTo(bId);
    });
    
    for (final match in sortedMatches) {
      final matchNum = match['matchId'].toString();
      final prefix = _buildMatchesDocPrefix(division, phase);
      final docId = '$prefix$matchNum';
      
      // Check if this match document exists
      final matchDocIndex = matchesDocs.indexWhere((doc) => doc.id == docId);
      
      if (matchDocIndex == -1) {
        // Document doesn't exist, it's scheduled/queued
        return matchNum;
      }
      
      // Document exists, check if finalized
      final finalized = finalizedMap[docId] ?? false;
      if (!finalized) {
        // Check if it has scores (running) or not (scheduled/queued)
        final scores = scoresMap[docId];
        final redScore = scores?['red'] ?? 0;
        final blueScore = scores?['blue'] ?? 0;
        
        if (redScore == 0 && blueScore == 0) {
          // No scores, this is the next queued match
          return matchNum;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';
    final isCurrentStage = _isCurrentStage();
    final queuedMatchId = _getQueuedMatchId();

    // Look up match document from matchesDocs (much faster than individual StreamBuilder)
    final matchDocIndex = matchesDocs.indexWhere((doc) => doc.id == docId);
    final bool docExists = matchDocIndex != -1;
    final bool finalized = docExists ? (finalizedMap[docId] ?? false) : false;

    String status;

    if (!docExists) {
      // Document doesn't exist
      if (isCurrentStage && queuedMatchId == matchId) {
        status = 'Queued';
      } else {
        status = fallbackStatus;
      }
    } else if (finalized) {
      // If finalized is true, always show Completed
      status = 'Completed';
    } else {
      // Document exists but not finalized
      if (!isCurrentStage) {
        // Not current stage, show Scheduled
        status = 'Scheduled';
      } else {
        // Current stage - check if running or queued
        final scores = scoresMap[docId];
        final int redScore = scores?['red'] ?? 0;
        final int blueScore = scores?['blue'] ?? 0;

        if (redScore > 0 || blueScore > 0) {
          // Has scores, match is running
          status = 'Running';
        } else if (queuedMatchId == matchId) {
          // This is the next match to be played
          status = 'Queued';
        } else {
          // Scheduled but not queued yet
          status = 'Scheduled';
        }
      }
    }

    return _StatusChip(status: status);
  }
}

class _WinnerFromMatches extends StatelessWidget {
  final String division;
  final String phase;
  final String matchId;
  final List<String> redTeams;
  final List<String> blueTeams;
  final TextStyle? baseStyle;
  final Map<String, String?> winnerMap;

  const _WinnerFromMatches({
    required this.division,
    required this.phase,
    required this.matchId,
    required this.redTeams,
    required this.blueTeams,
    required this.baseStyle,
    required this.winnerMap,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';

    // Get winner from the map (can be 'Red', 'Blue', or null for tie)
    final String? winner = winnerMap[docId];

    // If no winner field or it's null (tie), show '-'
    if (winner == null || winner.isEmpty) {
      return Text('-', style: baseStyle);
    }

    // Determine which teams won based on the winner field
    final bool redWins = winner.toLowerCase() == 'red';
    final bool blueWins = winner.toLowerCase() == 'blue';

    final List<String> winnerTeams = redWins 
        ? redTeams 
        : (blueWins ? blueTeams : <String>[]);

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
