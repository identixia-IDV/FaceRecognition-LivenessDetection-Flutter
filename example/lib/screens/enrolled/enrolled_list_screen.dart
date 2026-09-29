import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../services/person_database.dart';
import '../../widgets/enrolled_thumbnail.dart';

class EnrolledListScreen extends StatelessWidget {
  const EnrolledListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final people = context.watch<PersonDatabase>().persons;
    return Scaffold(
      appBar: AppBar(title: const Text('Enrolled list')),
      body: people.isEmpty
          ? const Center(
              child: Text(
                'No enrolled faces yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                return Container(
                  height: 72,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      EnrolledThumbnail(person: person),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            context.read<PersonDatabase>().remove(person.id),
                        icon: const Icon(Icons.close, color: AppColors.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
