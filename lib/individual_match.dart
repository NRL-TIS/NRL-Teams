import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Page that displays all matches for a specific team
class IndividualMatchSchedulePage extends StatelessWidget {
  final String teamNumber;

  const IndividualMatchSchedulePage({
    super.key,
    required this.teamNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Team $teamNumber Matches',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: IndividualMatchSchedule(teamNumber: teamNumber),
      ),
    );
  }
}

/// Fetches and displays matches for a specific team from Match Schedule collection
/// Organizes matches by stage (current stage at top, previous stages below)
class IndividualMatchSchedule extends StatelessWidget {
  final String teamNumber;

  const IndividualMatchSchedule({
    super.key,
    required this.teamNumber,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

        // Fetch all Match Schedule documents
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
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
                  'Error loading matches',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.redAccent,
                      ),
                ),
              );
            }

            if (!scheduleSnap.hasData || scheduleSnap.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No matches found.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              );
            }

            // Organize matches by stage
            final organizedMatches = _organizeMatchesByStage(
              scheduleSnap.data!.docs,
              teamNumber,
              currentStage,
            );

            if (organizedMatches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No matches for this team yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              );
            }

            // Display matches organized by stage
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: organizedMatches.length,
              itemBuilder: (context, index) {
                final stageData = organizedMatches[index];
                return _StageSection(
                  stageName: stageData['stageName'] as String,
                  matches: stageData['matches'] as List<Map<String, dynamic>>,
                  teamNumber: teamNumber,
                  isCurrentStage: stageData['isCurrent'] as bool,
                );
              },
            );
          },
        );
      },
    );
  }

  /// Organizes matches by stage based on current_stage
  /// Returns list of stage data with matches, ordered: current first, then previous stages
  List<Map<String, dynamic>> _organizeMatchesByStage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String teamNumber,
    String? currentStage,
  ) {
    // Define stage order and document mapping
    final stageConfig = [
      {
        'stage': 'champions_of_champions',
        'docIds': ['champions'],
        'label': 'Champions of Champions',
      },
      {
        'stage': 'alpha_finals',
        'docIds': ['alpha_finals'],
        'label': 'Alpha Finals',
      },
      {
        'stage': 'bravo_finals',
        'docIds': ['bravo_finals'],
        'label': 'Bravo Finals',
      },
      {
        'stage': 'alpha_semifinals',
        'docIds': ['Alpha_semifinals'],
        'label': 'Alpha Semi Finals',
      },
      {
        'stage': 'bravo_semifinals',
        'docIds': ['Bravo_semifinals'],
        'label': 'Bravo Semi Finals',
      },
      {
        'stage': 'alpha_quarterfinals',
        'docIds': ['Alpha_quarterfinals'],
        'label': 'Alpha Quarterfinals',
      },
      {
        'stage': 'bravo_quarterfinals',
        'docIds': ['Bravo_quarterfinals'],
        'label': 'Bravo Quarterfinals',
      },
      {
        'stage': 'qualification',
        'docIds': ['alpha', 'bravo'],
        'label': 'Qualification',
      },
    ];

    final List<Map<String, dynamic>> organizedStages = [];
    final List<Map<String, dynamic>> currentStages = [];
    final List<Map<String, dynamic>> previousStages = [];

    // Determine which stage is current
    String? normalizedCurrentStage;
    int? currentStageIndex;
    
    if (currentStage != null) {
      normalizedCurrentStage = currentStage.toLowerCase().replaceAll(' ', '_');
      
      // Map current_stage to stage config index
      // Handle special cases: "alpha" or "bravo" -> qualification
      if (normalizedCurrentStage == 'alpha' || 
          normalizedCurrentStage == 'bravo' ||
          normalizedCurrentStage == 'qualification') {
        currentStageIndex = stageConfig.length - 1; // qualification is last
      } else {
        // Find matching stage in config
        for (int i = 0; i < stageConfig.length; i++) {
          final configStage = stageConfig[i]['stage'] as String;
          if (normalizedCurrentStage == configStage ||
              normalizedCurrentStage.contains(configStage) ||
              configStage.contains(normalizedCurrentStage)) {
            currentStageIndex = i;
            break;
          }
        }
      }
    }

    // Process each stage
    for (int i = 0; i < stageConfig.length; i++) {
      final config = stageConfig[i];
      final stageName = config['stage'] as String;
      final docIds = config['docIds'] as List<String>;
      final label = config['label'] as String;

      final List<Map<String, dynamic>> stageMatches = [];

      // Fetch matches from relevant documents
      for (final docId in docIds) {
        final matchingDocs = docs.where((d) => d.id == docId).toList();
        if (matchingDocs.isEmpty) continue; // Document doesn't exist
        
        final doc = matchingDocs.first;

        final docData = doc.data() as Map<String, dynamic>? ?? {};
        final matchesField = docData['matches'];

        // Extract matches from the document
        final extractedMatches = _extractMatchesFromDoc(
          matchesField,
          docId,
          stageName,
          teamNumber,
        );

        stageMatches.addAll(extractedMatches);
      }

      // Only add stage if it has matches
      if (stageMatches.isEmpty) continue;

      // Determine if this is current stage
      final isCurrent = currentStageIndex != null && i == currentStageIndex;

      final stageData = {
        'stageName': label,
        'matches': stageMatches,
        'isCurrent': isCurrent,
        'stageKey': stageName,
      };

      if (isCurrent) {
        currentStages.add(stageData);
      } else if (currentStageIndex != null) {
        // Check if this is a previous stage
        // Previous stages have higher indices (come later in the list)
        // since list is ordered: latest -> earliest
        if (i > currentStageIndex) {
          // This is a previous stage (earlier in tournament)
          previousStages.add(stageData);
        }
        // Future stages (i < currentStageIndex) are not added
      } else {
        // No current stage defined, show all stages that have matches
        previousStages.add(stageData);
      }
    }

    // Combine: current stages first, then previous stages
    organizedStages.addAll(currentStages);
    organizedStages.addAll(previousStages);

    return organizedStages;
  }

  /// Extracts matches from a document's matches field and filters by team
  List<Map<String, dynamic>> _extractMatchesFromDoc(
    dynamic matchesField,
    String docId,
    String stageName,
    String teamNumber,
  ) {
    final List<Map<String, dynamic>> matches = [];

    if (matchesField is Map<String, dynamic>) {
      matchesField.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _addMatchIfTeamInvolved(
            matches,
            value,
            docId,
            stageName,
            teamNumber,
          );
        }
      });
    } else if (matchesField is List) {
      for (final element in matchesField) {
        if (element is Map<String, dynamic>) {
          if (element.containsKey('matchNumber')) {
            _addMatchIfTeamInvolved(
              matches,
              element,
              docId,
              stageName,
              teamNumber,
            );
          } else if (element.isNotEmpty) {
            final inner = element.values.first;
            if (inner is Map<String, dynamic>) {
              _addMatchIfTeamInvolved(
                matches,
                inner,
                docId,
                stageName,
                teamNumber,
              );
            }
          }
        }
      }
    }

    return matches;
  }

  /// Adds a match to the list if the team is involved (in red or blue)
  void _addMatchIfTeamInvolved(
    List<Map<String, dynamic>> list,
    Map<String, dynamic> matchData,
    String docId,
    String stageName,
    String teamNumber,
  ) {
    final redTeams = (matchData['red'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];

    final blueTeams = (matchData['blue'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];

    // Check if team is in this match
    if (!redTeams.contains(teamNumber) && !blueTeams.contains(teamNumber)) {
      return;
    }

    // Extract score from match data (final score from schedule)
    final score = matchData['score'];
    int redScore = 0;
    int blueScore = 0;
    if (score is Map<String, dynamic>) {
      redScore = (score['red'] as num?)?.toInt() ?? 0;
      blueScore = (score['blue'] as num?)?.toInt() ?? 0;
    }

    // Determine match status
    String status;
    if (redScore == 0 && blueScore == 0) {
      status = 'Scheduled';
    } else {
      status = 'Completed';
    }

    list.add({
      'matchId': matchData['matchNumber']?.toString() ?? '',
      'time': matchData['time']?.toString() ?? '-',
      'redTeams': redTeams,
      'blueTeams': blueTeams,
      'redScore': redScore, // Initial score from schedule
      'blueScore': blueScore, // Initial score from schedule
      'status': status,
      'docId': docId,
      'stageName': stageName,
    });
  }
}

/// Widget to display matches for a specific stage
class _StageSection extends StatelessWidget {
  final String stageName;
  final List<Map<String, dynamic>> matches;
  final String teamNumber;
  final bool isCurrentStage;

  const _StageSection({
    required this.stageName,
    required this.matches,
    required this.teamNumber,
    required this.isCurrentStage,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Text(
                  stageName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (isCurrentStage) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Current',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...matches.map((match) => _MatchCard(
                match: match,
                teamNumber: teamNumber,
              )),
        ],
      ),
    );
  }
}

