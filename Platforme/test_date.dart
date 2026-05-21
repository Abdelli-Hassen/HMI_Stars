import 'dart:core';

String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  
  if (diff.isNegative) {
    final absDiff = diff.abs();
    if (absDiff.inDays > 0) return 'Dans ${absDiff.inDays} jours';
    if (absDiff.inHours > 0) {
      final minutes = absDiff.inMinutes % 60;
      if (minutes == 0) return 'Dans ${absDiff.inHours} h';
      return 'Dans ${absDiff.inHours} h et $minutes min';
    }
    if (absDiff.inMinutes > 0) return 'Dans ${absDiff.inMinutes} min';
    return 'À l\'instant';
  }

  if (diff.inSeconds < 60) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) {
    final heures = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) return 'Il y a $heures h';
    return 'Il y a $heures h et $minutes min';
  }
  if (diff.inDays == 1) return 'Hier';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

void main() {
  print('1 hour from now: ${formatRelativeTime(DateTime.now().add(Duration(hours: 1)))}');
  print('1 hour 30m from now: ${formatRelativeTime(DateTime.now().add(Duration(hours: 1, minutes: 30)))}');
  print('2 days from now: ${formatRelativeTime(DateTime.now().add(Duration(days: 2)))}');
  print('5 minutes from now: ${formatRelativeTime(DateTime.now().add(Duration(minutes: 5)))}');
  print('Just now: ${formatRelativeTime(DateTime.now())}');
  print('2 hours ago: ${formatRelativeTime(DateTime.now().subtract(Duration(hours: 2, minutes: 15)))}');
  print('Yesterday: ${formatRelativeTime(DateTime.now().subtract(Duration(days: 1)))}');
}
