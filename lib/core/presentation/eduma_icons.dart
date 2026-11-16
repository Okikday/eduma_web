import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Compact glyph descriptor used once all icons are inlined so Jaspr's
/// dart2js bundle does not pull full [Iconsax] / [HugeIconsStroke] /
/// [HugeIconsSolid] icon lookup tables.
final class EdumaIconData {
  const EdumaIconData(this.codePoint, {required this.fontFamily});

  final int codePoint;
  final String fontFamily;
}

/// Source-accurate icon registry mapped 1:1 to `../eduma` (`Iconsax`,
/// `HugeIconsStroke`, `HugeIconsSolid`).
abstract final class EdumaIcons {
  // ── Desktop Nav Rail ──────────────────────────────────────────────────────
  static const navRailHomeActive = EdumaIconData(0xecb2, fontFamily: 'FlutterIconsax');
  static const navRailHome = EdumaIconData(0xecb6, fontFamily: 'FlutterIconsax');
  static const navRailCalendarActive = EdumaIconData(0xea36, fontFamily: 'FlutterIconsax');
  static const navRailCalendar = EdumaIconData(0xea38, fontFamily: 'FlutterIconsax');
  static const navRailLibraryActive = EdumaIconData(0xe9e8, fontFamily: 'FlutterIconsax');
  static const navRailLibrary = EdumaIconData(0xe9eb, fontFamily: 'FlutterIconsax');
  static const navRailNotifications = EdumaIconData(0xee2b, fontFamily: 'FlutterIconsax');

  // ── Mobile Bottom Nav Pill & Contextual Mini FAB ──────────────────────────
  static const navBarHomeActive = EdumaIconData(0xf0cf, fontFamily: 'HugeIconsSolid');
  static const navBarHome = EdumaIconData(0xf0cf, fontFamily: 'HugeIconsStroke');
  static const navBarCalendarActive = EdumaIconData(0xebaa, fontFamily: 'HugeIconsSolid');
  static const navBarCalendar = EdumaIconData(0xebaa, fontFamily: 'HugeIconsStroke');
  static const navBarLibraryActive = EdumaIconData(0xeb20, fontFamily: 'HugeIconsSolid');
  static const navBarLibrary = EdumaIconData(0xf20f, fontFamily: 'HugeIconsStroke');
  static const fabCreateSpace = EdumaIconData(0xeb9b, fontFamily: 'FlutterIconsax');
  static const fabNewEvent = EdumaIconData(0xea3c, fontFamily: 'FlutterIconsax');
  static const fabAddLibrary = EdumaIconData(0xe9f1, fontFamily: 'FlutterIconsax');
  static const quickNote = EdumaIconData(0xeb8c, fontFamily: 'FlutterIconsax');

