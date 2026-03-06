import 'dart:ui';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../utils/connectivity_banner.dart';
import 'add_task_sheet.dart';
import 'task_model.dart';
import 'task_tile.dart';

// ──────────────────────────────────────────────────────────────
// Dashboard Screen
// ──────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _fabController;
  late final Animation<double> _fabRotation;
  final _searchCtrl = TextEditingController();
  bool _searchFocused = false;
  bool _didFireConfetti = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddTaskSheet({Task? editTask}) {
    _fabController.forward();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(editTask: editTask),
    ).whenComplete(() {
      if (mounted) _fabController.reverse();
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good Night';
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TaskProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = auth.currentUser;
    final meta = user?.userMetadata;
    final fullName = meta?['full_name'] as String?;
    final email = user?.email;
    final userName =
        fullName?.split(' ').first ?? email?.split('@').first ?? 'User';
    final avatarUrl = meta?['avatar_url'] as String?;

    if (tp.allDone && !_didFireConfetti) {
      _didFireConfetti = true;
      _confetti.play();
    } else if (!tp.allDone) {
      _didFireConfetti = false;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          ConnectivityBanner(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  floating: false,
                  toolbarHeight: kToolbarHeight,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _GlassHeader(
                      greeting: _greeting,
                      userName: userName,
                      avatarUrl: avatarUrl,
                      tp: tp,
                      isDark: isDark,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Toggle Theme',
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          AdaptiveTheme.of(context).toggleThemeMode(),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      icon: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppTheme.highPriority,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tp.totalTasks > 0)
                          _ProgressSection(tp: tp, isDark: isDark)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 12),

                        Focus(
                          onFocusChange: (f) =>
                              setState(() => _searchFocused = f),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: tp.setSearch,
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              prefixIcon: Icon(
                                _searchFocused
                                    ? Icons.search_rounded
                                    : Icons.search_outlined,
                                color: _searchFocused
                                    ? AppTheme.primary
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        tp.setSearch('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                        const SizedBox(height: 12),
                        _FilterBar(
                          tp: tp,
                          isDark: isDark,
                        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                _TaskListSliver(
                  tp: tp,
                  isDark: isDark,
                  theme: theme,
                  onAddTask: _showAddTaskSheet,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                AppTheme.primary,
                AppTheme.secondary,
                AppTheme.lowPriority,
                AppTheme.mediumPriority,
                AppTheme.urgentPriority,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: RotationTransition(
        turns: _fabRotation,
        child: FloatingActionButton(
          onPressed: () => _showAddTaskSheet(),
          backgroundColor: AppTheme.primary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Glass Header
// ──────────────────────────────────────────────────────────────
class _GlassHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final String? avatarUrl;
  final TaskProvider tp;
  final bool isDark;

  const _GlassHeader({
    required this.greeting,
    required this.userName,
    this.avatarUrl,
    required this.tp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [AppTheme.primary, AppTheme.secondary],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        // Use Align to anchor widget content to the bottom.
        // This avoids conflicts with the SliverAppBar action buttons
        // that are drawn on top, without needing a fixed-height spacer.
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting row
                Row(
                  children: [
                    _AvatarWidget(url: avatarUrl, name: userName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$greeting, $userName 👋',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: tp.totalTasks,
                      icon: Icons.list_rounded,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      label: 'Pending',
                      value: tp.pendingTasks,
                      icon: Icons.hourglass_empty_rounded,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      label: 'Done',
                      value: tp.completedTasks,
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String? url;
  final String name;
  const _AvatarWidget({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: ClipOval(
        child: (url != null && url!.isNotEmpty)
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _circle(name),
              )
            : _circle(name),
      ),
    );
  }

  Widget _circle(String n) => Container(
    color: Colors.white.withOpacity(0.2),
    alignment: Alignment.center,
    child: Text(
      n.isNotEmpty ? n[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$value',
                key: ValueKey(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Progress Section
// ──────────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final TaskProvider tp;
  final bool isDark;
  const _ProgressSection({required this.tp, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rate = tp.completionRate;
    final pct = (rate * 100).toInt();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              Text(
                '${tp.completedTasks}/${tp.totalTasks} — $pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkSubText : AppTheme.lightSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rate),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
                valueColor: AlwaysStoppedAnimation<Color>(
                  v == 1.0 ? AppTheme.lowPriority : AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Filter Bar
// ──────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final TaskProvider tp;
  final bool isDark;
  const _FilterBar({required this.tp, required this.isDark});

  String _label(TaskFilter f) {
    switch (f) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.pending:
        return 'Pending';
      case TaskFilter.completed:
        return 'Completed';
      case TaskFilter.highPriority:
        return '🔥 High';
      case TaskFilter.today:
        return '📅 Today';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskFilter.values.map((f) {
          final sel = tp.currentFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_label(f)),
              selected: sel,
              onSelected: (_) => tp.setFilter(f),
              backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: sel ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              elevation: sel ? 4 : 0,
              shadowColor: AppTheme.primary.withOpacity(0.3),
              side: BorderSide(
                color: sel
                    ? AppTheme.primary
                    : (isDark ? AppTheme.darkBorder : Colors.grey.shade300),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Task List Sliver
// ──────────────────────────────────────────────────────────────
class _TaskListSliver extends StatelessWidget {
  final TaskProvider tp;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onAddTask;

  const _TaskListSliver({
    required this.tp,
    required this.isDark,
    required this.theme,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    if (tp.isLoading && tp.allTasks.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _ShimmerTile(isDark: isDark),
          childCount: 5,
        ),
      );
    }

    final sorted = tp.sortedTasks;
    if (sorted.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(isDark: isDark, onAddTask: onAddTask),
      );
    }

    final urgent = sorted
        .where((t) => t.priority == 'urgent' && !t.isCompleted)
        .toList();
    final today = sorted
        .where((t) => t.isDueToday && !t.isCompleted && t.priority != 'urgent')
        .toList();
    final rest = sorted
        .where((t) => !urgent.contains(t) && !today.contains(t))
        .toList();

    final sections = <Widget>[];
    int idx = 0;

    if (urgent.isNotEmpty) {
      sections.add(
        _SectionHeader(title: '🔥 Urgent', isDark: isDark, index: idx++),
      );
      for (final t in urgent) {
        sections.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TaskTile(task: t, index: idx++),
          ),
        );
      }
    }
    if (today.isNotEmpty) {
      sections.add(
        _SectionHeader(title: "📅 Today's Focus", isDark: isDark, index: idx++),
      );
      for (final t in today) {
        sections.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TaskTile(task: t, index: idx++),
          ),
        );
      }
    }
    if (rest.isNotEmpty) {
      if (urgent.isNotEmpty || today.isNotEmpty) {
        sections.add(
          _SectionHeader(title: 'All Tasks', isDark: isDark, index: idx++),
        );
      }
      for (final t in rest) {
        sections.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: TaskTile(task: t, index: idx++),
          ),
        );
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => sections[i],
        childCount: sections.length,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final int index;
  const _SectionHeader({
    required this.title,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: isDark ? AppTheme.darkSubText : AppTheme.lightSubText,
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: index * 40),
      duration: 300.ms,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Empty State
// ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddTask;
  const _EmptyState({required this.isDark, required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 80,
                color: AppTheme.primary.withOpacity(0.15),
              ),
              const SizedBox(height: 20),
              Text(
                '🎉 No Tasks Today!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You're all caught up.\nAdd a new task to stay productive.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? AppTheme.darkSubText : AppTheme.lightSubText,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Task'),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

// ──────────────────────────────────────────────────────────────
// Shimmer Skeleton
// ──────────────────────────────────────────────────────────────
class _ShimmerTile extends StatelessWidget {
  final bool isDark;
  const _ShimmerTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppTheme.darkCard : Colors.grey.shade200;
    final shine = isDark ? const Color(0xFF475569) : Colors.grey.shade50;
    return Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(14),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: const Duration(milliseconds: 1200), color: shine);
  }
}
