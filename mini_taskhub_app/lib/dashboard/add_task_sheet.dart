import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/task_provider.dart';
import '../utils/validators.dart';
import 'task_model.dart';

class AddTaskSheet extends StatefulWidget {
  final Task? editTask;
  const AddTaskSheet({super.key, this.editTask});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late String _priority;
  late String? _category;
  DateTime? _dueDate;

  bool get _isEditing => widget.editTask != null;

  static const _priorities = ['low', 'medium', 'high', 'urgent'];
  static const _categories = [
    'General',
    'Work',
    'Study',
    'Personal',
    'Shopping',
    'Fitness',
    'Health',
  ];

  final _priorityColors = {
    'low': AppTheme.lowPriority,
    'medium': AppTheme.mediumPriority,
    'high': AppTheme.highPriority,
    'urgent': AppTheme.urgentPriority,
  };

  @override
  void initState() {
    super.initState();
    final e = widget.editTask;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _priority = e?.priority ?? 'medium';
    _category = e?.category ?? 'General';
    _dueDate = e?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final provider = context.read<TaskProvider>();
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

    if (_isEditing) {
      await provider.editTask(
        widget.editTask!,
        title: title,
        description: desc,
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      );
    } else {
      await provider.addTask(
        title,
        desc,
        _priority,
        category: _category,
        dueDate: _dueDate,
      );
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.watch<TaskProvider>().isLoading;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Task' : 'New Task',
                    style: theme.textTheme.displaySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleCtrl,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.requiredValidator(v, 'Title'),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // Priority
              Text('Priority', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              Row(
                children: _priorities.map((p) {
                  final color = _priorityColors[p]!;
                  final selected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _priority = p),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : (isDark
                                        ? AppTheme.darkBorder
                                        : Colors.grey.shade300),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppTheme.priorityEmoji(p),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? color
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Category + Due Date row
              Row(
                children: [
                  // Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(Icons.folder_outlined, size: 18),
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _category = v),
                          dropdownColor: cardBg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Due Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Due Date', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : Colors.white,
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: _dueDate != null
                                      ? AppTheme.primary
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _dueDate != null
                                        ? DateFormat('d MMM').format(_dueDate!)
                                        : 'No date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _dueDate != null
                                          ? AppTheme.primary
                                          : theme.textTheme.bodyMedium?.color,
                                      fontWeight: _dueDate != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_dueDate != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _dueDate = null),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isEditing
                              ? Icons.save_rounded
                              : Icons.add_task_rounded,
                        ),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 350.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