/// Widget to display a single match card
class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String teamNumber;

  const _MatchCard({
    required this.match,
    required this.teamNumber,
  });

  String _getMatchTitle(String stageName, String matchId) {
    // Convert stage name to match title format
    String title = stageName;
    
    // Handle different stage names
    if (stageName.toLowerCase().contains('qualification')) {
      title = 'Qualification';
    } else if (stageName.toLowerCase().contains('quarterfinal')) {
      title = 'Quarterfinals';
    } else if (stageName.toLowerCase().contains('semi final')) {
      title = 'Semi Finals';
    } else if (stageName.toLowerCase().contains('final') && 
               !stageName.toLowerCase().contains('semi') &&
               !stageName.toLowerCase().contains('quarter')) {
      title = 'Finals';
    } else if (stageName.toLowerCase().contains('champion')) {
      title = 'Champions of Champions';
    }
    
    return '$title Match $matchId';
  }

  @override
  Widget build(BuildContext context) {
    final redTeams = (match['redTeams'] as List)
        .map((e) => e.toString())
        .toList();
    final blueTeams = (match['blueTeams'] as List)
        .map((e) => e.toString())
        .toList();
    final String matchId = match['matchId'].toString();
    final String time = match['time'].toString();
    final String docId = match['docId'].toString();
    final String stageName = match['stageName'].toString();

    // Determine phase for fetching live scores
    // Check more specific phases first to avoid false matches
    String phase = 'qualification';
    final stageNameLower = stageName.toLowerCase();
    if (stageNameLower.contains('champion')) {
      phase = 'championofchampions';
    } else if (stageNameLower.contains('quarter')) {
      phase = 'quarterfinal';
    } else if (stageNameLower.contains('semi')) {
      phase = 'semifinal';
    } else if (stageNameLower.contains('final')) {
      phase = 'final';
    }

    // Determine division from docId (Match Schedule document ID)
    String division = 'alpha';
    final docIdLower = docId.toLowerCase();
    if (docIdLower.contains('bravo')) {
      division = 'bravo';
    } else if (docIdLower.contains('alpha')) {
      division = 'alpha';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMatchTitle(stageName, matchId),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...redTeams.map(
                (t) => _TeamChip(
                  teamNumber: t,
                  background: const Color(0xFFE53935),
                ),
              ),
              ...blueTeams.map(
                (t) => _TeamChip(
                  teamNumber: t,
                  background: const Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ScoreDisplay(
            match: match,
            teamNumber: teamNumber,
            division: division,
            phase: phase,
            redTeams: redTeams,
            blueTeams: blueTeams,
          ),
        ],
      ),
    );
  }
}

