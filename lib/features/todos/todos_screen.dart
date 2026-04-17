// lib/features/todos/todos_screen.dart
// Author: Jeffry Tambunan | IFS23032
// PAM Praktikum 8 - Flutter Authentication
//
// [Improvement] Filter todo (semua / selesai / belum) + pagination scroll.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final token = context.read<AuthProvider>().authToken ?? '';
      context.read<TodoProvider>().loadMoreTodos(authToken: token);
    }
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken;
    if (token != null) context.read<TodoProvider>().loadTodos(authToken: token);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final token = context.read<AuthProvider>().authToken ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Todo Saya',
        withSearch: true,
        searchHint: 'Cari todo...',
        onSearchChanged: (query) {
          context.read<TodoProvider>().updateSearchQuery(query);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(RouteConstants.todosAdd).then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          // ── Filter Chips ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipItem(
                    label: 'Semua (${provider.totalTodos})',
                    selected: provider.filter == TodoFilter.all,
                    onSelected: (_) =>
                        context.read<TodoProvider>().setFilter(TodoFilter.all),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Selesai (${provider.doneTodos})',
                    selected: provider.filter == TodoFilter.done,
                    onSelected: (_) =>
                        context.read<TodoProvider>().setFilter(TodoFilter.done),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Belum (${provider.pendingTodos})',
                    selected: provider.filter == TodoFilter.pending,
                    onSelected: (_) => context
                        .read<TodoProvider>()
                        .setFilter(TodoFilter.pending),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Content ───────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: switch (provider.status) {
                TodoStatus.loading || TodoStatus.initial =>
                  const LoadingWidget(message: 'Memuat todo...'),
                TodoStatus.error => AppErrorWidget(
                    message: provider.errorMessage, onRetry: _loadData),
                _ => provider.todos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada todo.\nKetuk + untuk menambahkan.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: provider.todos.length +
                            (provider.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          // Loading indicator di akhir list (pagination)
                          if (i == provider.todos.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final todo = provider.todos[i];
                          return _TodoCard(
                            todo: todo,
                            onTap: () => context
                                .push(RouteConstants.todosDetail(todo.id))
                                .then((_) => _loadData()),
                            onToggle: () async {
                              final success = await provider.editTodo(
                                authToken: token,
                                todoId: todo.id,
                                title: todo.title,
                                description: todo.description,
                                isDone: !todo.isDone,
                              );
                              if (!success && mounted) {
                                showAppSnackBar(context,
                                    message: provider.errorMessage,
                                    type: SnackBarType.error);
                              }
                            },
                          );
                        },
                      ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip Widget ───────────────────────────────────────────────────────
class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.color,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? color : Colors.grey.withOpacity(0.3),
      ),
    );
  }
}

// ── Todo Card Widget ─────────────────────────────────────────────────────────
class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  final dynamic todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: GestureDetector(
          onTap: onToggle,
          child: Icon(
            todo.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: todo.isDone ? Colors.green : colorScheme.outline,
            size: 28,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          todo.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
