import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DocNook'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get tabFiles;

  /// No description provided for @tabTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tabTools;

  /// No description provided for @actionScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get actionScan;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get searchHint;

  /// No description provided for @homeContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get homeContinueReading;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get homeRecentActivity;

  /// No description provided for @quickScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get quickScan;

  /// No description provided for @quickOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get quickOpenFile;

  /// No description provided for @quickMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge PDF'**
  String get quickMerge;

  /// No description provided for @quickConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get quickConvert;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a file or scan a page to get started'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Documents you open in DocNook appear here.'**
  String get homeEmptyBody;

  /// No description provided for @actionOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get actionOpenFile;

  /// No description provided for @actionFindDocuments.
  ///
  /// In en, this message translates to:
  /// **'Find my documents'**
  String get actionFindDocuments;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsGroupPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get toolsGroupPdf;

  /// No description provided for @toolsGroupConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get toolsGroupConvert;

  /// No description provided for @toolsGroupScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get toolsGroupScan;

  /// No description provided for @toolMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get toolMerge;

  /// No description provided for @toolMergeDesc.
  ///
  /// In en, this message translates to:
  /// **'Combine PDFs and images'**
  String get toolMergeDesc;

  /// No description provided for @toolSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get toolSplit;

  /// No description provided for @toolSplitDesc.
  ///
  /// In en, this message translates to:
  /// **'By range or every N pages'**
  String get toolSplitDesc;

  /// No description provided for @toolOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize pages'**
  String get toolOrganize;

  /// No description provided for @toolOrganizeDesc.
  ///
  /// In en, this message translates to:
  /// **'Reorder, rotate, delete'**
  String get toolOrganizeDesc;

  /// No description provided for @toolCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get toolCompress;

  /// No description provided for @toolCompressDesc.
  ///
  /// In en, this message translates to:
  /// **'Make the file smaller'**
  String get toolCompressDesc;

  /// No description provided for @toolProtect.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get toolProtect;

  /// No description provided for @toolProtectDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a password'**
  String get toolProtectDesc;

  /// No description provided for @toolUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get toolUnlock;

  /// No description provided for @toolUnlockDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove a password you know'**
  String get toolUnlockDesc;

  /// No description provided for @toolWatermark.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get toolWatermark;

  /// No description provided for @toolWatermarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Text or image on pages'**
  String get toolWatermarkDesc;

  /// No description provided for @toolPageNumbers.
  ///
  /// In en, this message translates to:
  /// **'Page numbers'**
  String get toolPageNumbers;

  /// No description provided for @toolPageNumbersDesc.
  ///
  /// In en, this message translates to:
  /// **'Number every page'**
  String get toolPageNumbersDesc;

  /// No description provided for @toolSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get toolSign;

  /// No description provided for @toolSignDesc.
  ///
  /// In en, this message translates to:
  /// **'Draw or place a signature'**
  String get toolSignDesc;

  /// No description provided for @toolAnnotate.
  ///
  /// In en, this message translates to:
  /// **'Annotate'**
  String get toolAnnotate;

  /// No description provided for @toolAnnotateDesc.
  ///
  /// In en, this message translates to:
  /// **'Highlight, draw, add notes'**
  String get toolAnnotateDesc;

  /// No description provided for @toolFillForms.
  ///
  /// In en, this message translates to:
  /// **'Fill forms'**
  String get toolFillForms;

  /// No description provided for @toolFillFormsDesc.
  ///
  /// In en, this message translates to:
  /// **'Type into PDF form fields'**
  String get toolFillFormsDesc;

  /// No description provided for @toolRedact.
  ///
  /// In en, this message translates to:
  /// **'Redact'**
  String get toolRedact;

  /// No description provided for @toolRedactDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove content for good'**
  String get toolRedactDesc;

  /// No description provided for @toolImagesToPdf.
  ///
  /// In en, this message translates to:
  /// **'Images to PDF'**
  String get toolImagesToPdf;

  /// No description provided for @toolImagesToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Photos into one PDF'**
  String get toolImagesToPdfDesc;

  /// No description provided for @toolPdfToImages.
  ///
  /// In en, this message translates to:
  /// **'PDF to images'**
  String get toolPdfToImages;

  /// No description provided for @toolPdfToImagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Each page as JPG or PNG'**
  String get toolPdfToImagesDesc;

  /// No description provided for @toolWordToPdf.
  ///
  /// In en, this message translates to:
  /// **'Word to PDF'**
  String get toolWordToPdf;

  /// No description provided for @toolWordToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'DOCX and ODT'**
  String get toolWordToPdfDesc;

  /// No description provided for @toolExcelToPdf.
  ///
  /// In en, this message translates to:
  /// **'Excel to PDF'**
  String get toolExcelToPdf;

  /// No description provided for @toolExcelToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'XLSX, ODS and CSV'**
  String get toolExcelToPdfDesc;

  /// No description provided for @toolPptToPdf.
  ///
  /// In en, this message translates to:
  /// **'PowerPoint to PDF'**
  String get toolPptToPdf;

  /// No description provided for @toolPptToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'One slide per page'**
  String get toolPptToPdfDesc;

  /// No description provided for @toolPdfToWord.
  ///
  /// In en, this message translates to:
  /// **'PDF to Word'**
  String get toolPdfToWord;

  /// No description provided for @toolPdfToWordDesc.
  ///
  /// In en, this message translates to:
  /// **'Basic layout, editable text'**
  String get toolPdfToWordDesc;

  /// No description provided for @toolPdfToText.
  ///
  /// In en, this message translates to:
  /// **'PDF to text'**
  String get toolPdfToText;

  /// No description provided for @toolPdfToTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Plain text, OCR if scanned'**
  String get toolPdfToTextDesc;

  /// No description provided for @toolTextToPdf.
  ///
  /// In en, this message translates to:
  /// **'Text to PDF'**
  String get toolTextToPdf;

  /// No description provided for @toolTextToPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'TXT and Markdown'**
  String get toolTextToPdfDesc;

  /// No description provided for @toolCsvExcel.
  ///
  /// In en, this message translates to:
  /// **'CSV and Excel'**
  String get toolCsvExcel;

  /// No description provided for @toolCsvExcelDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert either way'**
  String get toolCsvExcelDesc;

  /// No description provided for @toolScanDoc.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get toolScanDoc;

  /// No description provided for @toolScanDocDesc.
  ///
  /// In en, this message translates to:
  /// **'Pages to PDF'**
  String get toolScanDocDesc;

  /// No description provided for @toolScanId.
  ///
  /// In en, this message translates to:
  /// **'Scan ID card'**
  String get toolScanId;

  /// No description provided for @toolScanIdDesc.
  ///
  /// In en, this message translates to:
  /// **'Front and back on one page'**
  String get toolScanIdDesc;

  /// No description provided for @toolScanBook.
  ///
  /// In en, this message translates to:
  /// **'Scan book'**
  String get toolScanBook;

  /// No description provided for @toolScanBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Splits two-page spreads'**
  String get toolScanBookDesc;

  /// No description provided for @toolScanOcr.
  ///
  /// In en, this message translates to:
  /// **'Scan with text'**
  String get toolScanOcr;

  /// No description provided for @toolScanOcrDesc.
  ///
  /// In en, this message translates to:
  /// **'Searchable PDF'**
  String get toolScanOcrDesc;

  /// No description provided for @toolExtractText.
  ///
  /// In en, this message translates to:
  /// **'Extract text from image'**
  String get toolExtractText;

  /// No description provided for @toolExtractTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Copy text from a photo'**
  String get toolExtractTextDesc;

  /// No description provided for @filesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get filesEmptyTitle;

  /// No description provided for @filesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Let DocNook list the documents on your phone, or open one directly.'**
  String get filesEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @openingFile.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get openingFile;

  /// No description provided for @copyingFile.
  ///
  /// In en, this message translates to:
  /// **'Copying file…'**
  String get copyingFile;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionOpenWith.
  ///
  /// In en, this message translates to:
  /// **'Open with another app'**
  String get actionOpenWith;

  /// No description provided for @actionTryAnyway.
  ///
  /// In en, this message translates to:
  /// **'Open anyway'**
  String get actionTryAnyway;

  /// No description provided for @actionTryText.
  ///
  /// In en, this message translates to:
  /// **'Show as plain text'**
  String get actionTryText;

  /// No description provided for @actionMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get actionMore;

  /// No description provided for @actionStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get actionStar;

  /// No description provided for @actionUnstar.
  ///
  /// In en, this message translates to:
  /// **'Remove star'**
  String get actionUnstar;

  /// No description provided for @actionInfo.
  ///
  /// In en, this message translates to:
  /// **'Document info'**
  String get actionInfo;

  /// No description provided for @actionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get actionPrint;

  /// No description provided for @actionGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get actionGo;

  /// No description provided for @errUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'DocNook can\'t open this type of file'**
  String get errUnsupportedTitle;

  /// No description provided for @errUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'You can open it in another app instead.'**
  String get errUnsupportedBody;

  /// No description provided for @errCorruptTitle.
  ///
  /// In en, this message translates to:
  /// **'This file looks damaged'**
  String get errCorruptTitle;

  /// No description provided for @errCorruptBody.
  ///
  /// In en, this message translates to:
  /// **'Part of the file is missing or unreadable. If you received it in a chat, ask the sender to share it again.'**
  String get errCorruptBody;

  /// No description provided for @errMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'This file is no longer available'**
  String get errMissingTitle;

  /// No description provided for @errMissingBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been moved, renamed or deleted, or the app that shared it no longer gives access.'**
  String get errMissingBody;

  /// No description provided for @errPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'This file is password-protected'**
  String get errPasswordTitle;

  /// No description provided for @errPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the password to open it.'**
  String get errPasswordBody;

  /// No description provided for @errTooLargeTitle.
  ///
  /// In en, this message translates to:
  /// **'This file is very large'**
  String get errTooLargeTitle;

  /// No description provided for @errTooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'It is {size}, more than DocNook can open comfortably on this phone. It may be slow or close unexpectedly.'**
  String errTooLargeBody(String size);

  /// No description provided for @errPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'DocNook can\'t read this file'**
  String get errPermissionTitle;

  /// No description provided for @errPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'The app that shared it didn\'t give permission. Try opening it from that app again, or use Open file.'**
  String get errPermissionBody;

  /// No description provided for @errOutOfSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone is out of space'**
  String get errOutOfSpaceTitle;

  /// No description provided for @errOutOfSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Free up some storage and try again.'**
  String get errOutOfSpaceBody;

  /// No description provided for @errUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errUnknownTitle;

  /// No description provided for @errUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'DocNook couldn\'t finish. Try again, or open the file in another app.'**
  String get errUnknownBody;

  /// No description provided for @errNoAppToOpen.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open this file'**
  String get errNoAppToOpen;

  /// No description provided for @errLegacyBanner.
  ///
  /// In en, this message translates to:
  /// **'Old Office files can only be previewed as text.'**
  String get errLegacyBanner;

  /// No description provided for @passwordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordTitle;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordWrong.
  ///
  /// In en, this message translates to:
  /// **'That password didn\'t work. Check it and try again.'**
  String get passwordWrong;

  /// No description provided for @passwordOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get passwordOpen;

  /// No description provided for @pdfPageOf.
  ///
  /// In en, this message translates to:
  /// **'{page} / {total}'**
  String pdfPageOf(int page, int total);

  /// No description provided for @pdfGoToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get pdfGoToPage;

  /// No description provided for @pdfPageNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Page number (1–{total})'**
  String pdfPageNumberHint(int total);

  /// No description provided for @pdfThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pdfThumbnails;

  /// No description provided for @pdfOutline.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get pdfOutline;

  /// No description provided for @pdfBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get pdfBookmarks;

  /// No description provided for @pdfNightMode.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get pdfNightMode;

  /// No description provided for @pdfDayMode.
  ///
  /// In en, this message translates to:
  /// **'Day mode'**
  String get pdfDayMode;

  /// No description provided for @pdfAnnotate.
  ///
  /// In en, this message translates to:
  /// **'Annotate'**
  String get pdfAnnotate;

  /// No description provided for @pdfNoOutline.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no table of contents.'**
  String get pdfNoOutline;

  /// No description provided for @pdfNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet. Add one for the page you are on.'**
  String get pdfNoBookmarks;

  /// No description provided for @pdfAddBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this page'**
  String get pdfAddBookmark;

  /// No description provided for @pdfRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get pdfRemoveBookmark;

  /// No description provided for @pdfBookmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pdfBookmarkLabel(int page);

  /// No description provided for @pdfScrollVertical.
  ///
  /// In en, this message translates to:
  /// **'Continuous scroll'**
  String get pdfScrollVertical;

  /// No description provided for @pdfScrollHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Page by page'**
  String get pdfScrollHorizontal;

  /// No description provided for @searchInDocument.
  ///
  /// In en, this message translates to:
  /// **'Find in document'**
  String get searchInDocument;

  /// No description provided for @searchMatches.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String searchMatches(int current, int total);

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// No description provided for @searchSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchSearching;

  /// No description provided for @searchPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get searchPrevious;

  /// No description provided for @searchNext.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get searchNext;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get actionSelectAll;

  /// No description provided for @sizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{n} B'**
  String sizeBytes(int n);

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 page} other{{n} pages}}'**
  String pagesCount(int n);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeToday;

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @comingInPhase.
  ///
  /// In en, this message translates to:
  /// **'Arrives in a later build'**
  String get comingInPhase;

  /// No description provided for @privacyPromise.
  ///
  /// In en, this message translates to:
  /// **'DocNook has no internet permission. Your documents never leave your phone unless you share them. No accounts, no ads, no tracking.'**
  String get privacyPromise;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