  // ── Home / Spaces / See-All ───────────────────────────────────────────────
  static const sparkles = EdumaIconData(0xf7cf, fontFamily: 'HugeIconsStroke');
  static const aiMagic = EdumaIconData(0xe963, fontFamily: 'HugeIconsStroke');
  static const magicWand = EdumaIconData(0xf283, fontFamily: 'HugeIconsStroke');
  static const canvas = EdumaIconData(0xec17, fontFamily: 'HugeIconsStroke');
  static const canvasSolid = EdumaIconData(0xec17, fontFamily: 'HugeIconsSolid');
  static const note = EdumaIconData(0xf43e, fontFamily: 'HugeIconsStroke');
  static const noteSolid = EdumaIconData(0xf43e, fontFamily: 'HugeIconsSolid');
  static const note01 = EdumaIconData(0xf435, fontFamily: 'HugeIconsStroke');
  static const layer = EdumaIconData(0xf1dd, fontFamily: 'HugeIconsStroke');
  static const layerSolid = EdumaIconData(0xf1dd, fontFamily: 'HugeIconsSolid');
  static const pin = EdumaIconData(0xf513, fontFamily: 'HugeIconsStroke');
  static const pinSolid = EdumaIconData(0xf513, fontFamily: 'HugeIconsSolid');
  static const pinOff = EdumaIconData(0xf512, fontFamily: 'HugeIconsStroke');
  static const playSolid = EdumaIconData(0xf52f, fontFamily: 'HugeIconsSolid');
  static const crownSolid = EdumaIconData(0xedce, fontFamily: 'HugeIconsSolid');
  static const crownFilled = EdumaIconData(0xeb09, fontFamily: 'FlutterIconsax');
  static const crown = EdumaIconData(0xeb0a, fontFamily: 'FlutterIconsax');
  static const shieldUserSolid = EdumaIconData(0xf71a, fontFamily: 'HugeIconsSolid');
  static const bookmarkSolid = EdumaIconData(0xeb23, fontFamily: 'HugeIconsSolid');
  static const bookmarkAdd = EdumaIconData(0xeb26, fontFamily: 'HugeIconsStroke');
  static const streak = EdumaIconData(0xef96, fontFamily: 'HugeIconsStroke');
  static const streakSolid = EdumaIconData(0xef96, fontFamily: 'HugeIconsSolid');
  static const search = EdumaIconData(0xef22, fontFamily: 'FlutterIconsax');
  static const searchAlt = EdumaIconData(0xef23, fontFamily: 'FlutterIconsax');
  static const searchStroke = EdumaIconData(0xf6bb, fontFamily: 'HugeIconsStroke');
  static const searchStrokeAlt = EdumaIconData(0xf6bc, fontFamily: 'HugeIconsStroke');
  static const filter = EdumaIconData(0xebd7, fontFamily: 'FlutterIconsax');
  static const sort = EdumaIconData(0xefa9, fontFamily: 'FlutterIconsax');
  static const sortAz = EdumaIconData(0xf7c3, fontFamily: 'HugeIconsStroke');
  static const refresh = EdumaIconData(0xeed9, fontFamily: 'FlutterIconsax');
  static const login = EdumaIconData(0xed3a, fontFamily: 'FlutterIconsax');
  static const loginStroke = EdumaIconData(0xf261, fontFamily: 'HugeIconsStroke');
  static const logout = EdumaIconData(0xed3e, fontFamily: 'FlutterIconsax');
  static const logoutStroke = EdumaIconData(0xf268, fontFamily: 'HugeIconsStroke');
  static const add = EdumaIconData(0xe913, fontFamily: 'FlutterIconsax');
  static const addStroke = EdumaIconData(0xe923, fontFamily: 'HugeIconsStroke');
  static const addCircle = EdumaIconData(0xe912, fontFamily: 'FlutterIconsax');
  static const addCircleHalfDot = EdumaIconData(0xe925, fontFamily: 'HugeIconsStroke');
  static const addSquare = EdumaIconData(0xe917, fontFamily: 'FlutterIconsax');
  static const archive = EdumaIconData(0xe93f, fontFamily: 'FlutterIconsax');
  static const archiveStroke = EdumaIconData(0xe9ed, fontFamily: 'HugeIconsStroke');
  static const archiveSolid = EdumaIconData(0xe9ed, fontFamily: 'HugeIconsSolid');
  static const archiveAdd = EdumaIconData(0xe93c, fontFamily: 'FlutterIconsax');
  static const archiveMinus = EdumaIconData(0xe941, fontFamily: 'FlutterIconsax');
  static const archiveTick = EdumaIconData(0xe945, fontFamily: 'FlutterIconsax');
  static const back = EdumaIconData(0xe968, fontFamily: 'FlutterIconsax');
  static const arrowLeft = EdumaIconData(0xe96b, fontFamily: 'FlutterIconsax');
  static const arrowLeftStroke = EdumaIconData(0xea11, fontFamily: 'HugeIconsStroke');
  static const chevronRight = EdumaIconData(0xe972, fontFamily: 'FlutterIconsax');
  static const arrowRightStroke = EdumaIconData(0xea21, fontFamily: 'HugeIconsStroke');
  static const arrowDown1 = EdumaIconData(0xe960, fontFamily: 'FlutterIconsax');
  static const arrowDown2 = EdumaIconData(0xe962, fontFamily: 'FlutterIconsax');
  static const arrowDownStroke = EdumaIconData(0xea00, fontFamily: 'HugeIconsStroke');
  static const arrowSwap = EdumaIconData(0xe97f, fontFamily: 'FlutterIconsax');
  static const arrowSwapHorizontal = EdumaIconData(0xe981, fontFamily: 'FlutterIconsax');
  static const arrowTransferVertical = EdumaIconData(0xe9fe, fontFamily: 'HugeIconsStroke');
  static const grid = EdumaIconData(0xec65, fontFamily: 'FlutterIconsax');
  static const element3 = EdumaIconData(0xeb95, fontFamily: 'FlutterIconsax');
  static const element4 = EdumaIconData(0xeb97, fontFamily: 'FlutterIconsax');
  static const list = EdumaIconData(0xeefb, fontFamily: 'FlutterIconsax');
  static const check = EdumaIconData(0xf95a, fontFamily: 'HugeIconsStroke');
  static const tick04 = EdumaIconData(0xf95c, fontFamily: 'HugeIconsStroke');
  static const tickCircle = EdumaIconData(0xf007, fontFamily: 'FlutterIconsax');
  static const tickCircleFilled = EdumaIconData(0xf006, fontFamily: 'FlutterIconsax');
  static const tickSquare = EdumaIconData(0xf013, fontFamily: 'FlutterIconsax');
  static const verify = EdumaIconData(0xf06b, fontFamily: 'FlutterIconsax');
  static const closePlain = EdumaIconData(0xec10, fontFamily: 'HugeIconsStroke');
  static const closeCircle = EdumaIconData(0xeab3, fontFamily: 'FlutterIconsax');
  static const closeCircleFilled = EdumaIconData(0xeab2, fontFamily: 'FlutterIconsax');
  static const cancelCircle = EdumaIconData(0xec13, fontFamily: 'HugeIconsSolid');

