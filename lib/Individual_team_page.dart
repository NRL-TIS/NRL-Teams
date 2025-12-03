// ignore_for_file: unused_local_variable
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'individual_match.dart';
import 'package:url_launcher/url_launcher.dart';

// import 'Matchschedule.dart';

class _TeamMatchesCard extends StatelessWidget {
  final String teamNumber;

  const _TeamMatchesCard({required this.teamNumber});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Match Schedule',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          IndividualMatchSchedule(teamNumber: teamNumber),
        ],
      ),
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

String? _readOptionalString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;

  final s = value.toString().trim();
  if (s.isEmpty) return null;

  return s;
}

class TeamDetailPage extends StatelessWidget {
  final String teamNumber;
  final String teamDocId;

  const TeamDetailPage({
    super.key,
    required this.teamNumber,
    required this.teamDocId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          'Back to Dashboard',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('teams')
                .doc(teamDocId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading team details',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No details found for team $teamNumber',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final teamName =
              (data['teamName'] ?? data['name'] ?? 'Team $teamNumber')
                  .toString();
          final teamType = (data['teamType'] ?? data['type'])?.toString();
          final location = (data['cityState'] ?? data['city'])?.toString();

          final leaguePosition =
              (data['leaguePosition'] ?? data['rank'])?.toString();
          final autoScore =
              (data['autonomousScore'] ?? data['autoScore'])?.toString();

          final details = data['details']?.toString() ?? '';

          final int redCardCount = (data['redCardCount'] as num?)?.toInt() ?? 0;
          final int yellowCardCount =
              (data['yellowCards'] as num?)?.toInt() ?? 0;

          final String? robotName = _readOptionalString(data, 'robotName');
          final String? schoolName = _readOptionalString(data, 'schoolName');
          final String? teamTagline = _readOptionalString(data, 'teamTagline');
          final String? instaLink = _readOptionalString(data, 'instaLink');
          final String? groupPhotoStorageUrl = _readOptionalString(
            data,
            'groupPhotoStorageUrl',
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;

              if (isWide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _TeamInfoCard(
                          teamName: teamName,
                          teamNumber: teamNumber,
                          teamType: teamType,
                          location: location,
                          details: details,
                          redCardCount: redCardCount,
                          yellowCardCount: yellowCardCount,
                          robotName: robotName,
                          schoolName: schoolName,
                          teamTagline: teamTagline,
                          instaLink: instaLink,
                          groupPhotoStorageUrl:
                              groupPhotoStorageUrl, 
                        ),
                      ),
                      const SizedBox(width: 24),

                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('Rankings')
                                      .snapshots(),
                              builder: (context, rankingsSnap) {
                                String? leaguePosFromRankings;

                                if (rankingsSnap.hasData) {
                                  for (final doc in rankingsSnap.data!.docs) {
                                    final map = doc.data();
                                    final entry = map[teamNumber];
                                    if (entry is Map<String, dynamic>) {
                                      final prevRank =
                                          (entry['previousRank'] as num?)
                                              ?.toInt();
                                      if (prevRank != null) {
                                        leaguePosFromRankings =
                                            prevRank.toString();
                                        break;
                                      }
                                    }
                                  }
                                }

                                return _StandingsCard(
                                  leaguePosition: leaguePosFromRankings,
                                  autoScore: autoScore,
                                  accent: cs.primary,
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            _TeamMatchesCard(teamNumber: teamNumber),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TeamInfoCard(
                        teamName: teamName,
                        teamNumber: teamNumber,
                        teamType: teamType,
                        location: location,
                        details: details,
                        redCardCount: redCardCount,
                        yellowCardCount: yellowCardCount,
                        robotName: robotName,
                        schoolName: schoolName,
                        teamTagline: teamTagline,
                        instaLink: instaLink,
                        groupPhotoStorageUrl:
                            groupPhotoStorageUrl,

                      ),

                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('Rankings')
                                .snapshots(),
                        builder: (context, rankingsSnap) {
                          String? leaguePosFromRankings;

                          if (rankingsSnap.hasData) {
                            for (final doc in rankingsSnap.data!.docs) {
                              final map = doc.data();
                              final entry = map[teamNumber];
                              if (entry is Map<String, dynamic>) {
                                final prevRank =
                                    (entry['previousRank'] as num?)?.toInt();
                                if (prevRank != null) {
                                  leaguePosFromRankings = prevRank.toString();
                                  break;
                                }
                              }
                            }
                          }

                          return _StandingsCard(
                            leaguePosition: leaguePosFromRankings,
                            autoScore: autoScore,
                            accent: cs.primary,
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      _TeamMatchesCard(teamNumber: teamNumber),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _TeamInfoCard extends StatelessWidget {
  final String teamName;
  final String teamNumber;
  final String? teamType;
  final String? location;
  final String details;

  final int redCardCount;
  final int yellowCardCount;

  
  final String? robotName;
  final String? schoolName;
  final String? teamTagline;
  final String? instaLink;
  final String? groupPhotoStorageUrl;

  const _TeamInfoCard({
    required this.teamName,
    required this.teamNumber,
    required this.teamType,
    required this.location,
    required this.details,
    required this.redCardCount,
    required this.yellowCardCount,
    this.robotName,
    this.schoolName,
    this.teamTagline,
    this.instaLink,
    this.groupPhotoStorageUrl,
  });
  String _extractInstagramUsername(String rawLink) {
    String link = rawLink.trim();

    
    if (!link.startsWith('http')) {
      if (link.startsWith('@')) {
        link = link.substring(1);
      }
      return link;
    }

    
    try {
      final uri = Uri.parse(link);
      final seg = uri.pathSegments.firstWhere(
        (s) => s.isNotEmpty,
        orElse: () => '',
      );
      return seg;
    } catch (_) {
      link = link.replaceAll('https://', '').replaceAll('http://', '');
      final idx = link.indexOf('instagram.com/');
      if (idx != -1) {
        final after = link.substring(idx + 'instagram.com/'.length);
        final parts = after.split('/');
        return parts.firstWhere((s) => s.isNotEmpty, orElse: () => '');
      }
      return link;
    }
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool italicValue = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle:
                          italicValue ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstagramRow(BuildContext context, String rawLink) {
    final cs = Theme.of(context).colorScheme;

    final username = _extractInstagramUsername(rawLink);
    if (username.isEmpty) {
      return const SizedBox.shrink();
    }

    final Uri uri;
    if (rawLink.startsWith('http')) {
      uri = Uri.parse(rawLink);
    } else {
      uri = Uri.parse('https://instagram.com/$username');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          try {
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              debugPrint('Could not launch $uri');
            }
          } catch (e) {
            debugPrint('Error launching $uri: $e');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.alternate_email, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instagram',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 16, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  
  static Future<String?> _loadTeamLogo(String rawTeamNumber) async {
    final teamNumber = rawTeamNumber.trim();

    final storage = FirebaseStorage.instance;
    const exts = ['png', 'jpg', 'jpeg', 'jfif', 'webp'];

    for (final ext in exts) {
      final path = 'team_logos/$teamNumber.$ext';
      try {
        debugPrint('🔎 Trying logo: $path');
        final ref = storage.ref().child(path);
        final url = await ref.getDownloadURL();
        debugPrint('✅ Found logo for $teamNumber at $path');
        return url; // found a working extension
      } on FirebaseException catch (e) {
        debugPrint('❌ No logo for $path: ${e.code}');
      } catch (e) {
        debugPrint('⚠️ Unexpected error while loading $path: $e');
      }
    }

    debugPrint(
      'ℹ️ No logo found for team $teamNumber with any known extension.',
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
       
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            
              FutureBuilder<String?>(
                future: _TeamInfoCard._loadTeamLogo(teamNumber),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 22,
                        color: Colors.white38,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                      '❗ Error getting download URL for $teamNumber: ${snapshot.error}',
                    );
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.groups,
                        size: 22,
                        color: Colors.white54,
                      ),
                    );
                  }

                  final url = snapshot.data;
                  if (url == null || url.isEmpty) {
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.groups,
                        size: 22,
                        color: Colors.white54,
                      ),
                    );
                  }

                  debugPrint('🌐 Loading logo image for $teamNumber: $url');
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      url,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white38,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          '🚫 Error displaying logo image for $teamNumber: $error',
                        );
                        return Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.groups,
                            size: 22,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(width: 16),

    
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        teamName,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),

         
                    if (redCardCount > 0)
                      Row(
                        children: List.generate(
                          redCardCount,
                          (_) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 8,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                    if (redCardCount > 0 && yellowCardCount > 0)
                      const SizedBox(width: 4),

                    
                    if (yellowCardCount > 0)
                      Row(
                        children: List.generate(
                          yellowCardCount,
                          (_) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 8,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'Team #$teamNumber',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),

         
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Type',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamType?.isNotEmpty == true ? teamType! : '—',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location?.isNotEmpty == true ? location! : '—',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 16),

         
          Text(
            'Team Details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          Builder(
            builder: (context) {
              final rn = robotName;
              final sn = schoolName;
              final tag = teamTagline;
              final ig = instaLink;

         
              final hasAnyDetail = [
                rn,
                sn,
                tag,
                ig,
              ].any((v) => v != null && v.isNotEmpty);

              if (!hasAnyDetail) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rn != null && rn.isNotEmpty)
                      _buildDetailRow(
                        context,
                        icon: Icons.smart_toy_outlined,
                        label: 'Robot Name',
                        value: rn,
                      ),
                    if (sn != null && sn.isNotEmpty)
                      _buildDetailRow(
                        context,
                        icon: Icons.school_outlined,
                        label: 'School / Institute',
                        value: sn,
                      ),
                    if (tag != null && tag.isNotEmpty)
                      _buildDetailRow(
                        context,
                        icon: Icons.chat_bubble_outline,
                        label: 'Team Tagline',
                        value: tag,
                        italicValue: true,
                      ),
                    if (ig != null && ig.isNotEmpty)
                      _buildInstagramRow(context, ig),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 8),

          // ───────────────────── BIG TEAM LOGO (CONSISTENT SIZE) ─────────────────────
          // Center(
          //   child: FutureBuilder<String?>(
          //     future: _TeamInfoCard._loadTeamLogo(teamNumber),
          //     builder: (context, snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
          //         return Container(
          //           width: 220,
          //           height: 220,
          //           decoration: BoxDecoration(
          //             color: Colors.white10,
          //             borderRadius: BorderRadius.circular(24),
          //             border: Border.all(color: Colors.white.withOpacity(0.12)),
          //           ),
          //           child: const Center(
          //             child: CircularProgressIndicator(strokeWidth: 2),
          //           ),
          //         );
          //       }

          //       if (snapshot.hasError ||
          //           snapshot.data == null ||
          //           snapshot.data!.isEmpty) {
          //         // Fallback if logo missing or error
          //         return Container(
          //           width: 220,
          //           height: 220,
          //           decoration: BoxDecoration(
          //             color: Colors.white10,
          //             borderRadius: BorderRadius.circular(24),
          //             border: Border.all(color: Colors.white.withOpacity(0.12)),
          //           ),
          //           child: const Icon(
          //             Icons.groups,
          //             size: 72,
          //             color: Colors.white54,
          //           ),
          //         );
          //       }

          //       final url = snapshot.data!;
          //       debugPrint('🌐 Loading BIG logo image for $teamNumber: $url');

          //       return Container(
          //         width: 220,
          //         height: 220,
          //         decoration: BoxDecoration(
          //           color: Colors.white10,
          //           borderRadius: BorderRadius.circular(24),
          //           border: Border.all(color: Colors.white.withOpacity(0.12)),
          //         ),
          //         child: ClipRRect(
          //           borderRadius: BorderRadius.circular(24),
          //           child: Image.network(
          //             url,
          //             fit: BoxFit.contain, // 👈 keeps full logo, consistent box
          //             loadingBuilder: (context, child, loadingProgress) {
          //               if (loadingProgress == null) return child;
          //               return const Center(
          //                 child: CircularProgressIndicator(
          //                   strokeWidth: 2,
          //                   valueColor: AlwaysStoppedAnimation<Color>(
          //                     Colors.white38,
          //                   ),
          //                 ),
          //               );
          //             },
          //             errorBuilder: (context, error, stackTrace) {
          //               debugPrint(
          //                 '🚫 Error displaying BIG logo for $teamNumber: $error',
          //               );
          //               return const Center(
          //                 child: Icon(
          //                   Icons.groups,
          //                   size: 72,
          //                   color: Colors.white54,
          //                 ),
          //               );
          //             },
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // ───────────────────── GROUP PHOTO (FROM FIRESTORE URL) ─────────────────────
          if (groupPhotoStorageUrl != null && groupPhotoStorageUrl!.isNotEmpty)
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    groupPhotoStorageUrl!,
                    fit: BoxFit.cover, 
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white38,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                        '🚫 Error displaying group photo for $teamNumber: $error',
                      );
                      return const Center(
                        child: Icon(
                          Icons.groups,
                          size: 72,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandingsCard extends StatelessWidget {
  final String? leaguePosition;
  final String? autoScore;
  final Color accent;

  const _StandingsCard({
    required this.leaguePosition,
    required this.autoScore,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: accent),
              const SizedBox(width: 8),
              Text(
                'Standings',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'League Position',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            leaguePosition != null ? '#$leaguePosition' : '—',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Autonomous Score',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            autoScore != null ? '$autoScore pts' : '—',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
