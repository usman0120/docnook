// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DocNook';

  @override
  String get tabHome => 'Home';

  @override
  String get tabFiles => 'Files';

  @override
  String get tabTools => 'Tools';

  @override
  String get actionScan => 'Scan';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionSearch => 'Search';

  @override
  String get searchHint => 'Search documents';

  @override
  String get homeContinueReading => 'Continue reading';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeRecent => 'Recent';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeRecentActivity => 'Recent activity';

  @override
  String get quickScan => 'Scan';

  @override
  String get quickOpenFile => 'Open file';

  @override
  String get quickMerge => 'Merge PDF';

  @override
  String get quickConvert => 'Convert';

  @override
  String get homeEmptyTitle => 'Open a file or scan a page to get started';

  @override
  String get homeEmptyBody => 'Documents you open in DocNook appear here.';

  @override
  String get actionOpenFile => 'Open file';

  @override
  String get actionFindDocuments => 'Find my documents';

  @override
  String get filesTitle => 'Files';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsGroupPdf => 'PDF';

  @override
  String get toolsGroupConvert => 'Convert';

  @override
  String get toolsGroupScan => 'Scan';

  @override
  String get toolMerge => 'Merge';

  @override
  String get toolMergeDesc => 'Combine PDFs and images';

  @override
  String get toolSplit => 'Split';

  @override
  String get toolSplitDesc => 'By range or every N pages';

  @override
  String get toolOrganize => 'Organize pages';

  @override
  String get toolOrganizeDesc => 'Reorder, rotate, delete';

  @override
  String get toolCompress => 'Compress';

  @override
  String get toolCompressDesc => 'Make the file smaller';

  @override
  String get toolProtect => 'Protect';

  @override
  String get toolProtectDesc => 'Add a password';

  @override
  String get toolUnlock => 'Unlock';

  @override
  String get toolUnlockDesc => 'Remove a password you know';

  @override
  String get toolWatermark => 'Watermark';

  @override
  String get toolWatermarkDesc => 'Text or image on pages';

  @override
  String get toolPageNumbers => 'Page numbers';

  @override
  String get toolPageNumbersDesc => 'Number every page';

  @override
  String get toolSign => 'Sign';

  @override
  String get toolSignDesc => 'Draw or place a signature';

  @override
  String get toolAnnotate => 'Annotate';

  @override
  String get toolAnnotateDesc => 'Highlight, draw, add notes';

  @override
  String get toolFillForms => 'Fill forms';

  @override
  String get toolFillFormsDesc => 'Type into PDF form fields';

  @override
  String get toolRedact => 'Redact';

  @override
  String get toolRedactDesc => 'Remove content for good';

  @override
  String get toolImagesToPdf => 'Images to PDF';

  @override
  String get toolImagesToPdfDesc => 'Photos into one PDF';

  @override
  String get toolPdfToImages => 'PDF to images';

  @override
  String get toolPdfToImagesDesc => 'Each page as JPG or PNG';

  @override
  String get toolWordToPdf => 'Word to PDF';

  @override
  String get toolWordToPdfDesc => 'DOCX and ODT';

  @override
  String get toolExcelToPdf => 'Excel to PDF';

  @override
  String get toolExcelToPdfDesc => 'XLSX, ODS and CSV';

  @override
  String get toolPptToPdf => 'PowerPoint to PDF';

  @override
  String get toolPptToPdfDesc => 'One slide per page';

  @override
  String get toolPdfToWord => 'PDF to Word';

  @override
  String get toolPdfToWordDesc => 'Basic layout, editable text';

  @override
  String get toolPdfToText => 'PDF to text';

  @override
  String get toolPdfToTextDesc => 'Plain text, OCR if scanned';

  @override
  String get toolTextToPdf => 'Text to PDF';

  @override
  String get toolTextToPdfDesc => 'TXT and Markdown';

  @override
  String get toolCsvExcel => 'CSV and Excel';

  @override
  String get toolCsvExcelDesc => 'Convert either way';

  @override
  String get toolScanDoc => 'Scan document';

  @override
  String get toolScanDocDesc => 'Pages to PDF';

  @override
  String get toolScanId => 'Scan ID card';

  @override
  String get toolScanIdDesc => 'Front and back on one page';

  @override
  String get toolScanBook => 'Scan book';

  @override
  String get toolScanBookDesc => 'Splits two-page spreads';

  @override
  String get toolScanOcr => 'Scan with text';

  @override
  String get toolScanOcrDesc => 'Searchable PDF';

  @override
  String get toolExtractText => 'Extract text from image';

  @override
  String get toolExtractTextDesc => 'Copy text from a photo';

  @override
  String get filterAll => 'All';

  @override
  String get filterPdf => 'PDF';

  @override
  String get filterWord => 'Word';

  @override
  String get filterSheets => 'Sheets';

  @override
  String get filterSlides => 'Slides';

  @override
  String get filterImages => 'Images';

  @override
  String get filterText => 'Text';

  @override
  String get filterEbooks => 'E-books';

  @override
  String get filterArchives => 'Archives';

  @override
  String get filterStarred => 'Starred';

  @override
  String get segmentDocuments => 'Documents';

  @override
  String get segmentCollections => 'Collections';

  @override
  String get segmentFolders => 'Folders';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortName => 'Name';

  @override
  String get sortModified => 'Date modified';

  @override
  String get sortSize => 'Size';

  @override
  String get sortType => 'Type';

  @override
  String get viewList => 'List view';

  @override
  String get viewGrid => 'Grid view';

  @override
  String findingDocuments(int count) {
    return 'Finding documents… $count found';
  }

  @override
  String documentsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String filterEmpty(String type) {
    return 'No $type files yet';
  }

  @override
  String get starredEmpty =>
      'Nothing starred yet. Star a document to keep it here.';

  @override
  String get permissionCardTitle => 'Let DocNook list your documents';

  @override
  String get permissionCardBody =>
      'Without access, Files shows only documents you open here.';

  @override
  String get primerTitle => 'Find the documents already on your phone';

  @override
  String get primerBody =>
      'DocNook can list your PDFs, Office files and e-books so you can open them from one place. It only reads them on your phone; nothing is uploaded.';

  @override
  String get primerAllow => 'Allow access';

  @override
  String get primerFolders => 'Choose folders instead';

  @override
  String get primerNotNow => 'Not now';

  @override
  String get primerSettingsHint =>
      'On the next screen, turn on access for DocNook, then come back.';

  @override
  String selectedCount(int n) {
    return '$n selected';
  }

  @override
  String get actionSelectAllItems => 'Select all';

  @override
  String get actionDeselect => 'Cancel selection';

  @override
  String get actionAddToCollection => 'Add to collection';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionMerge => 'Merge';

  @override
  String get actionConvert => 'Convert';

  @override
  String get actionMoveToVault => 'Move to Vault';

  @override
  String get actionRemoveFromRecents => 'Remove from Recent';

  @override
  String get actionRemoveFromCollection => 'Remove from collection';

  @override
  String deleteTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: 'this file',
    );
    return 'Delete $_temp0?';
  }

  @override
  String get deleteBody =>
      'The file is removed from your phone. This can\'t be undone.';

  @override
  String deleted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files deleted',
      one: 'File deleted',
    );
    return '$_temp0';
  }

  @override
  String get deleteFailed =>
      'DocNook couldn\'t delete this file. It may belong to another app.';

  @override
  String get renameTitle => 'Rename';

  @override
  String get renameLabel => 'Name';

  @override
  String get renameFailed =>
      'Couldn\'t rename. A file with that name may already exist.';

  @override
  String get renamed => 'Renamed';

  @override
  String get starredDone => 'Starred';

  @override
  String get unstarredDone => 'Star removed';

  @override
  String addedToCollection(String name) {
    return 'Added to $name';
  }

  @override
  String get newCollection => 'New collection';

  @override
  String get collectionName => 'Collection name';

  @override
  String get collectionCreate => 'Create';

  @override
  String get collectionsEmptyTitle => 'No collections yet';

  @override
  String get collectionsEmptyBody =>
      'Group documents without moving them. A file can be in several collections.';

  @override
  String get collectionEmpty => 'This collection is empty';

  @override
  String get collectionEmptyBody =>
      'Add documents from Files with long-press, then Add to collection.';

  @override
  String get renameCollection => 'Rename collection';

  @override
  String get deleteCollection => 'Delete collection';

  @override
  String get deleteCollectionBody =>
      'The documents stay on your phone; only the collection is removed.';

  @override
  String get foldersDocNook => 'DocNook folder';

  @override
  String get foldersDocNookBody =>
      'Documents/DocNook — everything DocNook creates';

  @override
  String get foldersAllStorage => 'All of your phone\'s storage';

  @override
  String get foldersGranted => 'Folders you added';

  @override
  String get foldersAdd => 'Add a folder';

  @override
  String get foldersRemove => 'Remove folder';

  @override
  String get foldersEmpty =>
      'Add a folder so DocNook can list the documents in it.';

  @override
  String get infoType => 'Type';

  @override
  String get infoSize => 'Size';

  @override
  String get infoPages => 'Pages';

  @override
  String get infoModified => 'Modified';

  @override
  String get infoLastOpened => 'Last opened';

  @override
  String get infoLocation => 'Location';

  @override
  String get infoCollections => 'Collections';

  @override
  String get infoIndexed => 'Indexed for search';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notAvailableYet => 'This tool arrives in a later build';

  @override
  String get searchNames => 'Names';

  @override
  String get searchInside => 'Inside documents';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClearRecent => 'Clear';

  @override
  String searchEmptyTitle(String term) {
    return 'No matches for “$term”';
  }

  @override
  String get searchEmptyHint =>
      'Documents that haven\'t been indexed yet are only searched by name.';

  @override
  String get searchStartHint =>
      'Search file names and the text inside your documents.';

  @override
  String searchPageHit(int page) {
    return 'Page $page';
  }

  @override
  String searchPartHit(int part) {
    return 'Part $part';
  }

  @override
  String get filesEmptyTitle => 'No documents yet';

  @override
  String get filesEmptyBody =>
      'Let DocNook list the documents on your phone, or open one directly.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsReading => 'Reading';

  @override
  String get settingsPdfScroll => 'PDF page scrolling';

  @override
  String get settingsNightDefault => 'Open PDFs in night mode';

  @override
  String get settingsKeepScreenOn => 'Keep screen on while reading';

  @override
  String get settingsOutput => 'Output';

  @override
  String get settingsQuality => 'Default quality';

  @override
  String get qualitySmall => 'Small';

  @override
  String get qualityBalanced => 'Balanced';

  @override
  String get qualityBest => 'Best';

  @override
  String get settingsSaveLocation => 'Save location';

  @override
  String get settingsSaveLocationValue => 'Documents/DocNook';

  @override
  String get settingsLibrary => 'Library';

  @override
  String get settingsPrivacy => 'Privacy and security';

  @override
  String get settingsBlockScreenshots => 'Block screenshots';

  @override
  String get settingsBlockScreenshotsBody =>
      'Hides DocNook in the recent apps list too';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsCache => 'Cached copies and thumbnails';

  @override
  String get settingsClearCache => 'Clear';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String get settingsPrivacyPromise => 'Privacy promise';

  @override
  String get onboardingTitle1 => 'Every document, one place';

  @override
  String get onboardingBody1 =>
      'Read, scan, convert and combine — all on your phone.';

  @override
  String get onboardingTitle2 => 'No internet. No account.';

  @override
  String get onboardingBody2 =>
      'Your files stay on your phone. DocNook has no internet permission, so nothing can be uploaded.';

  @override
  String get onboardingBadge => 'No internet permission';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get openingFile => 'Opening…';

  @override
  String get copyingFile => 'Copying file…';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionShare => 'Share';

  @override
  String get actionOpenWith => 'Open with another app';

  @override
  String get actionTryAnyway => 'Open anyway';

  @override
  String get actionTryText => 'Show as plain text';

  @override
  String get actionMore => 'More options';

  @override
  String get actionStar => 'Star';

  @override
  String get actionUnstar => 'Remove star';

  @override
  String get actionInfo => 'Document info';

  @override
  String get actionPrint => 'Print';

  @override
  String get actionGo => 'Go';

  @override
  String get errUnsupportedTitle => 'DocNook can\'t open this type of file';

  @override
  String get errUnsupportedBody => 'You can open it in another app instead.';

  @override
  String get errCorruptTitle => 'This file looks damaged';

  @override
  String get errCorruptBody =>
      'Part of the file is missing or unreadable. If you received it in a chat, ask the sender to share it again.';

  @override
  String get errMissingTitle => 'This file is no longer available';

  @override
  String get errMissingBody =>
      'It may have been moved, renamed or deleted, or the app that shared it no longer gives access.';

  @override
  String get errPasswordTitle => 'This file is password-protected';

  @override
  String get errPasswordBody => 'Enter the password to open it.';

  @override
  String get errTooLargeTitle => 'This file is very large';

  @override
  String errTooLargeBody(String size) {
    return 'It is $size, more than DocNook can open comfortably on this phone. It may be slow or close unexpectedly.';
  }

  @override
  String get errPermissionTitle => 'DocNook can\'t read this file';

  @override
  String get errPermissionBody =>
      'The app that shared it didn\'t give permission. Try opening it from that app again, or use Open file.';

  @override
  String get errOutOfSpaceTitle => 'Your phone is out of space';

  @override
  String get errOutOfSpaceBody => 'Free up some storage and try again.';

  @override
  String get errUnknownTitle => 'Something went wrong';

  @override
  String get errUnknownBody =>
      'DocNook couldn\'t finish. Try again, or open the file in another app.';

  @override
  String get errNoAppToOpen => 'No app on this phone can open this file';

  @override
  String get errLegacyBanner =>
      'Old Office files can only be previewed as text.';

  @override
  String get passwordTitle => 'Enter password';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordWrong =>
      'That password didn\'t work. Check it and try again.';

  @override
  String get passwordOpen => 'Open';

  @override
  String pdfPageOf(int page, int total) {
    return '$page / $total';
  }

  @override
  String get pdfGoToPage => 'Go to page';

  @override
  String pdfPageNumberHint(int total) {
    return 'Page number (1–$total)';
  }

  @override
  String get pdfThumbnails => 'Pages';

  @override
  String get pdfOutline => 'Contents';

  @override
  String get pdfBookmarks => 'Bookmarks';

  @override
  String get pdfNightMode => 'Night mode';

  @override
  String get pdfDayMode => 'Day mode';

  @override
  String get pdfAnnotate => 'Annotate';

  @override
  String get pdfNoOutline => 'This PDF has no table of contents.';

  @override
  String get pdfNoBookmarks =>
      'No bookmarks yet. Add one for the page you are on.';

  @override
  String get pdfAddBookmark => 'Bookmark this page';

  @override
  String get pdfRemoveBookmark => 'Remove bookmark';

  @override
  String pdfBookmarkLabel(int page) {
    return 'Page $page';
  }

  @override
  String get pdfScrollVertical => 'Continuous scroll';

  @override
  String get pdfScrollHorizontal => 'Page by page';

  @override
  String get searchInDocument => 'Find in document';

  @override
  String searchMatches(int current, int total) {
    return '$current of $total';
  }

  @override
  String get searchNoMatches => 'No matches';

  @override
  String get searchSearching => 'Searching…';

  @override
  String get searchPrevious => 'Previous match';

  @override
  String get searchNext => 'Next match';

  @override
  String get copied => 'Copied';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionSelectAll => 'Select all';

  @override
  String sizeBytes(int n) {
    return '$n B';
  }

  @override
  String pagesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String get timeToday => 'Today';

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String get comingInPhase => 'Arrives in a later build';

  @override
  String get privacyPromise =>
      'DocNook has no internet permission. Your documents never leave your phone unless you share them. No accounts, no ads, no tracking.';
}