  // ── Space Detail & Collaboration ──────────────────────────────────────────
  static const calendarAddStroke = EdumaIconData(0xebad, fontFamily: 'HugeIconsStroke');
  static const addTeam = EdumaIconData(0xe92d, fontFamily: 'HugeIconsStroke');
  static const userGroup = EdumaIconData(0xfa3e, fontFamily: 'HugeIconsStroke');
  static const people = EdumaIconData(0xee55, fontFamily: 'FlutterIconsax');
  static const peopleFilled = EdumaIconData(0xee54, fontFamily: 'FlutterIconsax');
  static const profile2User = EdumaIconData(0xee7d, fontFamily: 'FlutterIconsax');
  static const user = EdumaIconData(0xf057, fontFamily: 'FlutterIconsax');
  static const userAdd = EdumaIconData(0xf054, fontFamily: 'FlutterIconsax');
  static const userEdit = EdumaIconData(0xf059, fontFamily: 'FlutterIconsax');
  static const userRemove = EdumaIconData(0xf05f, fontFamily: 'FlutterIconsax');
  static const userTag = EdumaIconData(0xf065, fontFamily: 'FlutterIconsax');
  static const userSearch = EdumaIconData(0xf061, fontFamily: 'FlutterIconsax');
  static const userTick = EdumaIconData(0xf067, fontFamily: 'FlutterIconsax');
  static const settings02 = EdumaIconData(0xf6f0, fontFamily: 'HugeIconsStroke');
  static const expand = EdumaIconData(0xef30, fontFamily: 'HugeIconsStroke');
  static const panelLeftClose = EdumaIconData(0xf499, fontFamily: 'HugeIconsStroke');
  static const panelLeftOpen = EdumaIconData(0xf49b, fontFamily: 'HugeIconsStroke');
  static const setting2 = EdumaIconData(0xef46, fontFamily: 'FlutterIconsax');
  static const setting4 = EdumaIconData(0xef4a, fontFamily: 'FlutterIconsax');
  static const edit = EdumaIconData(0xeb8c, fontFamily: 'FlutterIconsax');
  static const edit02 = EdumaIconData(0xeef1, fontFamily: 'HugeIconsStroke');
  static const edit04 = EdumaIconData(0xeef3, fontFamily: 'HugeIconsStroke');
  static const delete = EdumaIconData(0xf02b, fontFamily: 'FlutterIconsax');
  static const delete02 = EdumaIconData(0xee34, fontFamily: 'HugeIconsStroke');
  static const share = EdumaIconData(0xf706, fontFamily: 'HugeIconsStroke');
  static const copy = EdumaIconData(0xeaf7, fontFamily: 'FlutterIconsax');
  static const copyLink = EdumaIconData(0xeda0, fontFamily: 'HugeIconsStroke');
  static const link = EdumaIconData(0xed19, fontFamily: 'FlutterIconsax');
  static const linkAlt = EdumaIconData(0xed1e, fontFamily: 'FlutterIconsax');
  static const lock = EdumaIconData(0xed34, fontFamily: 'FlutterIconsax');
  static const lockFilled = EdumaIconData(0xed30, fontFamily: 'FlutterIconsax');
  static const unlock = EdumaIconData(0xf04f, fontFamily: 'FlutterIconsax');
  static const moreHorizontal = EdumaIconData(0xf3ad, fontFamily: 'HugeIconsStroke');
  static const more = EdumaIconData(0xede4, fontFamily: 'FlutterIconsax');
  static const moreCircle = EdumaIconData(0xede3, fontFamily: 'FlutterIconsax');
  static const flag = EdumaIconData(0xebeb, fontFamily: 'FlutterIconsax');
  static const flag03 = EdumaIconData(0xefa1, fontFamily: 'HugeIconsStroke');
  static const infoCircle = EdumaIconData(0xecde, fontFamily: 'FlutterIconsax');
  static const infoCircleStroke = EdumaIconData(0xf13d, fontFamily: 'HugeIconsStroke');
  static const clock = EdumaIconData(0xeab1, fontFamily: 'FlutterIconsax');
  static const clock01 = EdumaIconData(0xed17, fontFamily: 'HugeIconsStroke');
  static const timer = EdumaIconData(0xf016, fontFamily: 'FlutterIconsax');
  static const image = EdumaIconData(0xecd5, fontFamily: 'FlutterIconsax');
  static const gallery = EdumaIconData(0xec2d, fontFamily: 'FlutterIconsax');
  static const galleryAdd = EdumaIconData(0xec2c, fontFamily: 'FlutterIconsax');
  static const galleryEdit = EdumaIconData(0xec2f, fontFamily: 'FlutterIconsax');
  static const imageAdd = EdumaIconData(0xf114, fontFamily: 'HugeIconsStroke');
  static const camera = EdumaIconData(0xea5b, fontFamily: 'FlutterIconsax');
  static const document = EdumaIconData(0xeb60, fontFamily: 'FlutterIconsax');
  static const documentText = EdumaIconData(0xeb76, fontFamily: 'FlutterIconsax');
  static const documentText1 = EdumaIconData(0xeb75, fontFamily: 'FlutterIconsax');
  static const documentDownload = EdumaIconData(0xeb64, fontFamily: 'FlutterIconsax');
  static const documentUpload = EdumaIconData(0xeb78, fontFamily: 'FlutterIconsax');
  static const download = EdumaIconData(0xeeab, fontFamily: 'HugeIconsStroke');
  static const folder = EdumaIconData(0xebf8, fontFamily: 'FlutterIconsax');
  static const folderAdd = EdumaIconData(0xebfa, fontFamily: 'FlutterIconsax');
  static const folderOpen = EdumaIconData(0xec07, fontFamily: 'FlutterIconsax');
  static const book1 = EdumaIconData(0xe9ea, fontFamily: 'FlutterIconsax');
  static const bookUpload = EdumaIconData(0xeb21, fontFamily: 'HugeIconsStroke');
  static const fileAdd = EdumaIconData(0xef4c, fontFamily: 'HugeIconsStroke');
  static const folderAddStroke = EdumaIconData(0xefbf, fontFamily: 'HugeIconsStroke');

