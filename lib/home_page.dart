// ignore_for_file: unused_element_parameter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Individual_team_page.dart';
import 'package:flutter/material.dart';
import 'otherpages.dart';
import 'Matchschedule.dart';
import 'livetracker_page.dart';
import 'League_leaderboard.dart';
import 'Autonomous_leaderboard.dart';
import 'package:url_launcher/url_launcher.dart';

const double kDesktopCardHeight = 172;
const double kMobileSoloCardHeight = 112;

enum NrlSection {
  home,
  eventMap,
  matchSchedule,
  liveTracker,
  leagueLeaderboard,
  autonomousLeaderboard,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const double _mobileMax = 600;
  static const double _tabletMax = 1024;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  NrlSection _currentSection = NrlSection.home;
  bool _isSectionTitleHovered = false;
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final clamped = mq.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
    );

    return MediaQuery(
      data: mq.copyWith(textScaler: clamped),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final isMobile = w < HomePage._mobileMax;
          final isTablet = w >= HomePage._mobileMax && w < HomePage._tabletMax;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0.5,
              shadowColor: Colors.white.withOpacity(0.06),
              toolbarHeight: isMobile ? 100 : 110,
              centerTitle: false,
              titleSpacing: isMobile ? 8 : 12,
              leadingWidth: isMobile ? 56 : 80,
              leading: Padding(
                padding: EdgeInsets.only(left: isMobile ? 8 : 16),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: _BrandIcon(),
                ),
              ),

              // 🔹 Different title layouts for mobile vs laptop
              title: LayoutBuilder(
                builder: (_, cc) {
                  if (isMobile) {
                    // ----- MOBILE APPBAR TITLE -----
                    return SizedBox(
                      width: cc.maxWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Text block on the left (3 lines)
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'National Robotics',
                                    maxLines: 1,
                                    // you can also remove overflow if you want:
                                    // overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'League',
                                    maxLines: 1,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Championship Portal',
                                    maxLines: 1,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Images on the extreme right
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // small oboc.png
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 54,
                                ), // increase to 12, 16, etc.
                                child: Image.asset(
                                  'assets/oboc.png',
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // bigger o360o.png, tall enough to visually span lines 2 & 3
                              Image.asset(
                                'assets/o360o.png',
                                height: 50, // tweak 36–48 as per how it looks
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    // ----- LAPTOP / DESKTOP APPBAR TITLE -----
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'National Robotics League',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Championship Portal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              // 🔹 Actions: only on laptop/desktop, boc.png ~1.25x
              actions:
                  isMobile
                      ? []
                      : [
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SizedBox(
                            // make this ~1.25x your old size
                            height: 62,
                            width: 150,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.asset('assets/boc.png'),
                            ),
                          ),
                        ),
                      ],

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Divider(
                  height: 0.5,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            body: SafeArea(
              child: _buildBody(isMobile: isMobile, isTablet: isTablet),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({required bool isMobile, required bool isTablet}) {
    if (_currentSection == NrlSection.home) {
      return _buildHomeDashboard(isMobile: isMobile, isTablet: isTablet);
    }

    late final String sectionTitle;
    late final Widget sectionChild;

    switch (_currentSection) {
      case NrlSection.eventMap:
        sectionTitle = 'Event Map';
        sectionChild = const EventMapPage();
        break;
      case NrlSection.matchSchedule:
        sectionTitle = 'Match Schedule';
        sectionChild = const MatchSchedulePage();
        break;
      case NrlSection.liveTracker:
        sectionTitle = 'Checklist';
        sectionChild = const LiveTrackerPage();
        break;
      case NrlSection.leagueLeaderboard:
        sectionTitle = 'League Leaderboard';
        sectionChild = const LeagueLeaderboardPage();
        break;
      case NrlSection.autonomousLeaderboard:
        sectionTitle = 'Autonomous Leaderboard';
        sectionChild = const AutonomousLeaderboardPage();
        break;
      case NrlSection.home:
        sectionTitle = '';
        sectionChild = const SizedBox.shrink();
        break;
    }

    final horizontalPad = isMobile ? 16.0 : 24.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 1200.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isMobile ? 12 : 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  setState(() {
                    _currentSection = NrlSection.home;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _isSectionTitleHovered = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _isSectionTitleHovered = false;
                        });
                      },
                      child: Text(
                        sectionTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,

                          color:
                              _isSectionTitleHovered
                                  ? Colors.pinkAccent
                                  : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  isMobile ? 6.0 : 16.0,
                  0,
                  isMobile ? 6.0 : 16.0,
                  isMobile ? 12.0 : 20.0,
                ),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.95),

                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 1,
                  ),
                ),
                child: sectionChild,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard({required bool isMobile, required bool isTablet}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 1200.0,
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 16 : 24,
          ),
          children: [
            Text(
              'Find Your Team',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const _SearchBar(),

            const SizedBox(height: 28),

            Center(
              child: Text(
                'Quick Access',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            if (!isMobile && !isTablet) ...[
              Row(
                children: [
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.map_outlined,
                      label: 'Event Map',
                      onTap:
                          () => setState(
                            () => _currentSection = NrlSection.eventMap,
                          ),
                      height: kDesktopCardHeight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.event_note_outlined,
                      label: 'Match Schedule',
                      onTap:
                          () => setState(
                            () => _currentSection = NrlSection.matchSchedule,
                          ),
                      height: kDesktopCardHeight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.checklist,
                      label: 'Checklist',
                      onTap:
                          () => setState(
                            () => _currentSection = NrlSection.liveTracker,
                          ),
                      height: kDesktopCardHeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.emoji_events_outlined,
                      label: 'League Leaderboard',
                      onTap:
                          () => setState(
                            () =>
                                _currentSection = NrlSection.leagueLeaderboard,
                          ),
                      height: kDesktopCardHeight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickCard(
                      icon: Icons.auto_mode_outlined,
                      label: 'Autonomous Leaderboard',
                      onTap:
                          () => setState(
                            () =>
                                _currentSection =
                                    NrlSection.autonomousLeaderboard,
                          ),
                      height: kDesktopCardHeight,
                    ),
                  ),
                ],
              ),
            ] else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 1.2 : 1.4,
                children: [
                  _QuickCard(
                    icon: Icons.map_outlined,
                    label: 'Event Map',
                    onTap:
                        () => setState(
                          () => _currentSection = NrlSection.eventMap,
                        ),
                  ),
                  _QuickCard(
                    icon: Icons.event_note_outlined,
                    label: 'Match Schedule',
                    onTap:
                        () => setState(
                          () => _currentSection = NrlSection.matchSchedule,
                        ),
                  ),
                  _QuickCard(
                    icon: Icons.checklist,
                    label: 'Checklist',
                    onTap:
                        () => setState(
                          () => _currentSection = NrlSection.liveTracker,
                        ),
                  ),
                  _QuickCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'League Leaderboard',
                    onTap:
                        () => setState(
                          () => _currentSection = NrlSection.leagueLeaderboard,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _QuickCard(
                icon: Icons.auto_mode_outlined,
                label: 'Autonomous Leaderboard',
                onTap:
                    () => setState(
                      () => _currentSection = NrlSection.autonomousLeaderboard,
                    ),
                height: kMobileSoloCardHeight,
              ),
            ],

            const SizedBox(height: 28),

            _InfoHero(isMobile: isMobile),
            const SizedBox(height: 36),

            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/nrl_logo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({super.key});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  String _searchTerm = '';
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_focusNode.hasFocus) return;

    final next = _controller.text.trim();
    if (next == _searchTerm) return;

    setState(() => _searchTerm = next);
    _runSearch();
  }

  Future<void> _runSearch() async {
    final q = _searchTerm;
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() => _suggestions = []);
      _updateOverlay();
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance.collection('teams').get();

      String normalize(String s) {
        final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.replaceFirst(RegExp(r'^0+'), '');
      }

      final normalizedQ = normalize(q);
      if (normalizedQ.isEmpty) {
        if (!mounted) return;
        setState(() => _suggestions = []);
        _updateOverlay();
        return;
      }

      final List<String> matches = [];
      for (final doc in snap.docs) {
        final id = doc.id.toString();
        final normId = normalize(id);

        if (normId.contains(normalizedQ)) {
          matches.add(id);
          if (matches.length >= 8) break;
        }
      }

      if (!mounted) return;
      setState(() {
        _suggestions = matches;
      });
      _updateOverlay();
    } catch (_) {}
  }

  void _openTeam(String teamNumber) {
    _focusNode.unfocus();
    _controller.text = teamNumber;

    setState(() {
      _searchTerm = '';
      _suggestions = [];
    });
    _removeOverlay();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) =>
                TeamDetailPage(teamNumber: teamNumber, teamDocId: teamNumber),
      ),
    );
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a team number')));
      return;
    }
    _openTeam(q);
  }

  void _updateOverlay() {
    if (_searchTerm.isEmpty) {
      _removeOverlay();
      return;
    }

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (overlayContext) {
        final renderBox =
            _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          return const SizedBox.shrink();
        }

        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);
        final hasResults = _suggestions.isNotEmpty;

        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 4,
          width: size.width,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(overlayContext).cardColor.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child:
                    hasResults
                        ? ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          physics: const ClampingScrollPhysics(),
                          separatorBuilder:
                              (_, __) => Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                          itemBuilder: (context, index) {
                            final teamNumber = _suggestions[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                teamNumber,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                _openTeam(teamNumber);
                              },
                            );
                          },
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            'No results',
                            style: Theme.of(overlayContext).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < HomePage._mobileMax; // 👈 NEW

    return Container(
      key: _fieldKey,
      child: LayoutBuilder(
        builder: (context, c) {
          final wrap = c.maxWidth < 420;

          final input = TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Find your team by team number...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _submit(),
          );

          // 👇 On mobile: show ONLY the input (no Search button)
          if (isMobile) {
            return input;
          }

          // 👇 On tablet/desktop: keep existing button behaviour
          final button = SizedBox(
            height: wrap ? 40 : 44,
            child: FilledButton(
              onPressed: _submit,
              child: const Text(
                'Search',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );

          if (wrap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                input,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: input),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _QuickCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? height;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.height,
    super.key,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _hover = true;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final double inferredMinHeight = w >= 1024 ? 168 : (w >= 600 ? 140 : 132);

    final double targetHeight = widget.height ?? inferredMinHeight;

    final bool compact = targetHeight <= 120;

    final double vPad = compact ? 8.0 : 16.0;
    final double iconSz = compact ? 22.0 : 30.0;
    final double spacing = compact ? 6.0 : 10.0;
    final double txtSize =
        compact
            ? 13.0
            : (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16);

    final inner = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: vPad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow:
            _hover
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
                : const [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: iconSz,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: spacing),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: txtSize,
              ),
            ),
          ),
        ],
      ),
    );

    final child = ConstrainedBox(
      constraints: BoxConstraints(minHeight: targetHeight),
      child: inner,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}

class _InfoHero extends StatelessWidget {
  final bool isMobile;
  const _InfoHero({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dim = Colors.white.withOpacity(0.75);

    Widget meta() {
      final styleValue = Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);
      if (isMobile) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'December 2025',
              style: styleValue,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text('IIT Bombay', style: styleValue, textAlign: TextAlign.center),
          ],
        );
      }
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('December 2025', style: styleValue),
          Text(
            '•',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: dim),
          ),
          Text('IIT Bombay', style: styleValue),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'National Robotics League Championship 2025',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'India\'s Biggest Robotics Championship for Middle & High School Students',
          textAlign: TextAlign.center,
          softWrap: true,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 16),
        meta(),
      ],
    );
  }
}

class _Footer extends StatefulWidget {
  const _Footer({super.key});

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  bool _isHovering = false;

  Future<void> _launchNrlSite() async {
    final uri = Uri.parse('https://nrl.theinnovationstory.com/');

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open NRL website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),
          Text(
            'National Robotics League Championship 2025',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Organized by The Innovation Story | IIT Bombay',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 4),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: _launchNrlSite,
              child: Text(
                'Visit NRL Website',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isHovering ? Colors.white : cs.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            '© 2025 All Rights Reserved',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