/// Widget to display scores with hybrid approach (live from Matches, final from Schedule)
class _ScoreDisplay extends StatelessWidget {
  final Map<String, dynamic> match;
  final String teamNumber;
  final String division;
  final String phase;
  final List<String> redTeams;
  final List<String> blueTeams;

  const _ScoreDisplay({
    required this.match,
    required this.teamNumber,
    required this.division,
    required this.phase,
    required this.redTeams,
    required this.blueTeams,
  });

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

  @override
  Widget build(BuildContext context) {
    final String matchId = match['matchId'].toString();
    final prefix = _buildMatchesDocPrefix(division, phase);
    final docId = '$prefix$matchId';

    // Initial scores from schedule (fallback if no live scores)
    final int initialRedScore = match['redScore'] as int;
    final int initialBlueScore = match['blueScore'] as int;

    // Always fetch from Matches collection for live updates
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Matches')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        int redScore = initialRedScore;
        int blueScore = initialBlueScore;
        String? winner;

        // Override with live scores and winner if available
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          
          // Use red_final_score_with_penalties and blue_final_score_with_penalties (primary)
          // Fallback to red_final_score and blue_final_score if penalties not available
          final liveRedScore = (data?['red_final_score_with_penalties'] as num?)?.toInt();
          final liveBlueScore = (data?['blue_final_score_with_penalties'] as num?)?.toInt();
          
          // If penalties scores exist, use them; otherwise try regular scores
          if (liveRedScore != null) {
            redScore = liveRedScore;
          } else {
            final fallbackRed = (data?['red_final_score'] as num?)?.toInt();
            if (fallbackRed != null) redScore = fallbackRed;
          }
          
          if (liveBlueScore != null) {
            blueScore = liveBlueScore;
          } else {
            final fallbackBlue = (data?['blue_final_score'] as num?)?.toInt();
            if (fallbackBlue != null) blueScore = fallbackBlue;
          }
          
          // Get winner field from document ('Red', 'Blue', or null for tie)
          winner = data?['winner'] as String?;
        } else if (snapshot.hasError) {
          // Document doesn't exist or error occurred - use initial scores
          // This is expected for matches that haven't started yet
        }