  // ── Calendar & Events ─────────────────────────────────────────────────────
  static const calendar = EdumaIconData(0xea38, fontFamily: 'FlutterIconsax');
  static const calendarCopy = EdumaIconData(0xea3f, fontFamily: 'FlutterIconsax');
  static const calendarAdd = EdumaIconData(0xea3c, fontFamily: 'FlutterIconsax');
  static const calendarTick = EdumaIconData(0xea47, fontFamily: 'FlutterIconsax');
  static const calendarSearch = EdumaIconData(0xea45, fontFamily: 'FlutterIconsax');
  static const repeat = EdumaIconData(0xeee3, fontFamily: 'FlutterIconsax');
  static const tag = EdumaIconData(0xefd8, fontFamily: 'FlutterIconsax');
  static const noteText = EdumaIconData(0xee20, fontFamily: 'FlutterIconsax');
  static const noteAdd = EdumaIconData(0xee17, fontFamily: 'FlutterIconsax');
  static const videoPlay = EdumaIconData(0xf079, fontFamily: 'FlutterIconsax');

  // ── Library ───────────────────────────────────────────────────────────────
  static const libraryEmpty = EdumaIconData(0xf210, fontFamily: 'HugeIconsStroke');
  static const star = EdumaIconData(0xefb7, fontFamily: 'FlutterIconsax');
  static const starFilled = EdumaIconData(0xefb4, fontFamily: 'FlutterIconsax');
  static const starSolid = EdumaIconData(0xf82d, fontFamily: 'HugeIconsSolid');
  static const global = EdumaIconData(0xec4f, fontFamily: 'FlutterIconsax');
  static const mobile = EdumaIconData(0xedb8, fontFamily: 'FlutterIconsax');
  static const warning = EdumaIconData(0xeb11, fontFamily: 'FlutterIconsax');
  static const warning2 = EdumaIconData(0xf0b8, fontFamily: 'FlutterIconsax');
  static const cloudCross = EdumaIconData(0xeabf, fontFamily: 'FlutterIconsax');
  static const minusCircle = EdumaIconData(0xedaf, fontFamily: 'FlutterIconsax');
  static const flash = EdumaIconData(0xebee, fontFamily: 'FlutterIconsax');
  static const magicStar = EdumaIconData(0xed44, fontFamily: 'FlutterIconsax');

