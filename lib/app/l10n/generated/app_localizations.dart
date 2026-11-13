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

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get filterPdf;

  /// No description provided for @filterWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get filterWord;

  /// No description provided for @filterSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get filterSheets;

  /// No description provided for @filterSlides.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get filterSlides;

  /// No description provided for @filterImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get filterImages;

  /// No description provided for @filterText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get filterText;

  /// No description provided for @filterEbooks.
  ///
  /// In en, this message translates to:
  /// **'E-books'**
  String get filterEbooks;

  /// No description provided for @filterArchives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get filterArchives;

  /// No description provided for @filterStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get filterStarred;

  /// No description provided for @segmentDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get segmentDocuments;

  /// No description provided for @segmentCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get segmentCollections;

  /// No description provided for @segmentFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get segmentFolders;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortModified.
  ///
  /// In en, this message translates to:
  /// **'Date modified'**
  String get sortModified;

  /// No description provided for @sortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortSize;

  /// No description provided for @sortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sortType;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get viewList;

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get viewGrid;

  /// No description provided for @findingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Finding documents… {count} found'**
  String findingDocuments(int count);

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 document} other{{n} documents}}'**
  String documentsCount(int n);

  /// No description provided for @filterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No {type} files yet'**
  String filterEmpty(String type);

  /// No description provided for @starredEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing starred yet. Star a document to keep it here.'**
  String get starredEmpty;

  /// No description provided for @permissionCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Let DocNook list your documents'**
  String get permissionCardTitle;

  /// No description provided for @permissionCardBody.
  ///
  /// In en, this message translates to:
  /// **'Without access, Files shows only documents you open here.'**
  String get permissionCardBody;

  /// No description provided for @primerTitle.
  ///
  /// In en, this message translates to:
  /// **'Find the documents already on your phone'**
  String get primerTitle;

  /// No description provided for @primerBody.
  ///
  /// In en, this message translates to:
  /// **'DocNook can list your PDFs, Office files and e-books so you can open them from one place. It only reads them on your phone; nothing is uploaded.'**
  String get primerBody;

  /// No description provided for @primerAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get primerAllow;

  /// No description provided for @primerFolders.
  ///
  /// In en, this message translates to:
  /// **'Choose folders instead'**
  String get primerFolders;

  /// No description provided for @primerNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get primerNotNow;

  /// No description provided for @primerSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'On the next screen, turn on access for DocNook, then come back.'**
  String get primerSettingsHint;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String selectedCount(int n);

  /// No description provided for @actionSelectAllItems.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get actionSelectAllItems;

  /// No description provided for @actionDeselect.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get actionDeselect;

  /// No description provided for @actionAddToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get actionAddToCollection;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get actionMerge;

  /// No description provided for @actionConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get actionConvert;

  /// No description provided for @actionMoveToVault.
  ///
  /// In en, this message translates to:
  /// **'Move to Vault'**
  String get actionMoveToVault;

  /// No description provided for @actionRemoveFromRecents.
  ///
  /// In en, this message translates to:
  /// **'Remove from Recent'**
  String get actionRemoveFromRecents;

  /// No description provided for @actionRemoveFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove from collection'**
  String get actionRemoveFromCollection;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {n, plural, =1{this file} other{{n} files}}?'**
  String deleteTitle(int n);

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'The file is removed from your phone. This can\'t be undone.'**
  String get deleteBody;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{File deleted} other{{n} files deleted}}'**
  String deleted(int n);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'DocNook couldn\'t delete this file. It may belong to another app.'**
  String get deleteFailed;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameTitle;

  /// No description provided for @renameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get renameLabel;

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename. A file with that name may already exist.'**
  String get renameFailed;

  /// No description provided for @renamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get renamed;

  /// No description provided for @starredDone.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get starredDone;

  /// No description provided for @unstarredDone.
  ///
  /// In en, this message translates to:
  /// **'Star removed'**
  String get unstarredDone;

  /// No description provided for @addedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToCollection(String name);

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollection;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionName;

  /// No description provided for @collectionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get collectionCreate;

  /// No description provided for @collectionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get collectionsEmptyTitle;

  /// No description provided for @collectionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Group documents without moving them. A file can be in several collections.'**
  String get collectionsEmptyBody;

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'This collection is empty'**
  String get collectionEmpty;

  /// No description provided for @collectionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add documents from Files with long-press, then Add to collection.'**
  String get collectionEmptyBody;

  /// No description provided for @renameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename collection'**
  String get renameCollection;

  /// No description provided for @deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get deleteCollection;

  /// No description provided for @deleteCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'The documents stay on your phone; only the collection is removed.'**
  String get deleteCollectionBody;

  /// No description provided for @foldersDocNook.
  ///
  /// In en, this message translates to:
  /// **'DocNook folder'**
  String get foldersDocNook;

  /// No description provided for @foldersDocNookBody.
  ///
  /// In en, this message translates to:
  /// **'Documents/DocNook — everything DocNook creates'**
  String get foldersDocNookBody;

  /// No description provided for @foldersAllStorage.
  ///
  /// In en, this message translates to:
  /// **'All of your phone\'s storage'**
  String get foldersAllStorage;

  /// No description provided for @foldersGranted.
  ///
  /// In en, this message translates to:
  /// **'Folders you added'**
  String get foldersGranted;

  /// No description provided for @foldersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a folder'**
  String get foldersAdd;

  /// No description provided for @foldersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove folder'**
  String get foldersRemove;

  /// No description provided for @foldersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a folder so DocNook can list the documents in it.'**
  String get foldersEmpty;

  /// No description provided for @infoType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get infoType;

  /// No description provided for @infoSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get infoSize;

  /// No description provided for @infoPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get infoPages;

  /// No description provided for @infoModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get infoModified;

  /// No description provided for @infoLastOpened.
  ///
  /// In en, this message translates to:
  /// **'Last opened'**
  String get infoLastOpened;

  /// No description provided for @infoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get infoLocation;

  /// No description provided for @infoCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get infoCollections;

  /// No description provided for @infoIndexed.
  ///
  /// In en, this message translates to:
  /// **'Indexed for search'**
  String get infoIndexed;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @docNoOutline.
  ///
  /// In en, this message translates to:
  /// **'This document has no headings to list.'**
  String get docNoOutline;

  /// No description provided for @docSimplifiedBanner.
  ///
  /// In en, this message translates to:
  /// **'Simplified layout — some formatting may differ from the original.'**
  String get docSimplifiedBanner;

  /// No description provided for @docTextLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get docTextLarger;

  /// No description provided for @docTextSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get docTextSmaller;

  /// No description provided for @docLegacyBanner.
  ///
  /// In en, this message translates to:
  /// **'Limited preview: old Office files show their text only.'**
  String get docLegacyBanner;

  /// No description provided for @sheetFitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit to width'**
  String get sheetFitWidth;

  /// No description provided for @sheetActualSize.
  ///
  /// In en, this message translates to:
  /// **'Actual size'**
  String get sheetActualSize;

  /// No description provided for @sheetTruncated.
  ///
  /// In en, this message translates to:
  /// **'This sheet is very large; DocNook shows the first 1,000,000 cells.'**
  String get sheetTruncated;

  /// No description provided for @sheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'This sheet is empty'**
  String get sheetEmpty;

  /// No description provided for @sheetFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get sheetFormula;

  /// No description provided for @sheetFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get sheetFormat;

  /// No description provided for @slidesOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get slidesOutline;

  /// No description provided for @slidesSlides.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get slidesSlides;

  /// No description provided for @slidesNotes.
  ///
  /// In en, this message translates to:
  /// **'Speaker notes'**
  String get slidesNotes;

  /// No description provided for @slideOf.
  ///
  /// In en, this message translates to:
  /// **'{n} / {total}'**
  String slideOf(int n, int total);

  /// No description provided for @slidesBanner.
  ///
  /// In en, this message translates to:
  /// **'Simplified slides — animations, charts and some shapes are not shown.'**
  String get slidesBanner;

  /// No description provided for @textWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get textWrap;

  /// No description provided for @textNoWrap.
  ///
  /// In en, this message translates to:
  /// **'Don\'t wrap lines'**
  String get textNoWrap;

  /// No description provided for @textLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get textLineNumbers;

  /// No description provided for @textJumpEnd.
  ///
  /// In en, this message translates to:
  /// **'Jump to end'**
  String get textJumpEnd;

  /// No description provided for @textJumpStart.
  ///
  /// In en, this message translates to:
  /// **'Jump to start'**
  String get textJumpStart;

  /// No description provided for @mdRendered.
  ///
  /// In en, this message translates to:
  /// **'Formatted'**
  String get mdRendered;

  /// No description provided for @mdSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get mdSource;

  /// No description provided for @imageRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get imageRotate;

  /// No description provided for @imageMakePdf.
  ///
  /// In en, this message translates to:
  /// **'Make PDF'**
  String get imageMakePdf;

  /// No description provided for @imageExtractText.
  ///
  /// In en, this message translates to:
  /// **'Extract text'**
  String get imageExtractText;

  /// No description provided for @imageOf.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String imageOf(int n, int total);

  /// No description provided for @zipEntries.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 item} other{{n} items}}'**
  String zipEntries(int n);

  /// No description provided for @zipExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract to DocNook folder'**
  String get zipExtract;

  /// No description provided for @zipExtracted.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Extracted 1 file} other{Extracted {n} files}} to Documents/DocNook/Extracted'**
  String zipExtracted(int n);

  /// No description provided for @zipEmpty.
  ///
  /// In en, this message translates to:
  /// **'This archive is empty'**
  String get zipEmpty;

  /// No description provided for @zipUnsafe.
  ///
  /// In en, this message translates to:
  /// **'Skipped {n, plural, =1{1 item} other{{n} items}} with unsafe names'**
  String zipUnsafe(int n);

  /// No description provided for @zipFolderUp.
  ///
  /// In en, this message translates to:
  /// **'Up one folder'**
  String get zipFolderUp;

  /// No description provided for @epubChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get epubChapters;

  /// No description provided for @epubTheme.
  ///
  /// In en, this message translates to:
  /// **'Reading theme'**
  String get epubTheme;

  /// No description provided for @epubThemePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get epubThemePaper;

  /// No description provided for @epubThemeWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get epubThemeWhite;

  /// No description provided for @epubThemeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get epubThemeNight;

  /// No description provided for @epubLineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line spacing'**
  String get epubLineSpacing;

  /// No description provided for @epubChapterProgress.
  ///
  /// In en, this message translates to:
  /// **'Chapter {n} of {total}'**
  String epubChapterProgress(int n, int total);

  /// No description provided for @epubNext.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get epubNext;

  /// No description provided for @epubPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get epubPrevious;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'This tool arrives in a later build'**
  String get notAvailableYet;

  /// No description provided for @searchNames.
  ///
  /// In en, this message translates to:
  /// **'Names'**
  String get searchNames;

  /// No description provided for @searchInside.
  ///
  /// In en, this message translates to:
  /// **'Inside documents'**
  String get searchInside;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// No description provided for @searchClearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearRecent;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches for “{term}”'**
  String searchEmptyTitle(String term);

  /// No description provided for @searchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Documents that haven\'t been indexed yet are only searched by name.'**
  String get searchEmptyHint;

  /// No description provided for @searchStartHint.
  ///
  /// In en, this message translates to:
  /// **'Search file names and the text inside your documents.'**
  String get searchStartHint;

  /// No description provided for @searchPageHit.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String searchPageHit(int page);

  /// No description provided for @searchPartHit.
  ///
  /// In en, this message translates to:
  /// **'Part {part}'**
  String searchPartHit(int part);

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

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get settingsReading;

  /// No description provided for @settingsPdfScroll.
  ///
  /// In en, this message translates to:
  /// **'PDF page scrolling'**
  String get settingsPdfScroll;

  /// No description provided for @settingsNightDefault.
  ///
  /// In en, this message translates to:
  /// **'Open PDFs in night mode'**
  String get settingsNightDefault;

  /// No description provided for @settingsKeepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on while reading'**
  String get settingsKeepScreenOn;

  /// No description provided for @settingsOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get settingsOutput;

  /// No description provided for @settingsQuality.
  ///
  /// In en, this message translates to:
  /// **'Default quality'**
  String get settingsQuality;

  /// No description provided for @qualitySmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get qualitySmall;

  /// No description provided for @qualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get qualityBalanced;

  /// No description provided for @qualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get qualityBest;

  /// No description provided for @settingsSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get settingsSaveLocation;

  /// No description provided for @settingsSaveLocationValue.
  ///
  /// In en, this message translates to:
  /// **'Documents/DocNook'**
  String get settingsSaveLocationValue;

  /// No description provided for @settingsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsLibrary;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and security'**
  String get settingsPrivacy;

  /// No description provided for @settingsBlockScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get settingsBlockScreenshots;

  /// No description provided for @settingsBlockScreenshotsBody.
  ///
  /// In en, this message translates to:
  /// **'Hides DocNook in the recent apps list too'**
  String get settingsBlockScreenshotsBody;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsCache.
  ///
  /// In en, this message translates to:
  /// **'Cached copies and thumbnails'**
  String get settingsCache;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClearCache;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @settingsPrivacyPromise.
  ///
  /// In en, this message translates to:
  /// **'Privacy promise'**
  String get settingsPrivacyPromise;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Every document, one place'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Read, scan, convert and combine — all on your phone.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'No internet. No account.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Your files stay on your phone. DocNook has no internet permission, so nothing can be uploaded.'**
  String get onboardingBody2;

  /// No description provided for @onboardingBadge.
  ///
  /// In en, this message translates to:
  /// **'No internet permission'**
  String get onboardingBadge;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get actionGetStarted;

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

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @scanPageLimit.
  ///
  /// In en, this message translates to:
  /// **'A scan can have up to 50 pages'**
  String get scanPageLimit;

  /// No description provided for @scanAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add that page. Try again.'**
  String get scanAddFailed;

  /// No description provided for @scanIdHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the front of the card first, then the back. Both sides are placed at real size on one page.'**
  String get scanIdHint;

  /// No description provided for @scanLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this scan'**
  String get scanLoadErrorTitle;

  /// No description provided for @scanLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Go back and try again.'**
  String get scanLoadErrorBody;

  /// No description provided for @scanGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'This scan has been saved or discarded'**
  String get scanGoneTitle;

  /// No description provided for @scanDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard scan'**
  String get scanDiscard;

  /// No description provided for @scanDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this scan?'**
  String get scanDiscardTitle;

  /// No description provided for @scanDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Its page will be deleted.} other{Its {n} pages will be deleted.}}'**
  String scanDiscardBody(int n);

  /// No description provided for @scanNoPagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get scanNoPagesTitle;

  /// No description provided for @scanAddPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get scanAddPage;

  /// No description provided for @scanCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get scanCrop;

  /// No description provided for @scanRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get scanRotate;

  /// No description provided for @scanFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get scanFilter;

  /// No description provided for @scanRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scanRetake;

  /// No description provided for @scanApplyToAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all pages'**
  String get scanApplyToAll;

  /// No description provided for @scanDeletePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this page?'**
  String get scanDeletePageTitle;

  /// No description provided for @scanFilterOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get scanFilterOriginal;

  /// No description provided for @scanFilterDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get scanFilterDocument;

  /// No description provided for @scanFilterGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get scanFilterGrayscale;

  /// No description provided for @scanFilterEnhanced.
  ///
  /// In en, this message translates to:
  /// **'Enhanced colour'**
  String get scanFilterEnhanced;

  /// No description provided for @scanPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String scanPageLabel(int n);

  /// No description provided for @scanSplitLine.
  ///
  /// In en, this message translates to:
  /// **'Split between pages. Drag to adjust.'**
  String get scanSplitLine;

  /// No description provided for @scanCropAuto.
  ///
  /// In en, this message translates to:
  /// **'Detect edges'**
  String get scanCropAuto;

  /// No description provided for @scanCropFull.
  ///
  /// In en, this message translates to:
  /// **'Whole photo'**
  String get scanCropFull;

  /// No description provided for @scanCornerTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top-left corner'**
  String get scanCornerTopLeft;

  /// No description provided for @scanCornerTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top-right corner'**
  String get scanCornerTopRight;

  /// No description provided for @scanCornerBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom-right corner'**
  String get scanCornerBottomRight;

  /// No description provided for @scanCornerBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom-left corner'**
  String get scanCornerBottomLeft;

  /// No description provided for @scanCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera couldn\'t start. Close other camera apps and try again.'**
  String get scanCameraFailed;

  /// No description provided for @scanCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'DocNook needs the camera to scan. Allow it in Settings › Apps › DocNook › Permissions.'**
  String get scanCameraDenied;

  /// No description provided for @scanCameraMissing.
  ///
  /// In en, this message translates to:
  /// **'This phone has no camera DocNook can use.'**
  String get scanCameraMissing;

  /// No description provided for @scanIdFront.
  ///
  /// In en, this message translates to:
  /// **'Front of the card'**
  String get scanIdFront;

  /// No description provided for @scanIdBack.
  ///
  /// In en, this message translates to:
  /// **'Back of the card'**
  String get scanIdBack;

  /// No description provided for @scanBookHint.
  ///
  /// In en, this message translates to:
  /// **'Fit both pages of the open book in the frame'**
  String get scanBookHint;

  /// No description provided for @scanFlashOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on light'**
  String get scanFlashOn;

  /// No description provided for @scanFlashOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off light'**
  String get scanFlashOff;

  /// No description provided for @scanShutter.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanShutter;

  /// No description provided for @scanModeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get scanModeDocument;

  /// No description provided for @scanModeIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID card'**
  String get scanModeIdCard;

  /// No description provided for @scanModeBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get scanModeBook;

  /// No description provided for @scanPagesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 page} other{{n} pages}}'**
  String scanPagesCount(int n);

  /// No description provided for @scanSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save scan'**
  String get scanSaveTitle;

  /// No description provided for @scanFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get scanFieldName;

  /// No description provided for @scanFieldFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get scanFieldFormat;

  /// No description provided for @scanFieldPageSize.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get scanFieldPageSize;

  /// No description provided for @scanFieldQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get scanFieldQuality;

  /// No description provided for @scanFieldCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get scanFieldCollection;

  /// No description provided for @scanSizeLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get scanSizeLetter;

  /// No description provided for @scanSizeFit.
  ///
  /// In en, this message translates to:
  /// **'Fit to image'**
  String get scanSizeFit;

  /// No description provided for @scanQualitySmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get scanQualitySmall;

  /// No description provided for @scanQualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get scanQualityBalanced;

  /// No description provided for @scanQualityBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get scanQualityBest;

  /// No description provided for @scanEstimate.
  ///
  /// In en, this message translates to:
  /// **'About {size}'**
  String scanEstimate(String size);

  /// No description provided for @scanOcrToggle.
  ///
  /// In en, this message translates to:
  /// **'Make text searchable'**
  String get scanOcrToggle;

  /// No description provided for @scanOcrHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads English and other Latin-script text on your phone, so you can search and copy it.'**
  String get scanOcrHelp;

  /// No description provided for @scanNoCollection.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get scanNoCollection;

  /// No description provided for @scanSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving… {percent}%'**
  String scanSaving(int percent);

  /// No description provided for @scanSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the scan. Your pages are kept; try again.'**
  String get scanSaveFailed;

  /// No description provided for @scanSaveNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Your phone is out of space. Free some space and try again.'**
  String get scanSaveNoSpace;

  /// No description provided for @scanSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get scanSavedTitle;

  /// No description provided for @scanSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Documents › DocNook › Scans'**
  String get scanSavedLocation;

  /// No description provided for @scanImagesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 image} other{{n} images}}'**
  String scanImagesCount(int n);

  /// No description provided for @homeDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished scan'**
  String get homeDraftTitle;

  /// No description provided for @homeDraftDetails.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No pages yet} =1{1 page} other{{n} pages}} · {when}'**
  String homeDraftDetails(int n, String when);

  /// No description provided for @homeDraftResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeDraftResume;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionDecrease.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get actionDecrease;

  /// No description provided for @actionIncrease.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get actionIncrease;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get actionRedo;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @editDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get editDiscardTitle;

  /// No description provided for @editDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been saved yet. The original file stays as it was.'**
  String get editDiscardBody;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'{n} / {total}'**
  String pageOf(int n, int total);

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String pageLabel(int n);

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @colorGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get colorGrey;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @posBottomCenter.
  ///
  /// In en, this message translates to:
  /// **'Bottom centre'**
  String get posBottomCenter;

  /// No description provided for @posBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get posBottomLeft;

  /// No description provided for @posBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get posBottomRight;

  /// No description provided for @posTopCenter.
  ///
  /// In en, this message translates to:
  /// **'Top centre'**
  String get posTopCenter;

  /// No description provided for @posTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get posTopLeft;

  /// No description provided for @posTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get posTopRight;

  /// No description provided for @posCenter.
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get posCenter;

  /// No description provided for @toolOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get toolOpening;

  /// No description provided for @toolBrowseDevice.
  ///
  /// In en, this message translates to:
  /// **'Browse device'**
  String get toolBrowseDevice;

  /// No description provided for @toolPickOne.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get toolPickOne;

  /// No description provided for @toolPickMany.
  ///
  /// In en, this message translates to:
  /// **'Choose files in the order you want them'**
  String get toolPickMany;

  /// No description provided for @toolPickNone.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get toolPickNone;

  /// No description provided for @toolContinueWith.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Continue with 1 file} other{Continue with {n} files}}'**
  String toolContinueWith(int n);

  /// No description provided for @toolPickEmptyPdf.
  ///
  /// In en, this message translates to:
  /// **'No PDFs in your library yet'**
  String get toolPickEmptyPdf;

  /// No description provided for @toolPickEmptyAny.
  ///
  /// In en, this message translates to:
  /// **'No PDFs or pictures in your library yet'**
  String get toolPickEmptyAny;

  /// No description provided for @toolPickEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick one from your phone instead.'**
  String get toolPickEmptyBody;

  /// No description provided for @toolPickErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your files'**
  String get toolPickErrorTitle;

  /// No description provided for @toolPickErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the file from your phone instead.'**
  String get toolPickErrorBody;

  /// No description provided for @toolBusy.
  ///
  /// In en, this message translates to:
  /// **'Another tool is still working. Try again when it’s done.'**
  String get toolBusy;

  /// No description provided for @toolCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Nothing was saved.'**
  String get toolCancelled;

  /// No description provided for @toolStepWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get toolStepWorking;

  /// No description provided for @toolStepPage.
  ///
  /// In en, this message translates to:
  /// **'Page {n} of {total}'**
  String toolStepPage(int n, int total);

  /// No description provided for @toolKeepsRunning.
  ///
  /// In en, this message translates to:
  /// **'You can close this. The job keeps running and shows on the Tools tab.'**
  String get toolKeepsRunning;

  /// No description provided for @toolDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get toolDoneTitle;

  /// No description provided for @toolFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 file} other{{n} files}}'**
  String toolFilesCount(int n);

  /// No description provided for @toolFilesNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} and {more, plural, =1{1 more} other{{more} more}}'**
  String toolFilesNamed(String name, int more);

  /// No description provided for @toolSizeChange.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after} ({percent}%)'**
  String toolSizeChange(String before, String after, int percent);

  /// No description provided for @toolSavedIn.
  ///
  /// In en, this message translates to:
  /// **'In Documents/DocNook/{folder}'**
  String toolSavedIn(String folder);

  /// No description provided for @toolOverwritten.
  ///
  /// In en, this message translates to:
  /// **'The original file was replaced'**
  String get toolOverwritten;

  /// No description provided for @toolSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Some files couldn’t be used'**
  String get toolSomeFailed;

  /// No description provided for @toolShowInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get toolShowInFolder;

  /// No description provided for @toolDoMore.
  ///
  /// In en, this message translates to:
  /// **'Do more'**
  String get toolDoMore;

  /// No description provided for @toolFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Find it in Documents/DocNook/{folder} with your Files app.'**
  String toolFolderHint(String folder);

  /// No description provided for @toolChipRunning.
  ///
  /// In en, this message translates to:
  /// **'{tool}: {percent}%'**
  String toolChipRunning(String tool, int percent);

  /// No description provided for @toolChipDone.
  ///
  /// In en, this message translates to:
  /// **'{tool} finished. Tap to see the result.'**
  String toolChipDone(String tool);

  /// No description provided for @toolChipFailed.
  ///
  /// In en, this message translates to:
  /// **'{tool} didn’t finish. Tap for details.'**
  String toolChipFailed(String tool);

  /// No description provided for @toolPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get toolPrevPage;

  /// No description provided for @toolNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get toolNextPage;

  /// No description provided for @toolOutputName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get toolOutputName;

  /// No description provided for @toolMergeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get toolMergeOrder;

  /// No description provided for @toolDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get toolDragToReorder;

  /// No description provided for @toolImagePage.
  ///
  /// In en, this message translates to:
  /// **'Picture, 1 page'**
  String get toolImagePage;

  /// No description provided for @toolAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get toolAddFiles;

  /// No description provided for @toolMergeNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Add at least two files to merge.'**
  String get toolMergeNeedTwo;

  /// No description provided for @toolMergeAction.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Merge 1 file} other{Merge {n} files}}'**
  String toolMergeAction(int n);

  /// No description provided for @toolSplitHow.
  ///
  /// In en, this message translates to:
  /// **'How to split'**
  String get toolSplitHow;

  /// No description provided for @toolSplitRanges.
  ///
  /// In en, this message translates to:
  /// **'Ranges'**
  String get toolSplitRanges;

  /// No description provided for @toolSplitEvery.
  ///
  /// In en, this message translates to:
  /// **'Every N pages'**
  String get toolSplitEvery;

  /// No description provided for @toolSplitExtract.
  ///
  /// In en, this message translates to:
  /// **'Pick pages'**
  String get toolSplitExtract;

  /// No description provided for @toolSplitRangesLabel.
  ///
  /// In en, this message translates to:
  /// **'One file for each range'**
  String get toolSplitRangesLabel;

  /// No description provided for @toolSplitExtractLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages to keep, in one file'**
  String get toolSplitExtractLabel;

  /// No description provided for @toolSplitEveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages per file'**
  String get toolSplitEveryLabel;

  /// No description provided for @toolRangesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1-3, 5, 8-'**
  String get toolRangesHint;

  /// No description provided for @toolRangesHelp.
  ///
  /// In en, this message translates to:
  /// **'Pages 1 to {total}. Use commas between ranges.'**
  String toolRangesHelp(int total);

  /// No description provided for @toolRangesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the page numbers. This PDF has {total} pages.'**
  String toolRangesInvalid(int total);

  /// No description provided for @toolSplitResult.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Makes 1 file} other{Makes {n} files}}'**
  String toolSplitResult(int n);

  /// No description provided for @toolSplitAction.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get toolSplitAction;

  /// No description provided for @toolSplitActionMany.
  ///
  /// In en, this message translates to:
  /// **'Split into {n} files'**
  String toolSplitActionMany(int n);

  /// No description provided for @toolCompressLevel.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get toolCompressLevel;

  /// No description provided for @toolCompressLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get toolCompressLight;

  /// No description provided for @toolCompressLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-saves the file and drops unused data. Nothing visible changes.'**
  String get toolCompressLightDesc;

  /// No description provided for @toolCompressBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get toolCompressBalanced;

  /// No description provided for @toolCompressBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Makes large photos smaller. Text stays sharp and selectable.'**
  String get toolCompressBalancedDesc;

  /// No description provided for @toolCompressStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get toolCompressStrong;

  /// No description provided for @toolCompressStrongDesc.
  ///
  /// In en, this message translates to:
  /// **'Turns every page into a compact picture. Smallest file; text stays selectable only with the option below.'**
  String get toolCompressStrongDesc;

  /// No description provided for @toolCompressOcrHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads the pages so text can still be searched and copied. Takes longer.'**
  String get toolCompressOcrHelp;

  /// No description provided for @toolCompressAction.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get toolCompressAction;

  /// No description provided for @toolProtectPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get toolProtectPassword;

  /// No description provided for @toolPasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get toolPasswordNew;

  /// No description provided for @toolPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get toolPasswordConfirm;

  /// No description provided for @toolPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don’t match.'**
  String get toolPasswordMismatch;

  /// No description provided for @toolPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 4 characters.'**
  String get toolPasswordShort;

  /// No description provided for @toolProtectWarning.
  ///
  /// In en, this message translates to:
  /// **'DocNook doesn’t keep this password. If you forget it, the copy can’t be opened.'**
  String get toolProtectWarning;

  /// No description provided for @toolProtectAction.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get toolProtectAction;

  /// No description provided for @toolUnlockHelp.
  ///
  /// In en, this message translates to:
  /// **'The copy will open without a password. The original keeps its password.'**
  String get toolUnlockHelp;

  /// No description provided for @toolUnlockNotLocked.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no password, so there is nothing to remove.'**
  String get toolUnlockNotLocked;

  /// No description provided for @toolUnlockAction.
  ///
  /// In en, this message translates to:
  /// **'Remove password'**
  String get toolUnlockAction;

  /// No description provided for @toolWatermarkKind.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get toolWatermarkKind;

  /// No description provided for @toolWatermarkText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get toolWatermarkText;

  /// No description provided for @toolWatermarkImage.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get toolWatermarkImage;

  /// No description provided for @toolWatermarkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CONFIDENTIAL'**
  String get toolWatermarkHint;

  /// No description provided for @toolWatermarkColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get toolWatermarkColor;

  /// No description provided for @toolWatermarkPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose a picture'**
  String get toolWatermarkPickImage;

  /// No description provided for @toolWatermarkSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get toolWatermarkSize;

  /// No description provided for @toolWatermarkAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get toolWatermarkAngle;

  /// No description provided for @toolWatermarkOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity {percent}%'**
  String toolWatermarkOpacity(int percent);

  /// No description provided for @toolWatermarkAction.
  ///
  /// In en, this message translates to:
  /// **'Add watermark'**
  String get toolWatermarkAction;

  /// No description provided for @toolPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get toolPages;

  /// No description provided for @toolPagesAll.
  ///
  /// In en, this message translates to:
  /// **'All pages'**
  String get toolPagesAll;

  /// No description provided for @toolPagesSome.
  ///
  /// In en, this message translates to:
  /// **'Some pages'**
  String get toolPagesSome;

  /// No description provided for @toolNumbersPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get toolNumbersPosition;

  /// No description provided for @toolNumbersFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get toolNumbersFormat;

  /// No description provided for @toolNumbersPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page 1 of N'**
  String get toolNumbersPageOf;

  /// No description provided for @toolNumbersStart.
  ///
  /// In en, this message translates to:
  /// **'First number'**
  String get toolNumbersStart;

  /// No description provided for @toolNumbersSkipFirst.
  ///
  /// In en, this message translates to:
  /// **'Skip the first page (cover)'**
  String get toolNumbersSkipFirst;

  /// No description provided for @toolPageNumbersAction.
  ///
  /// In en, this message translates to:
  /// **'Add page numbers'**
  String get toolPageNumbersAction;

  /// No description provided for @organizeSelected.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 page selected} other{{n} pages selected}}'**
  String organizeSelected(int n);

  /// No description provided for @organizeRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get organizeRotate;

  /// No description provided for @organizeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get organizeDuplicate;

  /// No description provided for @organizeExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get organizeExtract;

  /// No description provided for @organizeInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get organizeInsert;

  /// No description provided for @organizeInsertBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank page'**
  String get organizeInsertBlank;

  /// No description provided for @organizeInsertImage.
  ///
  /// In en, this message translates to:
  /// **'Picture from your phone'**
  String get organizeInsertImage;

  /// No description provided for @organizeKeepOne.
  ///
  /// In en, this message translates to:
  /// **'A PDF needs at least one page.'**
  String get organizeKeepOne;

  /// No description provided for @organizeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get organizeSave;

  /// No description provided for @organizeSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get organizeSaveTitle;

  /// No description provided for @organizeSaveCopy.
  ///
  /// In en, this message translates to:
  /// **'Save as a copy'**
  String get organizeSaveCopy;

  /// No description provided for @organizeOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Replace the original'**
  String get organizeOverwrite;

  /// No description provided for @organizeOverwriteHelp.
  ///
  /// In en, this message translates to:
  /// **'Replacing can’t be undone. A copy keeps the original as it is.'**
  String get organizeOverwriteHelp;

  /// No description provided for @organizePageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String organizePageLabel(int n);

  /// No description provided for @organizeTapHint.
  ///
  /// In en, this message translates to:
  /// **'select. Long-press and drag to move'**
  String get organizeTapHint;

  /// No description provided for @annotHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get annotHighlight;

  /// No description provided for @annotUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get annotUnderline;

  /// No description provided for @annotStrike.
  ///
  /// In en, this message translates to:
  /// **'Strike'**
  String get annotStrike;

  /// No description provided for @annotPen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get annotPen;

  /// No description provided for @annotNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get annotNote;

  /// No description provided for @annotSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get annotSignature;

  /// No description provided for @annotEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get annotEraser;

  /// No description provided for @annotColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get annotColor;

  /// No description provided for @annotWidth.
  ///
  /// In en, this message translates to:
  /// **'Line width {width}'**
  String annotWidth(String width);

  /// No description provided for @annotNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get annotNoteTitle;

  /// No description provided for @annotNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get annotNoteLabel;

  /// No description provided for @annotSave.
  ///
  /// In en, this message translates to:
  /// **'Save copy'**
  String get annotSave;

  /// No description provided for @signAdd.
  ///
  /// In en, this message translates to:
  /// **'Add signature'**
  String get signAdd;

  /// No description provided for @signChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a signature'**
  String get signChoose;

  /// No description provided for @signNew.
  ///
  /// In en, this message translates to:
  /// **'New signature'**
  String get signNew;

  /// No description provided for @signSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved signature'**
  String get signSaved;

  /// No description provided for @signDrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign here'**
  String get signDrawTitle;

  /// No description provided for @signDrawArea.
  ///
  /// In en, this message translates to:
  /// **'Signature drawing area'**
  String get signDrawArea;

  /// No description provided for @signKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep for next time (up to 3)'**
  String get signKeep;

  /// No description provided for @signPlaced.
  ///
  /// In en, this message translates to:
  /// **'Signature. Drag to move'**
  String get signPlaced;

  /// No description provided for @signResize.
  ///
  /// In en, this message translates to:
  /// **'Resize signature'**
  String get signResize;

  /// No description provided for @formChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get formChoose;

  /// No description provided for @formNoFields.
  ///
  /// In en, this message translates to:
  /// **'This PDF has no fillable fields'**
  String get formNoFields;

  /// No description provided for @formNoFieldsBody.
  ///
  /// In en, this message translates to:
  /// **'You can still write on it with Annotate.'**
  String get formNoFieldsBody;

  /// No description provided for @formLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the form'**
  String get formLoadFailed;

  /// No description provided for @formFieldsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 field} other{{n} fields}}'**
  String formFieldsCount(int n);

  /// No description provided for @formPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get formPrevious;

  /// No description provided for @formNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get formNext;

  /// No description provided for @formSave.
  ///
  /// In en, this message translates to:
  /// **'Save copy'**
  String get formSave;

  /// No description provided for @formSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save the filled form'**
  String get formSaveTitle;

  /// No description provided for @formSaveEditable.
  ///
  /// In en, this message translates to:
  /// **'Save copy (still editable)'**
  String get formSaveEditable;

  /// No description provided for @formSaveFlat.
  ///
  /// In en, this message translates to:
  /// **'Save flattened copy'**
  String get formSaveFlat;

  /// No description provided for @formSaveHelp.
  ///
  /// In en, this message translates to:
  /// **'A flattened copy can’t be changed again, and looks the same in every app.'**
  String get formSaveHelp;

  /// No description provided for @redactArea.
  ///
  /// In en, this message translates to:
  /// **'Draw box'**
  String get redactArea;

  /// No description provided for @redactText.
  ///
  /// In en, this message translates to:
  /// **'Select text'**
  String get redactText;

  /// No description provided for @redactAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Drag over anything you want removed.'**
  String get redactAreaHint;

  /// No description provided for @redactTextHint.
  ///
  /// In en, this message translates to:
  /// **'Drag across the words you want removed.'**
  String get redactTextHint;

  /// No description provided for @redactMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked areas'**
  String get redactMarked;

  /// No description provided for @redactNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing marked yet.'**
  String get redactNone;

  /// No description provided for @redactAreas.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 area} other{{n} areas}}'**
  String redactAreas(int n);

  /// No description provided for @redactClearPage.
  ///
  /// In en, this message translates to:
  /// **'Clear this page'**
  String get redactClearPage;

  /// No description provided for @redactSave.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Redact} =1{Redact 1 area} other{Redact {n} areas}}'**
  String redactSave(int n);

  /// No description provided for @redactConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove marked content?'**
  String get redactConfirmTitle;

  /// No description provided for @redactConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Marked content will be permanently removed. Text on redacted pages is rebuilt using OCR. The original file stays as it was.'**
  String get redactConfirmBody;

  /// No description provided for @redactConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get redactConfirmAction;

  /// No description provided for @actionPdfTools.
  ///
  /// In en, this message translates to:
  /// **'PDF tools'**
  String get actionPdfTools;
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
