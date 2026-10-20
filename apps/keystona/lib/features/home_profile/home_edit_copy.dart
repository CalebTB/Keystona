/// Copy for HomeEdit. Kit text is verbatim; lines marked "invented" had none
/// (listed in the build report).
abstract final class HomeEditCopy {
  static const String cancel = 'Cancel';
  static const String title = 'Edit home';
  static const String save = 'Save';
  static const String photo = 'PHOTO';
  static const String cover = 'COVER';
  static const String coverTag = 'FRONT OF HOUSE';
  static const String addPhoto = 'ADD';
  static const String address = 'ADDRESS';
  static const String street = 'Street';
  static const String city = 'City';
  static const String state = 'State';
  static const String zip = 'ZIP';
  static const String kindOfHome = 'KIND OF HOME';
  static const String sizeAge = 'SIZE & AGE';
  static const String yearBuilt = 'Year built';
  static const String squareFeet = 'Square feet';
  static const String lot = 'Lot (acres)';
  static const String garage = 'Garage';
  static const String bedrooms = 'Bedrooms';
  static const String bathrooms = 'Bathrooms';
  static const String stories = 'Stories';
  static const String bought = 'WHEN YOU BOUGHT IT';
  static const String boughtNote = 'OPTIONAL · ONLY YOU SEE THIS';
  static const String date = 'Date';
  static const String price = 'Price';
  static const String climate = 'CLIMATE';
  static const String yearHelpBad = 'FOUR DIGITS, LIKE 1998';
  static const String yearHelpChanged = 'REMINDERS AND LIFESPANS WILL UPDATE';
  static const String zipHelpChanged =
      "NEW ZIP · WE'LL RECHECK THE ZONE WHEN YOU SAVE";
  static const String zipHelpLocked =
      "SET FROM YOUR ZIP · CAN'T BE CHANGED BY HAND";

  /// Invented.
  static const String changePhoto = 'CHANGE';
  static const String basement = 'Has a basement';
  static const String garageSpaces = 'Garage spaces';
  static const String garageNone = 'No garage';
  static const String garageSheet = 'Garage';
  static const String garageUnset = 'Select';
  static const String purchaseSheet = 'When you bought it';
  static const String purchaseSet = 'Done';
  static const String purchaseClear = 'Clear date';
  static const String month = 'Month';
  static const String year = 'Year';
  static const String zipHelpBad = 'FIVE DIGITS';
  static const String stateHelpBad = 'TWO LETTERS, LIKE AL';
  static const String climateUnset = 'Set from your ZIP when you save';
  static const String loadError = "We couldn't load your home.";
  static const String saveError = 'Could not save. Please try again.';
  static const String noHomeTitle = 'No home yet';
  static const String noHomeBody = 'Add your home first, then you can edit it.';

  /// Garage kinds stored in `garage_type`, with how they read.
  static const List<({String value, String label})> garageKinds = [
    (value: 'attached', label: 'Attached'),
    (value: 'detached', label: 'Detached'),
    (value: 'carport', label: 'Carport'),
  ];
}