  // ── Profile & Settings ────────────────────────────────────────────────────
  static const teacher = EdumaIconData(0xefe5, fontFamily: 'FlutterIconsax');
  static const securitySafe = EdumaIconData(0xef35, fontFamily: 'FlutterIconsax');
  static const shieldTick = EdumaIconData(0xef5f, fontFamily: 'FlutterIconsax');
  static const shieldSlash = EdumaIconData(0xef5d, fontFamily: 'FlutterIconsax');
  static const eye = EdumaIconData(0xebc7, fontFamily: 'FlutterIconsax');
  static const eyeSlash = EdumaIconData(0xebc9, fontFamily: 'FlutterIconsax');
  static const moon = EdumaIconData(0xedde, fontFamily: 'FlutterIconsax');
  static const sun = EdumaIconData(0xefd2, fontFamily: 'FlutterIconsax');
  static const colorfilter = EdumaIconData(0xeadf, fontFamily: 'FlutterIconsax');
  static const text = EdumaIconData(0xeffb, fontFamily: 'FlutterIconsax');
  static const note2 = EdumaIconData(0xee13, fontFamily: 'FlutterIconsax');
  static const searchZoomIn = EdumaIconData(0xef2b, fontFamily: 'FlutterIconsax');
  static const searchStatus = EdumaIconData(0xef27, fontFamily: 'FlutterIconsax');
  static const taskSquare = EdumaIconData(0xefe3, fontFamily: 'FlutterIconsax');
  static const export3 = EdumaIconData(0xebc2, fontFamily: 'FlutterIconsax');
  static const import1 = EdumaIconData(0xecd8, fontFamily: 'FlutterIconsax');
  static const archive1 = EdumaIconData(0xe938, fontFamily: 'FlutterIconsax');
  static const microphone2 = EdumaIconData(0xed9f, fontFamily: 'FlutterIconsax');
  static const lock1 = EdumaIconData(0xed31, fontFamily: 'FlutterIconsax');
  static const messages2 = EdumaIconData(0xed8b, fontFamily: 'FlutterIconsax');
  static const archiveBook = EdumaIconData(0xe93e, fontFamily: 'FlutterIconsax');
  static const lampCharge = EdumaIconData(0xecfb, fontFamily: 'FlutterIconsax');
  static const messageQuestion = EdumaIconData(0xed84, fontFamily: 'FlutterIconsax');
  static const whatsapp = EdumaIconData(0xf0c2, fontFamily: 'FlutterIconsax');

