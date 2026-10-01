import 'package:flutter/material.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CareLink')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your next check-in',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Check-In',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Today at 4:00 PM'),
                      const SizedBox(height: 4),
                      const Text('Student Companion'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {},
                child: const Text('Start Check-In'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {},
                child: const Text('My Schedule'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {},
                child: const Text('Memory Lane'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
