import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/task_provider.dart';
import 'add_task_sheet.dart';
import 'task_model.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final int index;
  const TaskTile({super.key, required this.task, this.index = 0});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.task.isCompleted ? 1.0 : 0.0,
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(TaskTile old) {
    super.didUpdateWidget(old);
    if (old.task.isCompleted != widget.task.isCompleted) {
      widget.task.isCompleted
          ? _checkController.forward()
          : _checkController.reverse();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _showEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(editTask: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final task = widget.task;
    final pColor = AppTheme.priorityColor(task.priority);
    final isCompleted = task.isCompleted;

    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final completedCard = isDark
        ? AppTheme.darkCard.withOpacity(0.5)
        : Colors.grey.shade50;

    return Slidable(
          key: Key(task.id),
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) {
                  HapticFeedback.lightImpact();
                  context.read<TaskProvider>().toggleTask(task);
                },
                backgroundColor: AppTheme.lowPriority,
                foregroundColor: Colors.white,
                icon: task.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                label: task.isCompleted ? 'Undo' : 'Done',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.25,
            dismissible: DismissiblePane(
              onDismissed: () {
                HapticFeedback.mediumImpact();
                context.read<TaskProvider>().deleteTask(task.id);
                _showDeleteSnackbar(context, task.title);
              },
            ),
            children: [
              SlidableAction(
                onPressed: (_) {
                  HapticFeedback.mediumImpact();
                  context.read<TaskProvider>().deleteTask(task.id);
                  _showDeleteSnackbar(context, task.title);
                },
                backgroundColor: AppTheme.highPriority,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ],
          ),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isCompleted ? completedCard : cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted
                        ? (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                        : pColor.withOpacity(0.25),
                    width: 1,
                  ),
                  boxShadow: isCompleted
                      ? []
                      : [
                          BoxShadow(
                            color: pColor.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Priority color bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isCompleted
                                  ? [Colors.grey.shade300, Colors.grey.shade300]
                                  : [pColor, pColor.withOpacity(0.5)],
                            ),
                          ),
                        ),

                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: theme.textTheme.titleLarge!.copyWith(
                                    fontSize: 14,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationThickness: 2,
                                    color: isCompleted
                                        ? (isDark
                                              ? AppTheme.darkSubText
                                              : Colors.grey.shade400)
                                        : theme.textTheme.titleLarge?.color,
                                  ),
                                  child: Text(task.title),
                                ),

                                // Description
                                if (task.description != null &&
                                    task.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isCompleted
                                          ? Colors.grey.shade400
                                          : null,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // Badges row
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    // Priority badge
                                    _Badge(
                                      label:
                                          '${AppTheme.priorityEmoji(task.priority)} ${task.priority.toUpperCase()}',
                                      color: isCompleted
                                          ? Colors.grey.shade400
                                          : pColor,
                                    ),

                                    // Category badge
                                    if (task.category != null &&
                                        task.category!.isNotEmpty)
                                      _Badge(
                                        label: task.category!,
                                        color: isCompleted
                                            ? Colors.grey.shade400
                                            : AppTheme.secondary,
                                        icon: Icons.folder_outlined,
                                      ),

                                    // Due date badge
                                    if (task.dueDate != null)
                                      _Badge(
                                        label: _formatDue(task.dueDate!),
                                        color: isCompleted
                                            ? Colors.grey.shade400
                                            : task.isOverdue
                                            ? AppTheme.highPriority
                                            : task.isDueToday
                                            ? AppTheme.mediumPriority
                                            : (isDark
                                                  ? AppTheme.darkSubText
                                                  : AppTheme.lightSubText),
                                        icon: task.isOverdue
                                            ? Icons.warning_amber_rounded
                                            : Icons.calendar_today_rounded,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Action column: edit + check
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Edit button
                            if (!isCompleted)
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: isDark
                                      ? AppTheme.darkSubText
                                      : AppTheme.lightSubText,
                                ),
                                onPressed: _showEdit,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),

                            // Check button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.read<TaskProvider>().toggleTask(task);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isCompleted
                                        ? const LinearGradient(
                                            colors: [
                                              AppTheme.primary,
                                              AppTheme.secondary,
                                            ],
                                          )
                                        : null,
                                    color: isCompleted
                                        ? null
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isCompleted
                                          ? Colors.transparent
                                          : (isDark
                                                ? AppTheme.darkBorder
                                                : Colors.grey.shade300),
                                      width: 2,
                                    ),
                                    boxShadow: isCompleted
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: ScaleTransition(
                                    scale: _checkScale,
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.index * 50),
          duration: 300.ms,
        )
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
  }

  String _formatDue(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(d.year, d.month, d.day);
    if (due == today) return 'Today';
    if (due == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (due == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('d MMM').format(d);
  }

  void _showDeleteSnackbar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$title" deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Badge widget
// ──────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