        return _buildScoreRow(
          context,
          redScore,
          blueScore,
          redTeams,
          blueTeams,
          winner,
        );
      },
    );
  }

  Widget _buildScoreRow(
    BuildContext context,
    int redScore,
    int blueScore,
    List<String> redTeams,
    List<String> blueTeams,
    String? winner,
  ) {
    final bool inRed = redTeams.contains(teamNumber);
    final bool inBlue = blueTeams.contains(teamNumber);

    String resultLabel;
    Color resultColor;

    // If no scores, match is scheduled
    if (redScore == 0 && blueScore == 0) {
      resultLabel = 'Scheduled';
      resultColor = Colors.white70;
    } else if (winner == null || winner.isEmpty) {
      // Match has scores but no winner field = actual tie/draw
      resultLabel = 'Draw';
      resultColor = Colors.white70;
    } else {
      // Use winner field to determine result ('Red' or 'Blue')
      final String winnerLower = winner.toLowerCase().trim();
      final bool redWins = winnerLower == 'red';
      final bool blueWins = winnerLower == 'blue';
      
      if (redWins && inRed) {
        resultLabel = 'Win';
        resultColor = Colors.greenAccent;
      } else if (blueWins && inBlue) {
        resultLabel = 'Win';
        resultColor = Colors.greenAccent;
      } else {
        resultLabel = 'Loss';
        resultColor = Colors.redAccent;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$redScore - $blueScore',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          resultLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: resultColor,
              ),
        ),
      ],
    );
  }
}

/// Team chip widget
class _TeamChip extends StatelessWidget {
  final String teamNumber;
  final Color background;

  const _TeamChip({
    required this.teamNumber,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        teamNumber,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
      ),
    );
  }
}

