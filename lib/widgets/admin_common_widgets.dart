import 'package:flutter/material.dart';

class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    required this.onChanged,
    this.hint = 'Search',
  });

  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class AdminLoadingWidget extends StatelessWidget {
  const AdminLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class AdminEmptyWidget extends StatelessWidget {
  const AdminEmptyWidget({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 68,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'No $title found',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class AdminErrorWidget extends StatelessWidget {
  const AdminErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 62,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showAdminDeleteDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.delete_outline_rounded),
          title: const Text('Delete record'),
          content: const Text('Are you sure you want to delete this?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