  // ── Notifications & Streak ────────────────────────────────────────────────
  static const notifications = EdumaIconData(0xee27, fontFamily: 'FlutterIconsax');
  static const notificationsActive = EdumaIconData(0xee25, fontFamily: 'FlutterIconsax');
  static const notificationsSolid = EdumaIconData(0xf442, fontFamily: 'HugeIconsSolid');
  static const notificationsSquare = EdumaIconData(0xf450, fontFamily: 'HugeIconsStroke');
  static const directNotification = EdumaIconData(0xeb46, fontFamily: 'FlutterIconsax');
  static const messageNotif = EdumaIconData(0xed80, fontFamily: 'FlutterIconsax');
  static const messageText = EdumaIconData(0xed96, fontFamily: 'FlutterIconsax');
  static const messageTick = EdumaIconData(0xed98, fontFamily: 'FlutterIconsax');
  static const award = EdumaIconData(0xe999, fontFamily: 'FlutterIconsax');
  static const alarm = EdumaIconData(0xe923, fontFamily: 'FlutterIconsax');
  static const medal = EdumaIconData(0xed68, fontFamily: 'FlutterIconsax');
  static const ranking = EdumaIconData(0xeeaa, fontFamily: 'FlutterIconsax');

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const mail = EdumaIconData(0xf289, fontFamily: 'HugeIconsStroke');
  static const sms = EdumaIconData(0xef99, fontFamily: 'FlutterIconsax');
  static const smsTracking = EdumaIconData(0xefa3, fontFamily: 'FlutterIconsax');
  static const smsNotification = EdumaIconData(0xef9d, fontFamily: 'FlutterIconsax');
  static const key = EdumaIconData(0xecf2, fontFamily: 'FlutterIconsax');
  static const ticket = EdumaIconData(0xf00b, fontFamily: 'FlutterIconsax');
  static const google = EdumaIconData(0xec57, fontFamily: 'FlutterIconsax');
}

/// Renders an icon from [EdumaIcons] (supporting [huge.IconData],
/// [iconsax.IconData], and inlined [EdumaIconData]) with consistent styling.
Component edumaIcon(
  Object icon, {
  int size = 20,
  String? classes,
  String? label,
}) {
  final (int codePoint, String familyClass) = switch (icon) {
    final EdumaIconData i => (
      i.codePoint,
      switch (i.fontFamily) {
        'HugeIconsSolid' => 'eduma-huge-solid',
        'HugeIconsStroke' => 'eduma-huge-stroke',
        _ => 'eduma-iconsax',
      },
    ),
    _ => throw ArgumentError.value(icon, 'icon', 'Unsupported icon type'),
  };

  final combinedClasses = [
    'eduma-icon',
    familyClass,
    if (classes != null && classes.isNotEmpty) classes,
  ].join(' ');

  return span(
    classes: combinedClasses,
    attributes: {
      'style': 'font-size: ${size}px',
      if (label case final text?) 'aria-label': text,
      if (label == null) 'aria-hidden': 'true',
    },
    [Component.text(String.fromCharCode(codePoint))],
  );
}
