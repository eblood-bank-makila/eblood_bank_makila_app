// UPPERCASE FIRST LETTER
extension CapitalizeFirstLetterExtensions on String {
  String capitalizeFirstLetter() {
    if (isEmpty) {
      return this;
    }
    return this[0].toUpperCase() + substring(1);
  }
}

extension DateFormatExtensions on DateTime {
  String formatReadableDate() {
    // Format the date as "Day Month Year" (e.g., "17 Aug 2024")
    return '${this.day.toString().padLeft(2, '0')} '
        '${_monthName(this.month)} '
        '${this.year}';
  }

  // Helper function to get the month name
  String _monthName(int month) {
    const months = [
      'Janv',
      'Fevr',
      'Mars',
      'Avr',
      'May',
      'Juin',
      'Juil',
      'Août',
      'Sept',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
  }
}
