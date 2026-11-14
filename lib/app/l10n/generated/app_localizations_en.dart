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
  String get docNoOutline => 'This document has no headings to list.';

  @override
  String get docSimplifiedBanner =>
      'Simplified layout — some formatting may differ from the original.';

  @override
  String get docTextLarger => 'Larger text';

  @override
  String get docTextSmaller => 'Smaller text';

  @override
  String get docLegacyBanner =>
      'Limited preview: old Office files show their text only.';

  @override
  String get sheetFitWidth => 'Fit to width';

  @override
  String get sheetActualSize => 'Actual size';

  @override
  String get sheetTruncated =>
      'This sheet is very large; DocNook shows the first 1,000,000 cells.';

  @override
  String get sheetEmpty => 'This sheet is empty';

  @override
  String get sheetFormula => 'Formula';

  @override
  String get sheetFormat => 'Format';

  @override
  String get slidesOutline => 'Outline';

  @override
  String get slidesSlides => 'Slides';

  @override
  String get slidesNotes => 'Speaker notes';

  @override
  String slideOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get slidesBanner =>
      'Simplified slides — animations, charts and some shapes are not shown.';

  @override
  String get textWrap => 'Wrap lines';

  @override
  String get textNoWrap => 'Don\'t wrap lines';

  @override
  String get textLineNumbers => 'Line numbers';

  @override
  String get textJumpEnd => 'Jump to end';

  @override
  String get textJumpStart => 'Jump to start';

  @override
  String get mdRendered => 'Formatted';

  @override
  String get mdSource => 'Source';

  @override
  String get imageRotate => 'Rotate';

  @override
  String get imageMakePdf => 'Make PDF';

  @override
  String get imageExtractText => 'Extract text';

  @override
  String imageOf(int n, int total) {
    return '$n of $total';
  }

  @override
  String zipEntries(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get zipExtract => 'Extract to DocNook folder';

  @override
  String zipExtracted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Extracted $n files',
      one: 'Extracted 1 file',
    );
    return '$_temp0 to Documents/DocNook/Extracted';
  }

  @override
  String get zipEmpty => 'This archive is empty';

  @override
  String zipUnsafe(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return 'Skipped $_temp0 with unsafe names';
  }

  @override
  String get zipFolderUp => 'Up one folder';

  @override
  String get epubChapters => 'Chapters';

  @override
  String get epubTheme => 'Reading theme';

  @override
  String get epubThemePaper => 'Paper';

  @override
  String get epubThemeWhite => 'White';

  @override
  String get epubThemeNight => 'Night';

  @override
  String get epubLineSpacing => 'Line spacing';

  @override
  String epubChapterProgress(int n, int total) {
    return 'Chapter $n of $total';
  }

  @override
  String get epubNext => 'Next chapter';

  @override
  String get epubPrevious => 'Previous chapter';

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

  @override
  String get actionDone => 'Done';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSave => 'Save';

  @override
  String get scanPageLimit => 'A scan can have up to 50 pages';

  @override
  String get scanAddFailed => 'Couldn\'t add that page. Try again.';

  @override
  String get scanIdHint =>
      'Scan the front of the card first, then the back. Both sides are placed at real size on one page.';

  @override
  String get scanLoadErrorTitle => 'Couldn\'t open this scan';

  @override
  String get scanLoadErrorBody => 'Go back and try again.';

  @override
  String get scanGoneTitle => 'This scan has been saved or discarded';

  @override
  String get scanDiscard => 'Discard scan';

  @override
  String get scanDiscardTitle => 'Discard this scan?';

  @override
  String scanDiscardBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Its $n pages will be deleted.',
      one: 'Its page will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get scanNoPagesTitle => 'No pages yet';

  @override
  String get scanAddPage => 'Add page';

  @override
  String get scanCrop => 'Crop';

  @override
  String get scanRotate => 'Rotate';

  @override
  String get scanFilter => 'Filter';

  @override
  String get scanRetake => 'Retake';

  @override
  String get scanApplyToAll => 'Apply to all pages';

  @override
  String get scanDeletePageTitle => 'Delete this page?';

  @override
  String get scanFilterOriginal => 'Original';

  @override
  String get scanFilterDocument => 'Document';

  @override
  String get scanFilterGrayscale => 'Grayscale';

  @override
  String get scanFilterEnhanced => 'Enhanced colour';

  @override
  String scanPageLabel(int n) {
    return 'Page $n';
  }

  @override
  String get scanSplitLine => 'Split between pages. Drag to adjust.';

  @override
  String get scanCropAuto => 'Detect edges';

  @override
  String get scanCropFull => 'Whole photo';

  @override
  String get scanCornerTopLeft => 'Top-left corner';

  @override
  String get scanCornerTopRight => 'Top-right corner';

  @override
  String get scanCornerBottomRight => 'Bottom-right corner';

  @override
  String get scanCornerBottomLeft => 'Bottom-left corner';

  @override
  String get scanCameraFailed =>
      'The camera couldn\'t start. Close other camera apps and try again.';

  @override
  String get scanCameraDenied =>
      'DocNook needs the camera to scan. Allow it in Settings › Apps › DocNook › Permissions.';

  @override
  String get scanCameraMissing => 'This phone has no camera DocNook can use.';

  @override
  String get scanIdFront => 'Front of the card';

  @override
  String get scanIdBack => 'Back of the card';

  @override
  String get scanBookHint => 'Fit both pages of the open book in the frame';

  @override
  String get scanFlashOn => 'Turn on light';

  @override
  String get scanFlashOff => 'Turn off light';

  @override
  String get scanShutter => 'Take photo';

  @override
  String get scanModeDocument => 'Document';

  @override
  String get scanModeIdCard => 'ID card';

  @override
  String get scanModeBook => 'Book';

  @override
  String scanPagesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get scanSaveTitle => 'Save scan';

  @override
  String get scanFieldName => 'Name';

  @override
  String get scanFieldFormat => 'Format';

  @override
  String get scanFieldPageSize => 'Page size';

  @override
  String get scanFieldQuality => 'Quality';

  @override
  String get scanFieldCollection => 'Collection';

  @override
  String get scanSizeLetter => 'Letter';

  @override
  String get scanSizeFit => 'Fit to image';

  @override
  String get scanQualitySmall => 'Small';

  @override
  String get scanQualityBalanced => 'Balanced';

  @override
  String get scanQualityBest => 'Best';

  @override
  String scanEstimate(String size) {
    return 'About $size';
  }

  @override
  String get scanOcrToggle => 'Make text searchable';

  @override
  String get scanOcrHelp =>
      'Reads English and other Latin-script text on your phone, so you can search and copy it.';

  @override
  String get scanNoCollection => 'None';

  @override
  String scanSaving(int percent) {
    return 'Saving… $percent%';
  }

  @override
  String get scanSaveFailed =>
      'Couldn\'t save the scan. Your pages are kept; try again.';

  @override
  String get scanSaveNoSpace =>
      'Your phone is out of space. Free some space and try again.';

  @override
  String get scanSavedTitle => 'Saved';

  @override
  String get scanSavedLocation => 'Documents › DocNook › Scans';

  @override
  String scanImagesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String get homeDraftTitle => 'Unfinished scan';

  @override
  String homeDraftDetails(int n, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pages',
      one: '1 page',
      zero: 'No pages yet',
    );
    return '$_temp0 · $when';
  }

  @override
  String get homeDraftResume => 'Resume';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionDecrease => 'Fewer';

  @override
  String get actionIncrease => 'More';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionRedo => 'Redo';

  @override
  String get actionRemove => 'Remove';

  @override
  String get editDiscardTitle => 'Discard your changes?';

  @override
  String get editDiscardBody =>
      'Nothing has been saved yet. The original file stays as it was.';

  @override
  String pageOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String pageLabel(int n) {
    return 'Page $n';
  }

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get colorGrey => 'Grey';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBlue => 'Blue';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get posBottomCenter => 'Bottom centre';

  @override
  String get posBottomLeft => 'Bottom left';

  @override
  String get posBottomRight => 'Bottom right';

  @override
  String get posTopCenter => 'Top centre';

  @override
  String get posTopLeft => 'Top left';

  @override
  String get posTopRight => 'Top right';

  @override
  String get posCenter => 'Centre';

  @override
  String get toolOpening => 'Opening…';

  @override
  String get toolBrowseDevice => 'Browse device';

  @override
  String get toolPickOne => 'Choose a PDF';

  @override
  String get toolPickMany => 'Choose files in the order you want them';

  @override
  String get toolPickNone => 'Choose files';

  @override
  String toolContinueWith(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Continue with $n files',
      one: 'Continue with 1 file',
    );
    return '$_temp0';
  }

  @override
  String get toolPickEmptyPdf => 'No PDFs in your library yet';

  @override
  String get toolPickEmptyAny => 'No PDFs or pictures in your library yet';

  @override
  String get toolPickEmptyBody => 'Pick one from your phone instead.';

  @override
  String get toolPickErrorTitle => 'Couldn’t load your files';

  @override
  String get toolPickErrorBody => 'Pick the file from your phone instead.';

  @override
  String get toolBusy =>
      'Another tool is still working. Try again when it’s done.';

  @override
  String get toolCancelled => 'Cancelled. Nothing was saved.';

  @override
  String get toolStepWorking => 'Working…';

  @override
  String toolStepPage(int n, int total) {
    return 'Page $n of $total';
  }

  @override
  String get toolKeepsRunning =>
      'You can close this. The job keeps running and shows on the Tools tab.';

  @override
  String get toolDoneTitle => 'Saved';

  @override
  String toolFilesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String toolFilesNamed(String name, int more) {
    String _temp0 = intl.Intl.pluralLogic(
      more,
      locale: localeName,
      other: '$more more',
      one: '1 more',
    );
    return '$name and $_temp0';
  }

  @override
  String toolSizeChange(String before, String after, String change) {
    return '$before → $after ($change)';
  }

  @override
  String toolSavedIn(String folder) {
    return 'In Documents/DocNook/$folder';
  }

  @override
  String get toolOverwritten => 'The original file was replaced';

  @override
  String get toolSomeFailed => 'Some files couldn’t be used';

  @override
  String get toolShowInFolder => 'Show in folder';

  @override
  String get toolDoMore => 'Do more';

  @override
  String toolFolderHint(String folder) {
    return 'Find it in Documents/DocNook/$folder with your Files app.';
  }

  @override
  String toolChipRunning(String tool, int percent) {
    return '$tool: $percent%';
  }

  @override
  String toolChipDone(String tool) {
    return '$tool finished. Tap to see the result.';
  }

  @override
  String toolChipFailed(String tool) {
    return '$tool didn’t finish. Tap for details.';
  }

  @override
  String get toolPrevPage => 'Previous page';

  @override
  String get toolNextPage => 'Next page';

  @override
  String get toolOutputName => 'File name';

  @override
  String get toolMergeOrder => 'Order';

  @override
  String get toolDragToReorder => 'Drag to reorder';

  @override
  String get toolImagePage => 'Picture, 1 page';

  @override
  String get toolAddFiles => 'Add files';

  @override
  String get toolMergeNeedTwo => 'Add at least two files to merge.';

  @override
  String toolMergeAction(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Merge $n files',
      one: 'Merge 1 file',
    );
    return '$_temp0';
  }

  @override
  String get toolSplitHow => 'How to split';

  @override
  String get toolSplitRanges => 'Ranges';

  @override
  String get toolSplitEvery => 'Every N pages';

  @override
  String get toolSplitExtract => 'Pick pages';

  @override
  String get toolSplitRangesLabel => 'One file for each range';

  @override
  String get toolSplitExtractLabel => 'Pages to keep, in one file';

  @override
  String get toolSplitEveryLabel => 'Pages per file';

  @override
  String get toolRangesHint => 'e.g. 1-3, 5, 8-';

  @override
  String toolRangesHelp(int total) {
    return 'Pages 1 to $total. Use commas between ranges.';
  }

  @override
  String toolRangesInvalid(int total) {
    return 'Check the page numbers. This PDF has $total pages.';
  }

  @override
  String toolSplitResult(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Makes $n files',
      one: 'Makes 1 file',
    );
    return '$_temp0';
  }

  @override
  String get toolSplitAction => 'Split';

  @override
  String toolSplitActionMany(int n) {
    return 'Split into $n files';
  }

  @override
  String get toolCompressLevel => 'Compression';

  @override
  String get toolCompressLight => 'Light';

  @override
  String get toolCompressLightDesc =>
      'Re-saves the file and drops unused data. Nothing visible changes.';

  @override
  String get toolCompressBalanced => 'Balanced';

  @override
  String get toolCompressBalancedDesc =>
      'Makes large photos smaller. Text stays sharp and selectable.';

  @override
  String get toolCompressStrong => 'Strong';

  @override
  String get toolCompressStrongDesc =>
      'Turns every page into a compact picture. Smallest file; text stays selectable only with the option below.';

  @override
  String get toolCompressOcrHelp =>
      'Reads the pages so text can still be searched and copied. Takes longer.';

  @override
  String get toolCompressAction => 'Compress';

  @override
  String get toolProtectPassword => 'Password';

  @override
  String get toolPasswordNew => 'New password';

  @override
  String get toolPasswordConfirm => 'Type it again';

  @override
  String get toolPasswordMismatch => 'The passwords don’t match.';

  @override
  String get toolPasswordShort => 'Use at least 4 characters.';

  @override
  String get toolProtectWarning =>
      'DocNook doesn’t keep this password. If you forget it, the copy can’t be opened.';

  @override
  String get toolProtectAction => 'Protect';

  @override
  String get toolUnlockHelp =>
      'The copy will open without a password. The original keeps its password.';

  @override
  String get toolUnlockNotLocked =>
      'This PDF has no password, so there is nothing to remove.';

  @override
  String get toolUnlockAction => 'Remove password';

  @override
  String get toolWatermarkKind => 'Watermark';

  @override
  String get toolWatermarkText => 'Text';

  @override
  String get toolWatermarkImage => 'Picture';

  @override
  String get toolWatermarkHint => 'e.g. CONFIDENTIAL';

  @override
  String get toolWatermarkColor => 'Colour';

  @override
  String get toolWatermarkPickImage => 'Choose a picture';

  @override
  String get toolWatermarkSize => 'Size';

  @override
  String get toolWatermarkAngle => 'Angle';

  @override
  String toolWatermarkOpacity(int percent) {
    return 'Opacity $percent%';
  }

  @override
  String get toolWatermarkAction => 'Add watermark';

  @override
  String get toolPages => 'Pages';

  @override
  String get toolPagesAll => 'All pages';

  @override
  String get toolPagesSome => 'Some pages';

  @override
  String get toolNumbersPosition => 'Position';

  @override
  String get toolNumbersFormat => 'Format';

  @override
  String get toolNumbersPageOf => 'Page 1 of N';

  @override
  String get toolNumbersStart => 'First number';

  @override
  String get toolNumbersSkipFirst => 'Skip the first page (cover)';

  @override
  String get toolPageNumbersAction => 'Add page numbers';

  @override
  String organizeSelected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pages selected',
      one: '1 page selected',
    );
    return '$_temp0';
  }

  @override
  String get organizeRotate => 'Rotate';

  @override
  String get organizeDuplicate => 'Duplicate';

  @override
  String get organizeExtract => 'Extract';

  @override
  String get organizeInsert => 'Insert';

  @override
  String get organizeInsertBlank => 'Blank page';

  @override
  String get organizeInsertImage => 'Picture from your phone';

  @override
  String get organizeKeepOne => 'A PDF needs at least one page.';

  @override
  String get organizeSave => 'Save';

  @override
  String get organizeSaveTitle => 'Save changes';

  @override
  String get organizeSaveCopy => 'Save as a copy';

  @override
  String get organizeOverwrite => 'Replace the original';

  @override
  String get organizeOverwriteHelp =>
      'Replacing can’t be undone. A copy keeps the original as it is.';

  @override
  String organizePageLabel(int n) {
    return 'Page $n';
  }

  @override
  String get organizeTapHint => 'select. Long-press and drag to move';

  @override
  String get annotHighlight => 'Highlight';

  @override
  String get annotUnderline => 'Underline';

  @override
  String get annotStrike => 'Strike';

  @override
  String get annotPen => 'Pen';

  @override
  String get annotNote => 'Note';

  @override
  String get annotSignature => 'Signature';

  @override
  String get annotEraser => 'Eraser';

  @override
  String get annotColor => 'Colour';

  @override
  String annotWidth(String width) {
    return 'Line width $width';
  }

  @override
  String get annotNoteTitle => 'Add a note';

  @override
  String get annotNoteLabel => 'Note';

  @override
  String get annotSave => 'Save copy';

  @override
  String get signAdd => 'Add signature';

  @override
  String get signChoose => 'Choose a signature';

  @override
  String get signNew => 'New signature';

  @override
  String get signSaved => 'Saved signature';

  @override
  String get signDrawTitle => 'Sign here';

  @override
  String get signDrawArea => 'Signature drawing area';

  @override
  String get signKeep => 'Keep for next time (up to 3)';

  @override
  String get signPlaced => 'Signature. Drag to move';

  @override
  String get signResize => 'Resize signature';

  @override
  String get formChoose => 'Choose';

  @override
  String get formNoFields => 'This PDF has no fillable fields';

  @override
  String get formNoFieldsBody => 'You can still write on it with Annotate.';

  @override
  String get formLoadFailed => 'Couldn’t read the form';

  @override
  String formFieldsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fields',
      one: '1 field',
    );
    return '$_temp0';
  }

  @override
  String get formPrevious => 'Previous';

  @override
  String get formNext => 'Next';

  @override
  String get formSave => 'Save copy';

  @override
  String get formSaveTitle => 'Save the filled form';

  @override
  String get formSaveEditable => 'Save copy (still editable)';

  @override
  String get formSaveFlat => 'Save flattened copy';

  @override
  String get formSaveHelp =>
      'A flattened copy can’t be changed again, and looks the same in every app.';

  @override
  String get redactArea => 'Draw box';

  @override
  String get redactText => 'Select text';

  @override
  String get redactAreaHint => 'Drag over anything you want removed.';

  @override
  String get redactTextHint => 'Drag across the words you want removed.';

  @override
  String get redactMarked => 'Marked areas';

  @override
  String get redactNone => 'Nothing marked yet.';

  @override
  String redactAreas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n areas',
      one: '1 area',
    );
    return '$_temp0';
  }

  @override
  String get redactClearPage => 'Clear this page';

  @override
  String redactSave(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Redact $n areas',
      one: 'Redact 1 area',
      zero: 'Redact',
    );
    return '$_temp0';
  }

  @override
  String get redactConfirmTitle => 'Remove marked content?';

  @override
  String get redactConfirmBody =>
      'Marked content will be permanently removed. Text on redacted pages is rebuilt using OCR. The original file stays as it was.';

  @override
  String get redactConfirmAction => 'Remove';

  @override
  String get actionPdfTools => 'PDF tools';

  @override
  String get annotHintNone =>
      'Pick a tool, then draw on the page. Swipe to turn pages.';

  @override
  String get annotHintNote => 'Tap where the note should go.';

  @override
  String get annotHintEraser => 'Tap a mark to remove it.';

  @override
  String get actionTools => 'Tools';

  @override
  String toolWrongType(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files can’t be used with this tool.',
      one: '1 file can’t be used with this tool.',
    );
    return '$_temp0';
  }

  @override
  String toolPickEmptyFor(String tool) {
    return 'No files for $tool in your library yet';
  }

  @override
  String get toolPickFile => 'Choose a file';

  @override
  String get toolCopyText => 'Copy text';

  @override
  String get toolTextCopied => 'Text copied.';

  @override
  String get toolMakePdf => 'Make PDF';

  @override
  String get toolReadText => 'Read text';

  @override
  String get toolConvert => 'Convert';

  @override
  String toolConvertMany(int n) {
    return 'Convert $n files';
  }

  @override
  String get toolFilesLabel => 'Files';

  @override
  String get fidelityFull => 'Full';

  @override
  String get fidelityGood => 'Good';

  @override
  String get fidelityBasic => 'Basic';

  @override
  String get limitImagesToPdf => 'One picture per page, in the order shown.';

  @override
  String get limitPdfToImages => 'Each page becomes a separate picture.';

  @override
  String get limitPdfToText =>
      'Text only, no layout. Scanned pages are read with OCR.';

  @override
  String get limitWordToPdf =>
      'Uses DocNook’s own layout, not Word’s; complex layouts may shift.';

  @override
  String get limitExcelToPdf =>
      'Sheet to pages; charts and pictures in cells are left out.';

  @override
  String get limitPptToPdf =>
      'One slide per page; animations and some shapes are simplified.';

  @override
  String get limitTextToPdf => 'Plain text and Markdown, exactly as written.';

  @override
  String get limitPdfToWord =>
      'Paragraphs, headings and pictures; no complex layout.';

  @override
  String get limitCsvExcel => 'All data is kept; formatting is minimal.';

  @override
  String get convPageSize => 'Page size';

  @override
  String get convFitPicture => 'Fit picture';

  @override
  String get convMargins => 'Margins';

  @override
  String get convMarginNone => 'None';

  @override
  String get convMarginNormal => 'Normal';

  @override
  String get convQuality => 'Quality';

  @override
  String get convBest => 'Best';

  @override
  String get convImageFormat => 'Format';

  @override
  String get convResolution => 'Resolution';

  @override
  String get convDpiScreen => 'Screen';

  @override
  String get convDpiPrint => 'Print';

  @override
  String get convDpiHigh => 'High';

  @override
  String get convImagesHint => 'Each PDF page is saved as its own picture.';

  @override
  String get convOcrScanned => 'Read scanned pages';

  @override
  String get convOcrScannedHelp =>
      'Pages with no text layer are read with OCR. Takes longer.';

  @override
  String get convFitWidth => 'Fit columns to the page width';

  @override
  String get convFitWidthHelp => 'Very wide sheets continue on extra pages.';

  @override
  String get convToExcel => 'Makes an Excel file (.xlsx).';

  @override
  String get convToCsv => 'Makes one CSV file for each sheet.';
}
