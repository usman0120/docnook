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
