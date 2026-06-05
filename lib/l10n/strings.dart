import 'package:flutter/widgets.dart';

import '../models/power_up.dart';
import '../state/app_scope.dart';

/// Lightweight, dependency-free localization. Strings are keyed by the same
/// display names the language picker uses (English, French, …), so switching
/// the saved language ([AppState.setLanguage]) instantly re-renders every
/// widget that reads [BuildContext.l10n] (they depend on the AppScope notifier).
///
/// Only the visible app-shell UI is translated here; long-form help-article
/// bodies stay in English. Add a key + its 12 values to extend coverage.
class L10n {
  const L10n(this.lang);
  final String lang;

  String _t(String key) {
    final row = _data[key];
    if (row == null) return key;
    return row[lang] ?? row['English'] ?? key;
  }

  // Navigation / home.
  String get home => _t('home');
  String get shop => _t('shop');
  String get ranks => _t('ranks');
  String get play => _t('play');
  String get level => _t('level');
  String get daily => _t('daily');

  // Settings.
  String get settings => _t('settings');
  String get paused => _t('paused');
  String get resume => _t('resume');
  String get restartQ => _t('restartQ');
  String get quitGame => _t('quitGame');
  String get language => _t('language');
  String get save => _t('save');
  String get support => _t('support');
  String get notifications => _t('notifications');
  String get theme => _t('theme');
  String get restorePurchase => _t('restorePurchase');
  String get privacyPolicy => _t('privacyPolicy');

  // Lives + fail flow.
  String get lives => _t('lives');
  String get outOfLives => _t('outOfLives');
  String get getMoreLives => _t('getMoreLives');
  String get nextLifeIn => _t('nextLifeIn');
  String get infiniteLives => _t('infiniteLives');
  String get refill => _t('refill');
  String get free => _t('free');
  String get get => _t('get');
  String get wait => _t('wait');
  String get youllLoseALife => _t('youllLoseALife');
  String get youWillLoseALife => _t('youWillLoseALife');
  String get goBack => _t('goBack');
  String get levelFailed => _t('levelFailed');
  String get tryAgain => _t('tryAgain');

  // Promos.
  String get removeWord => _t('removeWord');
  String get adsWord => _t('adsWord');
  String get specialWord => _t('specialWord');
  String get offerWord => _t('offerWord');
  String get removesAds => _t('removesAds');
  String get keepOptionalAds => _t('keepOptionalAds');
  String get noAdsLabel => _t('noAdsLabel');
  String get sale => _t('sale');
  String get piggy => _t('piggy');

  // Support.
  String get howCanWeHelp => _t('howCanWeHelp');
  String get searchArticles => _t('searchArticles');
  String get popularArticles => _t('popularArticles');
  String get needMoreHelp => _t('needMoreHelp');
  String get chatWithUs => _t('chatWithUs');

  // Shop.
  String get coinsWord => _t('coinsWord');
  String get full => _t('full');
  String get removeInterstitial => _t('removeInterstitial');
  String get dailyGift => _t('dailyGift');
  String get claim => _t('claim');
  String get nextIn => _t('nextIn');
  String get bestValue => _t('bestValue');

  // Leaderboard.
  String get yourProgress => _t('yourProgress');
  String get totalStars => _t('totalStars');
  String get levelsCleared => _t('levelsCleared');
  String get dayStreak => _t('dayStreak');
  String get coinsTitle => _t('coinsTitle');
  String get globalLeaderboards => _t('globalLeaderboards');

  // Piggy bank.
  String get breakWord => _t('breakWord');
  String get bankWord => _t('bankWord');
  String get beatLevels => _t('beatLevels');
  String get fillPiggy => _t('fillPiggy');
  String get unlockRewards => _t('unlockRewards');
  String get breakPiggyToCollect => _t('breakPiggyToCollect');
  String get tapToContinue => _t('tapToContinue');

  // Daily reward.
  String get dailyReward => _t('dailyReward');
  String get freeGift => _t('freeGift');
  String get week => _t('week');
  String get day => _t('day');
  String get collect => _t('collect');
  String get continueWord => _t('continueWord');
  String get claimed => _t('claimed');
  String dayTapCollect(int n) => _t('dayTapCollect').replaceFirst('{n}', '$n');
  String comeBackForDay(int n) =>
      _t('comeBackForDay').replaceFirst('{n}', '$n');
  String dayLabel(int n) => '$day $n';
  String weekLabel(int w) => '$week $w';

  // Booster.
  String get getBooster => _t('getBooster');
  String boosterTitle(PowerUp p) =>
      _t('getABooster').replaceFirst('{x}', powerName(p));
  String boosterAdded(PowerUp p) =>
      _t('boosterAdded').replaceFirst('{x}', powerName(p));
  String needCoinsBundle(int n) =>
      _t('needCoinsBundle').replaceFirst('{n}', '$n');

  // Purchase dialogs.
  String get purchaseComplete => _t('purchaseComplete');
  String get adsRemovedThanks => _t('adsRemovedThanks');
  String get purchaseFailedTitle => _t('purchaseFailedTitle');
  String get somethingWrong => _t('somethingWrong');
  String get okay => _t('okay');

  // Profile.
  String get username => _t('username');
  String get yourName => _t('yourName');
  String get createUsername => _t('createUsername');
  String get profile => _t('profile');
  String get unlockFrameLater => _t('unlockFrameLater');
  String get comingSoon => _t('comingSoon');
  String get avatar => _t('avatar');
  String get frame => _t('frame');
  String get badge => _t('badge');

  // Misc overlays.
  String get processing => _t('processing');
  String get tutorialTap => _t('tutorialTap');
  String get newPower => _t('newPower');
  String get gotIt => _t('gotIt');

  // Power-up names + intro descriptions.
  String get pHint => _t('pHint');
  String get pEraser => _t('pEraser');
  String get pMagic => _t('pMagic');
  String get pUndo => _t('pUndo');
  String powerName(PowerUp p) => switch (p) {
        PowerUp.hint => pHint,
        PowerUp.eraser => pEraser,
        PowerUp.magic => pMagic,
        PowerUp.undo => pUndo,
      };
  String powerDesc(PowerUp p) => switch (p) {
        PowerUp.hint => _t('powerDescHint'),
        PowerUp.eraser => _t('powerDescEraser'),
        PowerUp.magic => _t('powerDescMagic'),
        PowerUp.undo => _t('powerDescUndo'),
      };
}

extension L10nX on BuildContext {
  /// The translator for the currently-selected language. Reading this in a
  /// build method subscribes the widget to language changes.
  L10n get l10n => L10n(appState.language);
}

// key -> { language name -> translation }
const Map<String, Map<String, String>> _data = {
  'home': {
    'English': 'Home', 'French': 'Accueil', 'Spanish': 'Inicio',
    'Dutch': 'Home', 'German': 'Start', 'Turkish': 'Ana Sayfa',
    'Swedish': 'Hem', 'Italian': 'Home', 'Japanese': 'ホーム',
    'Korean': '홈', 'Russian': 'Главная', 'Portuguese': 'Início',
  },
  'shop': {
    'English': 'Shop', 'French': 'Boutique', 'Spanish': 'Tienda',
    'Dutch': 'Winkel', 'German': 'Shop', 'Turkish': 'Mağaza',
    'Swedish': 'Butik', 'Italian': 'Negozio', 'Japanese': 'ショップ',
    'Korean': '상점', 'Russian': 'Магазин', 'Portuguese': 'Loja',
  },
  'ranks': {
    'English': 'Ranks', 'French': 'Classement', 'Spanish': 'Rangos',
    'Dutch': 'Ranglijst', 'German': 'Ränge', 'Turkish': 'Sıralama',
    'Swedish': 'Ranking', 'Italian': 'Classifica', 'Japanese': 'ランキング',
    'Korean': '순위', 'Russian': 'Рейтинг', 'Portuguese': 'Ranking',
  },
  'play': {
    'English': 'PLAY', 'French': 'JOUER', 'Spanish': 'JUGAR',
    'Dutch': 'SPELEN', 'German': 'SPIELEN', 'Turkish': 'OYNA',
    'Swedish': 'SPELA', 'Italian': 'GIOCA', 'Japanese': 'プレイ',
    'Korean': '플레이', 'Russian': 'ИГРАТЬ', 'Portuguese': 'JOGAR',
  },
  'level': {
    'English': 'Level', 'French': 'Niveau', 'Spanish': 'Nivel',
    'Dutch': 'Level', 'German': 'Level', 'Turkish': 'Seviye',
    'Swedish': 'Nivå', 'Italian': 'Livello', 'Japanese': 'レベル',
    'Korean': '레벨', 'Russian': 'Уровень', 'Portuguese': 'Nível',
  },
  'daily': {
    'English': 'Daily', 'French': 'Quotidien', 'Spanish': 'Diario',
    'Dutch': 'Dagelijks', 'German': 'Täglich', 'Turkish': 'Günlük',
    'Swedish': 'Daglig', 'Italian': 'Giornaliero', 'Japanese': 'デイリー',
    'Korean': '데일리', 'Russian': 'Ежедневно', 'Portuguese': 'Diário',
  },
  'settings': {
    'English': 'Settings', 'French': 'Paramètres', 'Spanish': 'Ajustes',
    'Dutch': 'Instellingen', 'German': 'Einstellungen', 'Turkish': 'Ayarlar',
    'Swedish': 'Inställningar', 'Italian': 'Impostazioni', 'Japanese': '設定',
    'Korean': '설정', 'Russian': 'Настройки', 'Portuguese': 'Configurações',
  },
  'paused': {
    'English': 'Paused', 'French': 'En pause', 'Spanish': 'En pausa',
    'Dutch': 'Gepauzeerd', 'German': 'Pausiert', 'Turkish': 'Duraklatıldı',
    'Swedish': 'Pausad', 'Italian': 'In pausa', 'Japanese': '一時停止',
    'Korean': '일시정지', 'Russian': 'Пауза', 'Portuguese': 'Pausado',
  },
  'resume': {
    'English': 'RESUME', 'French': 'REPRENDRE', 'Spanish': 'REANUDAR',
    'Dutch': 'HERVATTEN', 'German': 'FORTSETZEN', 'Turkish': 'DEVAM ET',
    'Swedish': 'FORTSÄTT', 'Italian': 'RIPRENDI', 'Japanese': '再開',
    'Korean': '계속하기', 'Russian': 'ПРОДОЛЖИТЬ', 'Portuguese': 'CONTINUAR',
  },
  'restartQ': {
    'English': 'Restart?', 'French': 'Recommencer ?', 'Spanish': '¿Reiniciar?',
    'Dutch': 'Opnieuw?', 'German': 'Neustart?', 'Turkish': 'Yeniden başlat?',
    'Swedish': 'Starta om?', 'Italian': 'Ricominciare?', 'Japanese': 'やり直す？',
    'Korean': '다시 시작?', 'Russian': 'Заново?', 'Portuguese': 'Reiniciar?',
  },
  'quitGame': {
    'English': 'Quit Game', 'French': 'Quitter', 'Spanish': 'Salir',
    'Dutch': 'Afsluiten', 'German': 'Beenden', 'Turkish': 'Çıkış',
    'Swedish': 'Avsluta', 'Italian': 'Esci', 'Japanese': 'ゲーム終了',
    'Korean': '게임 종료', 'Russian': 'Выйти', 'Portuguese': 'Sair',
  },
  'language': {
    'English': 'Language', 'French': 'Langue', 'Spanish': 'Idioma',
    'Dutch': 'Taal', 'German': 'Sprache', 'Turkish': 'Dil',
    'Swedish': 'Språk', 'Italian': 'Lingua', 'Japanese': '言語',
    'Korean': '언어', 'Russian': 'Язык', 'Portuguese': 'Idioma',
  },
  'save': {
    'English': 'SAVE', 'French': 'ENREGISTRER', 'Spanish': 'GUARDAR',
    'Dutch': 'OPSLAAN', 'German': 'SPEICHERN', 'Turkish': 'KAYDET',
    'Swedish': 'SPARA', 'Italian': 'SALVA', 'Japanese': '保存',
    'Korean': '저장', 'Russian': 'СОХРАНИТЬ', 'Portuguese': 'SALVAR',
  },
  'support': {
    'English': 'SUPPORT', 'French': 'ASSISTANCE', 'Spanish': 'SOPORTE',
    'Dutch': 'SUPPORT', 'German': 'SUPPORT', 'Turkish': 'DESTEK',
    'Swedish': 'SUPPORT', 'Italian': 'SUPPORTO', 'Japanese': 'サポート',
    'Korean': '지원', 'Russian': 'ПОДДЕРЖКА', 'Portuguese': 'SUPORTE',
  },
  'notifications': {
    'English': 'NOTIFICATIONS', 'French': 'NOTIFICATIONS',
    'Spanish': 'NOTIFICACIONES', 'Dutch': 'MELDINGEN',
    'German': 'BENACHRICHTIGUNGEN', 'Turkish': 'BİLDİRİMLER',
    'Swedish': 'AVISERINGAR', 'Italian': 'NOTIFICHE', 'Japanese': '通知',
    'Korean': '알림', 'Russian': 'УВЕДОМЛЕНИЯ', 'Portuguese': 'NOTIFICAÇÕES',
  },
  'theme': {
    'English': 'THEME', 'French': 'THÈME', 'Spanish': 'TEMA',
    'Dutch': 'THEMA', 'German': 'DESIGN', 'Turkish': 'TEMA',
    'Swedish': 'TEMA', 'Italian': 'TEMA', 'Japanese': 'テーマ',
    'Korean': '테마', 'Russian': 'ТЕМА', 'Portuguese': 'TEMA',
  },
  'restorePurchase': {
    'English': 'RESTORE PURCHASE', 'French': "RESTAURER L'ACHAT",
    'Spanish': 'RESTAURAR COMPRA', 'Dutch': 'AANKOOP HERSTELLEN',
    'German': 'KAUF WIEDERHERSTELLEN', 'Turkish': 'SATIN ALMAYI GERİ YÜKLE',
    'Swedish': 'ÅTERSTÄLL KÖP', 'Italian': 'RIPRISTINA ACQUISTO',
    'Japanese': '購入を復元', 'Korean': '구매 복원',
    'Russian': 'ВОССТАНОВИТЬ ПОКУПКУ', 'Portuguese': 'RESTAURAR COMPRA',
  },
  'privacyPolicy': {
    'English': 'PRIVACY POLICY', 'French': 'CONFIDENTIALITÉ',
    'Spanish': 'PRIVACIDAD', 'Dutch': 'PRIVACYBELEID',
    'German': 'DATENSCHUTZ', 'Turkish': 'GİZLİLİK POLİTİKASI',
    'Swedish': 'INTEGRITETSPOLICY', 'Italian': 'PRIVACY',
    'Japanese': 'プライバシーポリシー', 'Korean': '개인정보 처리방침',
    'Russian': 'КОНФИДЕНЦИАЛЬНОСТЬ', 'Portuguese': 'PRIVACIDADE',
  },
  'lives': {
    'English': 'Lives', 'French': 'Vies', 'Spanish': 'Vidas',
    'Dutch': 'Levens', 'German': 'Leben', 'Turkish': 'Canlar',
    'Swedish': 'Liv', 'Italian': 'Vite', 'Japanese': 'ライフ',
    'Korean': '라이프', 'Russian': 'Жизни', 'Portuguese': 'Vidas',
  },
  'outOfLives': {
    'English': 'OUT OF LIVES', 'French': 'PLUS DE VIES', 'Spanish': 'SIN VIDAS',
    'Dutch': 'GEEN LEVENS MEER', 'German': 'KEINE LEBEN MEHR',
    'Turkish': 'CAN KALMADI', 'Swedish': 'SLUT PÅ LIV',
    'Italian': 'VITE ESAURITE', 'Japanese': 'ライフ切れ',
    'Korean': '라이프 없음', 'Russian': 'НЕТ ЖИЗНЕЙ', 'Portuguese': 'SEM VIDAS',
  },
  'getMoreLives': {
    'English': 'GET MORE LIVES!', 'French': 'PLUS DE VIES !',
    'Spanish': '¡MÁS VIDAS!', 'Dutch': 'MEER LEVENS!',
    'German': 'MEHR LEBEN!', 'Turkish': 'DAHA FAZLA CAN!',
    'Swedish': 'FLER LIV!', 'Italian': 'PIÙ VITE!', 'Japanese': 'ライフを増やそう！',
    'Korean': '라이프 받기!', 'Russian': 'БОЛЬШЕ ЖИЗНЕЙ!',
    'Portuguese': 'MAIS VIDAS!',
  },
  'nextLifeIn': {
    'English': 'NEXT LIFE IN', 'French': 'PROCHAINE VIE DANS',
    'Spanish': 'PRÓXIMA VIDA EN', 'Dutch': 'VOLGEND LEVEN OVER',
    'German': 'NÄCHSTES LEBEN IN', 'Turkish': 'SONRAKİ CAN',
    'Swedish': 'NÄSTA LIV OM', 'Italian': 'PROSSIMA VITA TRA',
    'Japanese': '次のライフまで', 'Korean': '다음 라이프까지',
    'Russian': 'СЛЕДУЮЩАЯ ЖИЗНЬ', 'Portuguese': 'PRÓXIMA VIDA EM',
  },
  'infiniteLives': {
    'English': 'INFINITE LIVES', 'French': 'VIES INFINIES',
    'Spanish': 'VIDAS INFINITAS', 'Dutch': 'ONEINDIGE LEVENS',
    'German': 'UNENDLICHE LEBEN', 'Turkish': 'SONSUZ CAN',
    'Swedish': 'OÄNDLIGA LIV', 'Italian': 'VITE INFINITE',
    'Japanese': '無限ライフ', 'Korean': '무한 라이프',
    'Russian': 'БЕСКОНЕЧНЫЕ ЖИЗНИ', 'Portuguese': 'VIDAS INFINITAS',
  },
  'refill': {
    'English': 'REFILL', 'French': 'RECHARGER', 'Spanish': 'RELLENAR',
    'Dutch': 'BIJVULLEN', 'German': 'AUFFÜLLEN', 'Turkish': 'DOLDUR',
    'Swedish': 'FYLL PÅ', 'Italian': 'RICARICA', 'Japanese': '補充',
    'Korean': '채우기', 'Russian': 'ПОПОЛНИТЬ', 'Portuguese': 'REABASTECER',
  },
  'free': {
    'English': 'FREE', 'French': 'GRATUIT', 'Spanish': 'GRATIS',
    'Dutch': 'GRATIS', 'German': 'GRATIS', 'Turkish': 'ÜCRETSİZ',
    'Swedish': 'GRATIS', 'Italian': 'GRATIS', 'Japanese': '無料',
    'Korean': '무료', 'Russian': 'БЕСПЛАТНО', 'Portuguese': 'GRÁTIS',
  },
  'get': {
    'English': 'GET', 'French': 'OBTENIR', 'Spanish': 'OBTENER',
    'Dutch': 'KRIJG', 'German': 'HOLEN', 'Turkish': 'AL',
    'Swedish': 'HÄMTA', 'Italian': 'OTTIENI', 'Japanese': '入手',
    'Korean': '받기', 'Russian': 'ВЗЯТЬ', 'Portuguese': 'OBTER',
  },
  'wait': {
    'English': 'WAIT!', 'French': 'ATTENDS !', 'Spanish': '¡ESPERA!',
    'Dutch': 'WACHT!', 'German': 'WARTE!', 'Turkish': 'DUR!',
    'Swedish': 'VÄNTA!', 'Italian': 'ASPETTA!', 'Japanese': 'まって！',
    'Korean': '잠깐!', 'Russian': 'СТОЙ!', 'Portuguese': 'ESPERE!',
  },
  'youllLoseALife': {
    'English': "You'll lose a life\nif you leave now!",
    'French': 'Tu perdras une vie\nsi tu pars maintenant !',
    'Spanish': '¡Perderás una vida\nsi sales ahora!',
    'Dutch': 'Je verliest een leven\nals je nu stopt!',
    'German': 'Du verlierst ein Leben,\nwenn du jetzt gehst!',
    'Turkish': 'Şimdi çıkarsan\nbir can kaybedersin!',
    'Swedish': 'Du förlorar ett liv\nom du lämnar nu!',
    'Italian': 'Perderai una vita\nse esci ora!',
    'Japanese': '今やめると\nライフを1つ失います！',
    'Korean': '지금 나가면\n라이프를 잃어요!',
    'Russian': 'Вы потеряете жизнь,\nесли выйдете сейчас!',
    'Portuguese': 'Você perderá uma vida\nse sair agora!',
  },
  'youWillLoseALife': {
    'English': 'YOU WILL LOSE A LIFE!', 'French': 'TU VAS PERDRE UNE VIE !',
    'Spanish': '¡PERDERÁS UNA VIDA!', 'Dutch': 'JE VERLIEST EEN LEVEN!',
    'German': 'DU VERLIERST EIN LEBEN!', 'Turkish': 'BİR CAN KAYBEDECEKSİN!',
    'Swedish': 'DU FÖRLORAR ETT LIV!', 'Italian': 'PERDERAI UNA VITA!',
    'Japanese': 'ライフを1つ失います！', 'Korean': '라이프를 잃게 됩니다!',
    'Russian': 'ВЫ ПОТЕРЯЕТЕ ЖИЗНЬ!', 'Portuguese': 'VOCÊ PERDERÁ UMA VIDA!',
  },
  'goBack': {
    'English': 'GO BACK', 'French': 'RETOUR', 'Spanish': 'VOLVER',
    'Dutch': 'TERUG', 'German': 'ZURÜCK', 'Turkish': 'GERİ DÖN',
    'Swedish': 'TILLBAKA', 'Italian': 'INDIETRO', 'Japanese': 'もどる',
    'Korean': '돌아가기', 'Russian': 'НАЗАД', 'Portuguese': 'VOLTAR',
  },
  'levelFailed': {
    'English': 'LEVEL FAILED', 'French': 'NIVEAU ÉCHOUÉ',
    'Spanish': 'NIVEL FALLIDO', 'Dutch': 'LEVEL MISLUKT',
    'German': 'LEVEL VERLOREN', 'Turkish': 'SEVİYE BAŞARISIZ',
    'Swedish': 'NIVÅ MISSLYCKAD', 'Italian': 'LIVELLO FALLITO',
    'Japanese': 'レベル失敗', 'Korean': '레벨 실패',
    'Russian': 'УРОВЕНЬ ПРОВАЛЕН', 'Portuguese': 'NÍVEL FALHOU',
  },
  'tryAgain': {
    'English': "Don't give up —\ntry this level again!",
    'French': "N'abandonne pas —\nréessaie ce niveau !",
    'Spanish': '¡No te rindas —\nintenta este nivel otra vez!',
    'Dutch': 'Geef niet op —\nprobeer dit level opnieuw!',
    'German': 'Gib nicht auf —\nversuch das Level erneut!',
    'Turkish': 'Pes etme —\nbu seviyeyi tekrar dene!',
    'Swedish': 'Ge inte upp —\nförsök igen!',
    'Italian': 'Non mollare —\nriprova questo livello!',
    'Japanese': 'あきらめないで—\nもう一度挑戦！',
    'Korean': '포기하지 마세요 —\n다시 도전해 보세요!',
    'Russian': 'Не сдавайся —\nпопробуй ещё раз!',
    'Portuguese': 'Não desista —\ntente este nível de novo!',
  },
  'removeWord': {
    'English': 'REMOVE', 'French': 'SANS', 'Spanish': 'SIN',
    'Dutch': 'GEEN', 'German': 'KEINE', 'Turkish': 'REKLAMI',
    'Swedish': 'TA BORT', 'Italian': 'NIENTE', 'Japanese': '広告',
    'Korean': '광고', 'Russian': 'УБРАТЬ', 'Portuguese': 'SEM',
  },
  'adsWord': {
    'English': 'ADS', 'French': 'PUB', 'Spanish': 'ANUNCIOS',
    'Dutch': 'ADS', 'German': 'WERBUNG', 'Turkish': 'KALDIR',
    'Swedish': 'ANNONSER', 'Italian': 'PUB', 'Japanese': 'なし',
    'Korean': '없애기', 'Russian': 'РЕКЛАМУ', 'Portuguese': 'ANÚNCIOS',
  },
  'specialWord': {
    'English': 'SPECIAL', 'French': 'OFFRE', 'Spanish': 'OFERTA',
    'Dutch': 'SPECIALE', 'German': 'SPECIAL', 'Turkish': 'ÖZEL',
    'Swedish': 'SPECIAL', 'Italian': 'OFFERTA', 'Japanese': 'スペシャル',
    'Korean': '스페셜', 'Russian': 'СПЕЦ', 'Portuguese': 'OFERTA',
  },
  'offerWord': {
    'English': 'OFFER', 'French': 'SPÉCIALE', 'Spanish': 'ESPECIAL',
    'Dutch': 'AANBIEDING', 'German': 'ANGEBOT', 'Turkish': 'TEKLİF',
    'Swedish': 'ERBJUDANDE', 'Italian': 'SPECIALE', 'Japanese': 'オファー',
    'Korean': '오퍼', 'Russian': 'ОФФЕР', 'Portuguese': 'ESPECIAL',
  },
  'removesAds': {
    'English': 'Removes banner &\nfull screen Ads',
    'French': 'Supprime les bannières &\nles pubs plein écran',
    'Spanish': 'Elimina banners y\nanuncios de pantalla completa',
    'Dutch': 'Verwijdert banner- &\nschermvullende advertenties',
    'German': 'Entfernt Banner- &\nVollbild-Werbung',
    'Turkish': 'Banner ve tam ekran\nreklamları kaldırır',
    'Swedish': 'Tar bort banner- &\nhelskärmsannonser',
    'Italian': 'Rimuove banner e\npubblicità a schermo intero',
    'Japanese': 'バナーと全画面広告を\n削除します',
    'Korean': '배너 및 전면 광고를\n제거합니다',
    'Russian': 'Убирает баннеры и\nполноэкранную рекламу',
    'Portuguese': 'Remove banners e\nanúncios em tela cheia',
  },
  'keepOptionalAds': {
    'English': 'Keep optional Ads for rewards',
    'French': 'Gardez les pubs facultatives pour les récompenses',
    'Spanish': 'Mantén los anuncios opcionales por recompensas',
    'Dutch': 'Behoud optionele advertenties voor beloningen',
    'German': 'Optionale Werbung für Belohnungen bleibt',
    'Turkish': 'Ödüller için isteğe bağlı reklamlar kalır',
    'Swedish': 'Behåll valfria annonser för belöningar',
    'Italian': 'Mantieni le pubblicità opzionali per i premi',
    'Japanese': '報酬用の任意広告は残ります',
    'Korean': '보상용 선택 광고는 유지됩니다',
    'Russian': 'Реклама за награды остаётся',
    'Portuguese': 'Mantenha anúncios opcionais por recompensas',
  },
  'noAdsLabel': {
    'English': 'NO ADS', 'French': 'SANS PUB', 'Spanish': 'SIN ANUNCIOS',
    'Dutch': 'GEEN ADS', 'German': 'KEINE WERBUNG', 'Turkish': 'REKLAMSIZ',
    'Swedish': 'INGA ANNONSER', 'Italian': 'NO PUB', 'Japanese': '広告なし',
    'Korean': '광고 제거', 'Russian': 'БЕЗ РЕКЛАМЫ', 'Portuguese': 'SEM ANÚNCIOS',
  },
  'sale': {
    'English': 'SALE', 'French': 'SOLDE', 'Spanish': 'OFERTA',
    'Dutch': 'KORTING', 'German': 'SALE', 'Turkish': 'İNDİRİM',
    'Swedish': 'REA', 'Italian': 'SCONTO', 'Japanese': 'セール',
    'Korean': '세일', 'Russian': 'СКИДКА', 'Portuguese': 'PROMO',
  },
  'piggy': {
    'English': 'PIGGY', 'French': 'TIRELIRE', 'Spanish': 'HUCHA',
    'Dutch': 'SPAARPOT', 'German': 'SPARSCHWEIN', 'Turkish': 'KUMBARA',
    'Swedish': 'SPARGRIS', 'Italian': 'SALVADANAIO', 'Japanese': '貯金箱',
    'Korean': '저금통', 'Russian': 'КОПИЛКА', 'Portuguese': 'COFRINHO',
  },
  'howCanWeHelp': {
    'English': 'Hi, how can we help you?',
    'French': 'Bonjour, comment vous aider ?',
    'Spanish': 'Hola, ¿cómo podemos ayudarte?',
    'Dutch': 'Hoi, hoe kunnen we je helpen?',
    'German': 'Hallo, wie können wir helfen?',
    'Turkish': 'Merhaba, nasıl yardımcı olabiliriz?',
    'Swedish': 'Hej, hur kan vi hjälpa dig?',
    'Italian': 'Ciao, come possiamo aiutarti?',
    'Japanese': 'こんにちは、どうされましたか？',
    'Korean': '안녕하세요, 무엇을 도와드릴까요?',
    'Russian': 'Здравствуйте, чем помочь?',
    'Portuguese': 'Olá, como podemos ajudar?',
  },
  'searchArticles': {
    'English': 'Search for articles', 'French': 'Rechercher des articles',
    'Spanish': 'Buscar artículos', 'Dutch': 'Zoek artikelen',
    'German': 'Artikel suchen', 'Turkish': 'Makale ara',
    'Swedish': 'Sök artiklar', 'Italian': 'Cerca articoli',
    'Japanese': '記事を検索', 'Korean': '도움말 검색',
    'Russian': 'Поиск статей', 'Portuguese': 'Buscar artigos',
  },
  'popularArticles': {
    'English': 'POPULAR ARTICLES', 'French': 'ARTICLES POPULAIRES',
    'Spanish': 'ARTÍCULOS POPULARES', 'Dutch': 'POPULAIRE ARTIKELEN',
    'German': 'BELIEBTE ARTIKEL', 'Turkish': 'POPÜLER MAKALELER',
    'Swedish': 'POPULÄRA ARTIKLAR', 'Italian': 'ARTICOLI POPOLARI',
    'Japanese': '人気の記事', 'Korean': '인기 도움말',
    'Russian': 'ПОПУЛЯРНОЕ', 'Portuguese': 'ARTIGOS POPULARES',
  },
  'needMoreHelp': {
    'English': 'Need more help?', 'French': "Besoin d'aide ?",
    'Spanish': '¿Necesitas más ayuda?', 'Dutch': 'Meer hulp nodig?',
    'German': 'Brauchst du mehr Hilfe?', 'Turkish': 'Daha fazla yardım?',
    'Swedish': 'Behöver du mer hjälp?', 'Italian': 'Serve altro aiuto?',
    'Japanese': 'もっとヘルプが必要ですか？', 'Korean': '도움이 더 필요하세요?',
    'Russian': 'Нужна помощь?', 'Portuguese': 'Precisa de mais ajuda?',
  },
  'chatWithUs': {
    'English': 'CHAT WITH US', 'French': 'CONTACTEZ-NOUS',
    'Spanish': 'CHATEA CON NOSOTROS', 'Dutch': 'CHAT MET ONS',
    'German': 'SCHREIB UNS', 'Turkish': 'BİZE YAZIN',
    'Swedish': 'CHATTA MED OSS', 'Italian': 'SCRIVICI',
    'Japanese': 'お問い合わせ', 'Korean': '문의하기',
    'Russian': 'НАПИШИТЕ НАМ', 'Portuguese': 'FALE CONOSCO',
  },
  'coinsWord': {
    'English': 'COINS', 'French': 'PIÈCES', 'Spanish': 'MONEDAS',
    'Dutch': 'MUNTEN', 'German': 'MÜNZEN', 'Turkish': 'ALTIN',
    'Swedish': 'MYNT', 'Italian': 'MONETE', 'Japanese': 'コイン',
    'Korean': '코인', 'Russian': 'МОНЕТ', 'Portuguese': 'MOEDAS',
  },
  'full': {
    'English': 'FULL', 'French': 'PLEIN', 'Spanish': 'LLENO',
    'Dutch': 'VOL', 'German': 'VOLL', 'Turkish': 'DOLU',
    'Swedish': 'FULLT', 'Italian': 'PIENO', 'Japanese': '満タン',
    'Korean': '가득', 'Russian': 'ПОЛНО', 'Portuguese': 'CHEIO',
  },
  'removeInterstitial': {
    'English': 'Remove interstitial and banner ads',
    'French': 'Supprime les pubs interstitielles et bannières',
    'Spanish': 'Elimina anuncios intersticiales y banners',
    'Dutch': 'Verwijdert paginagrote en banneradvertenties',
    'German': 'Entfernt Interstitial- und Bannerwerbung',
    'Turkish': 'Geçiş ve banner reklamları kaldırır',
    'Swedish': 'Tar bort helsides- och bannerannonser',
    'Italian': 'Rimuove gli annunci interstiziali e banner',
    'Japanese': '全画面広告とバナー広告を削除',
    'Korean': '전면 광고와 배너 광고를 제거',
    'Russian': 'Убирает межстраничную и баннерную рекламу',
    'Portuguese': 'Remove anúncios intersticiais e banners',
  },
  'dailyGift': {
    'English': 'DAILY GIFT', 'French': 'CADEAU DU JOUR',
    'Spanish': 'REGALO DIARIO', 'Dutch': 'DAGELIJKS CADEAU',
    'German': 'TAGESGESCHENK', 'Turkish': 'GÜNLÜK HEDİYE',
    'Swedish': 'DAGLIG GÅVA', 'Italian': 'REGALO GIORNALIERO',
    'Japanese': 'デイリーギフト', 'Korean': '데일리 선물',
    'Russian': 'ЕЖЕДНЕВНЫЙ ПОДАРОК', 'Portuguese': 'PRESENTE DIÁRIO',
  },
  'claim': {
    'English': 'CLAIM', 'French': 'RÉCLAMER', 'Spanish': 'RECLAMAR',
    'Dutch': 'OPHALEN', 'German': 'ABHOLEN', 'Turkish': 'AL',
    'Swedish': 'HÄMTA', 'Italian': 'RISCATTA', 'Japanese': '受け取る',
    'Korean': '받기', 'Russian': 'ЗАБРАТЬ', 'Portuguese': 'RESGATAR',
  },
  'nextIn': {
    'English': 'NEXT IN ', 'French': 'PROCHAIN DANS ',
    'Spanish': 'PRÓXIMO EN ', 'Dutch': 'VOLGENDE OVER ',
    'German': 'NÄCHSTES IN ', 'Turkish': 'SONRAKİ ',
    'Swedish': 'NÄSTA OM ', 'Italian': 'PROSSIMO TRA ',
    'Japanese': '次まで ', 'Korean': '다음까지 ',
    'Russian': 'СЛЕДУЮЩИЙ ЧЕРЕЗ ', 'Portuguese': 'PRÓXIMO EM ',
  },
  'bestValue': {
    'English': 'BEST VALUE', 'French': 'MEILLEURE OFFRE',
    'Spanish': 'MEJOR VALOR', 'Dutch': 'BESTE DEAL',
    'German': 'TOP-ANGEBOT', 'Turkish': 'EN İYİ FİYAT',
    'Swedish': 'BÄSTA VÄRDE', 'Italian': 'MIGLIORE OFFERTA',
    'Japanese': 'お買い得', 'Korean': '최고 혜택',
    'Russian': 'ВЫГОДНО', 'Portuguese': 'MELHOR OFERTA',
  },
  'yourProgress': {
    'English': 'Your Progress', 'French': 'Ta progression',
    'Spanish': 'Tu progreso', 'Dutch': 'Jouw voortgang',
    'German': 'Dein Fortschritt', 'Turkish': 'İlerlemen',
    'Swedish': 'Dina framsteg', 'Italian': 'I tuoi progressi',
    'Japanese': 'あなたの進捗', 'Korean': '내 진행 상황',
    'Russian': 'Твой прогресс', 'Portuguese': 'Seu progresso',
  },
  'totalStars': {
    'English': 'Total Stars', 'French': 'Étoiles totales',
    'Spanish': 'Estrellas totales', 'Dutch': 'Totaal sterren',
    'German': 'Sterne gesamt', 'Turkish': 'Toplam Yıldız',
    'Swedish': 'Totalt antal stjärnor', 'Italian': 'Stelle totali',
    'Japanese': '合計スター', 'Korean': '총 별',
    'Russian': 'Всего звёзд', 'Portuguese': 'Estrelas totais',
  },
  'levelsCleared': {
    'English': 'Levels Cleared', 'French': 'Niveaux terminés',
    'Spanish': 'Niveles completados', 'Dutch': 'Voltooide levels',
    'German': 'Geschaffte Level', 'Turkish': 'Tamamlanan Seviye',
    'Swedish': 'Klarade nivåer', 'Italian': 'Livelli completati',
    'Japanese': 'クリアしたレベル', 'Korean': '클리어한 레벨',
    'Russian': 'Уровней пройдено', 'Portuguese': 'Níveis concluídos',
  },
  'dayStreak': {
    'English': 'Day Streak', 'French': 'Série de jours',
    'Spanish': 'Racha de días', 'Dutch': 'Dagenreeks',
    'German': 'Tagesserie', 'Turkish': 'Gün Serisi',
    'Swedish': 'Dagars svit', 'Italian': 'Serie di giorni',
    'Japanese': '連続日数', 'Korean': '연속 일수',
    'Russian': 'Серия дней', 'Portuguese': 'Sequência de dias',
  },
  'coinsTitle': {
    'English': 'Coins', 'French': 'Pièces', 'Spanish': 'Monedas',
    'Dutch': 'Munten', 'German': 'Münzen', 'Turkish': 'Altın',
    'Swedish': 'Mynt', 'Italian': 'Monete', 'Japanese': 'コイン',
    'Korean': '코인', 'Russian': 'Монеты', 'Portuguese': 'Moedas',
  },
  'globalLeaderboards': {
    'English': 'Global leaderboards coming soon!',
    'French': 'Classements mondiaux bientôt disponibles !',
    'Spanish': '¡Clasificaciones globales muy pronto!',
    'Dutch': 'Wereldwijde ranglijsten komen eraan!',
    'German': 'Globale Bestenlisten kommen bald!',
    'Turkish': 'Küresel sıralamalar çok yakında!',
    'Swedish': 'Globala topplistor kommer snart!',
    'Italian': 'Classifiche globali in arrivo!',
    'Japanese': 'グローバルランキングは近日公開！',
    'Korean': '글로벌 순위표가 곧 나옵니다!',
    'Russian': 'Мировые рейтинги скоро появятся!',
    'Portuguese': 'Rankings globais em breve!',
  },
  'breakWord': {
    'English': 'BREAK', 'French': 'CASSER', 'Spanish': 'ROMPER',
    'Dutch': 'BREKEN', 'German': 'ZERSCHLAGEN', 'Turkish': 'KIR',
    'Swedish': 'KROSSA', 'Italian': 'ROMPI', 'Japanese': '割る',
    'Korean': '깨기', 'Russian': 'РАЗБИТЬ', 'Portuguese': 'QUEBRAR',
  },
  'bankWord': {
    'English': 'BANK', 'French': 'TIRELIRE', 'Spanish': 'HUCHA',
    'Dutch': 'SPAARPOT', 'German': 'SPARSCHWEIN', 'Turkish': 'KUMBARA',
    'Swedish': 'BANK', 'Italian': 'BANCA', 'Japanese': 'バンク',
    'Korean': '뱅크', 'Russian': 'БАНК', 'Portuguese': 'BANCO',
  },
  'beatLevels': {
    'English': 'Beat Levels!', 'French': 'Termine des niveaux !',
    'Spanish': '¡Supera niveles!', 'Dutch': 'Versla levels!',
    'German': 'Schaffe Level!', 'Turkish': 'Seviyeleri geç!',
    'Swedish': 'Klara nivåer!', 'Italian': 'Supera i livelli!',
    'Japanese': 'レベルをクリア！', 'Korean': '레벨을 클리어!',
    'Russian': 'Проходи уровни!', 'Portuguese': 'Vença níveis!',
  },
  'fillPiggy': {
    'English': 'Fill Piggy!', 'French': 'Remplis la tirelire !',
    'Spanish': '¡Llena la hucha!', 'Dutch': 'Vul de spaarpot!',
    'German': 'Füll das Sparschwein!', 'Turkish': 'Kumbarayı doldur!',
    'Swedish': 'Fyll spargrisen!', 'Italian': 'Riempi il salvadanaio!',
    'Japanese': '貯金箱を満タンに！', 'Korean': '저금통을 채워요!',
    'Russian': 'Наполни копилку!', 'Portuguese': 'Encha o cofrinho!',
  },
  'unlockRewards': {
    'English': 'Unlock Rewards!', 'French': 'Débloque des récompenses !',
    'Spanish': '¡Desbloquea premios!', 'Dutch': 'Ontgrendel beloningen!',
    'German': 'Belohnungen freischalten!', 'Turkish': 'Ödülleri aç!',
    'Swedish': 'Lås upp belöningar!', 'Italian': 'Sblocca premi!',
    'Japanese': '報酬をアンロック！', 'Korean': '보상을 잠금 해제!',
    'Russian': 'Открой награды!', 'Portuguese': 'Desbloqueie prêmios!',
  },
  'breakPiggyToCollect': {
    'English': 'Break Piggy to collect coins!',
    'French': 'Casse la tirelire pour récupérer les pièces !',
    'Spanish': '¡Rompe la hucha para conseguir monedas!',
    'Dutch': 'Breek de spaarpot om munten te innen!',
    'German': 'Sparschwein zerschlagen für Münzen!',
    'Turkish': 'Altınları almak için kumbarayı kır!',
    'Swedish': 'Krossa spargrisen för att samla mynt!',
    'Italian': 'Rompi il salvadanaio per le monete!',
    'Japanese': '貯金箱を割ってコインを集めよう！',
    'Korean': '저금통을 깨서 코인을 모으세요!',
    'Russian': 'Разбей копилку, чтобы собрать монеты!',
    'Portuguese': 'Quebre o cofrinho para pegar moedas!',
  },
  'tapToContinue': {
    'English': 'Tap to Continue', 'French': 'Touche pour continuer',
    'Spanish': 'Toca para continuar', 'Dutch': 'Tik om door te gaan',
    'German': 'Zum Fortfahren tippen', 'Turkish': 'Devam için dokun',
    'Swedish': 'Tryck för att fortsätta', 'Italian': 'Tocca per continuare',
    'Japanese': 'タップして続ける', 'Korean': '탭하여 계속',
    'Russian': 'Нажмите, чтобы продолжить', 'Portuguese': 'Toque para continuar',
  },
  'freeGift': {
    'English': 'FREE GIFT!', 'French': 'CADEAU GRATUIT !',
    'Spanish': '¡REGALO GRATIS!', 'Dutch': 'GRATIS CADEAU!',
    'German': 'GRATIS GESCHENK!', 'Turkish': 'BEDAVA HEDİYE!',
    'Swedish': 'GRATIS GÅVA!', 'Italian': 'REGALO GRATIS!',
    'Japanese': '無料ギフト！', 'Korean': '무료 선물!',
    'Russian': 'ПОДАРОК!', 'Portuguese': 'PRESENTE GRÁTIS!',
  },
  'dailyReward': {
    'English': 'Daily Reward', 'French': 'Récompense du jour',
    'Spanish': 'Recompensa diaria', 'Dutch': 'Dagelijkse beloning',
    'German': 'Tägliche Belohnung', 'Turkish': 'Günlük Ödül',
    'Swedish': 'Daglig belöning', 'Italian': 'Premio giornaliero',
    'Japanese': 'デイリー報酬', 'Korean': '일일 보상',
    'Russian': 'Ежедневная награда', 'Portuguese': 'Recompensa diária',
  },
  'week': {
    'English': 'Week', 'French': 'Semaine', 'Spanish': 'Semana',
    'Dutch': 'Week', 'German': 'Woche', 'Turkish': 'Hafta',
    'Swedish': 'Vecka', 'Italian': 'Settimana', 'Japanese': '週',
    'Korean': '주차', 'Russian': 'Неделя', 'Portuguese': 'Semana',
  },
  'day': {
    'English': 'Day', 'French': 'Jour', 'Spanish': 'Día',
    'Dutch': 'Dag', 'German': 'Tag', 'Turkish': 'Gün',
    'Swedish': 'Dag', 'Italian': 'Giorno', 'Japanese': '日目',
    'Korean': '일차', 'Russian': 'День', 'Portuguese': 'Dia',
  },
  'collect': {
    'English': 'Collect', 'French': 'Récupérer', 'Spanish': 'Recoger',
    'Dutch': 'Ophalen', 'German': 'Einsammeln', 'Turkish': 'Topla',
    'Swedish': 'Samla', 'Italian': 'Raccogli', 'Japanese': '受け取る',
    'Korean': '받기', 'Russian': 'Забрать', 'Portuguese': 'Coletar',
  },
  'continueWord': {
    'English': 'Continue', 'French': 'Continuer', 'Spanish': 'Continuar',
    'Dutch': 'Doorgaan', 'German': 'Weiter', 'Turkish': 'Devam',
    'Swedish': 'Fortsätt', 'Italian': 'Continua', 'Japanese': '続ける',
    'Korean': '계속', 'Russian': 'Продолжить', 'Portuguese': 'Continuar',
  },
  'claimed': {
    'English': 'Claimed', 'French': 'Récupéré', 'Spanish': 'Reclamado',
    'Dutch': 'Opgehaald', 'German': 'Abgeholt', 'Turkish': 'Alındı',
    'Swedish': 'Hämtad', 'Italian': 'Riscattato', 'Japanese': '受取済',
    'Korean': '받음', 'Russian': 'Получено', 'Portuguese': 'Resgatado',
  },
  'dayTapCollect': {
    'English': 'Day {n} — tap Collect!',
    'French': 'Jour {n} — touche Récupérer !',
    'Spanish': 'Día {n} — ¡toca Recoger!',
    'Dutch': 'Dag {n} — tik op Ophalen!',
    'German': 'Tag {n} — tippe auf Einsammeln!',
    'Turkish': '{n}. gün — Topla’ya dokun!',
    'Swedish': 'Dag {n} — tryck Samla!',
    'Italian': 'Giorno {n} — tocca Raccogli!',
    'Japanese': '{n}日目 — 受け取ってね！',
    'Korean': '{n}일차 — 받기를 누르세요!',
    'Russian': 'День {n} — нажми Забрать!',
    'Portuguese': 'Dia {n} — toque em Coletar!',
  },
  'comeBackForDay': {
    'English': 'Come back tomorrow for Day {n}',
    'French': 'Reviens demain pour le jour {n}',
    'Spanish': 'Vuelve mañana para el día {n}',
    'Dutch': 'Kom morgen terug voor dag {n}',
    'German': 'Komm morgen wieder für Tag {n}',
    'Turkish': '{n}. gün için yarın geri gel',
    'Swedish': 'Kom tillbaka imorgon för dag {n}',
    'Italian': 'Torna domani per il giorno {n}',
    'Japanese': '明日また来て{n}日目を受け取ろう',
    'Korean': '내일 다시 와서 {n}일차를 받으세요',
    'Russian': 'Возвращайся завтра за днём {n}',
    'Portuguese': 'Volte amanhã para o dia {n}',
  },
  'getBooster': {
    'English': 'GET BOOSTER', 'French': 'OBTENIR BONUS',
    'Spanish': 'OBTENER BONUS', 'Dutch': 'BOOSTER HALEN',
    'German': 'BOOSTER HOLEN', 'Turkish': 'BOOSTER AL',
    'Swedish': 'HÄMTA BOOSTER', 'Italian': 'OTTIENI BONUS',
    'Japanese': 'ブースター入手', 'Korean': '부스터 받기',
    'Russian': 'ВЗЯТЬ БУСТЕР', 'Portuguese': 'OBTER BOOSTER',
  },
  'getABooster': {
    'English': 'Get a {x} Booster!', 'French': 'Obtiens un bonus {x} !',
    'Spanish': '¡Consigue un bonus de {x}!', 'Dutch': 'Haal een {x}-booster!',
    'German': 'Hol dir einen {x}-Booster!', 'Turkish': '{x} booster’ı al!',
    'Swedish': 'Skaffa en {x}-booster!', 'Italian': 'Ottieni un bonus {x}!',
    'Japanese': '{x}ブースターを入手！', 'Korean': '{x} 부스터를 받으세요!',
    'Russian': 'Получи бустер {x}!', 'Portuguese': 'Ganhe um booster de {x}!',
  },
  'boosterAdded': {
    'English': 'Nice! +1 {x} added.', 'French': 'Super ! +1 {x} ajouté.',
    'Spanish': '¡Genial! +1 {x} añadido.', 'Dutch': 'Mooi! +1 {x} toegevoegd.',
    'German': 'Super! +1 {x} hinzugefügt.', 'Turkish': 'Harika! +1 {x} eklendi.',
    'Swedish': 'Najs! +1 {x} tillagd.', 'Italian': 'Bene! +1 {x} aggiunto.',
    'Japanese': 'いいね！{x}を1つ追加。', 'Korean': '좋아요! {x} +1 추가됨.',
    'Russian': 'Отлично! +1 {x} добавлен.', 'Portuguese': 'Ótimo! +1 {x} adicionado.',
  },
  'needCoinsBundle': {
    'English': 'Need {n} coins for this bundle.',
    'French': 'Il faut {n} pièces pour ce pack.',
    'Spanish': 'Necesitas {n} monedas para este paquete.',
    'Dutch': '{n} munten nodig voor dit pakket.',
    'German': '{n} Münzen für dieses Paket nötig.',
    'Turkish': 'Bu paket için {n} altın gerekli.',
    'Swedish': 'Behöver {n} mynt för detta paket.',
    'Italian': 'Servono {n} monete per questo pacchetto.',
    'Japanese': 'このパックには{n}コイン必要です。',
    'Korean': '이 묶음에는 {n} 코인이 필요합니다.',
    'Russian': 'Нужно {n} монет для этого набора.',
    'Portuguese': 'Precisa de {n} moedas para este pacote.',
  },
  'purchaseComplete': {
    'English': 'PURCHASE COMPLETE!', 'French': 'ACHAT TERMINÉ !',
    'Spanish': '¡COMPRA COMPLETADA!', 'Dutch': 'AANKOOP VOLTOOID!',
    'German': 'KAUF ABGESCHLOSSEN!', 'Turkish': 'SATIN ALMA TAMAM!',
    'Swedish': 'KÖP KLART!', 'Italian': 'ACQUISTO COMPLETATO!',
    'Japanese': '購入完了！', 'Korean': '구매 완료!',
    'Russian': 'ПОКУПКА ЗАВЕРШЕНА!', 'Portuguese': 'COMPRA CONCLUÍDA!',
  },
  'adsRemovedThanks': {
    'English': 'Ads removed — enjoy the quiet. Thank you!',
    'French': 'Pubs supprimées — profite du calme. Merci !',
    'Spanish': 'Anuncios eliminados — disfruta la calma. ¡Gracias!',
    'Dutch': 'Advertenties weg — geniet van de rust. Bedankt!',
    'German': 'Werbung entfernt — genieße die Ruhe. Danke!',
    'Turkish': 'Reklamlar kalktı — sessizliğin tadını çıkar. Teşekkürler!',
    'Swedish': 'Annonser borta — njut av lugnet. Tack!',
    'Italian': 'Pubblicità rimossa — goditi la quiete. Grazie!',
    'Japanese': '広告を削除しました。お楽しみください。ありがとう！',
    'Korean': '광고가 제거됐어요 — 조용함을 즐기세요. 감사합니다!',
    'Russian': 'Реклама убрана — наслаждайтесь тишиной. Спасибо!',
    'Portuguese': 'Anúncios removidos — aproveite o silêncio. Obrigado!',
  },
  'purchaseFailedTitle': {
    'English': 'PURCHASE FAILED!', 'French': 'ÉCHEC DE L’ACHAT !',
    'Spanish': '¡COMPRA FALLIDA!', 'Dutch': 'AANKOOP MISLUKT!',
    'German': 'KAUF FEHLGESCHLAGEN!', 'Turkish': 'SATIN ALMA BAŞARISIZ!',
    'Swedish': 'KÖPET MISSLYCKADES!', 'Italian': 'ACQUISTO FALLITO!',
    'Japanese': '購入に失敗！', 'Korean': '구매 실패!',
    'Russian': 'ПОКУПКА НЕ УДАЛАСЬ!', 'Portuguese': 'COMPRA FALHOU!',
  },
  'somethingWrong': {
    'English': 'Oops! Something went wrong.\nPlease try again later.',
    'French': 'Oups ! Une erreur est survenue.\nRéessaie plus tard.',
    'Spanish': '¡Vaya! Algo salió mal.\nInténtalo más tarde.',
    'Dutch': 'Oeps! Er ging iets mis.\nProbeer het later opnieuw.',
    'German': 'Ups! Etwas ist schiefgelaufen.\nBitte später erneut versuchen.',
    'Turkish': 'Hata! Bir şeyler ters gitti.\nLütfen sonra tekrar dene.',
    'Swedish': 'Hoppsan! Något gick fel.\nFörsök igen senare.',
    'Italian': 'Ops! Qualcosa è andato storto.\nRiprova più tardi.',
    'Japanese': 'エラーが発生しました。\n後でもう一度お試しください。',
    'Korean': '문제가 발생했어요.\n나중에 다시 시도해 주세요.',
    'Russian': 'Упс! Что-то пошло не так.\nПопробуйте позже.',
    'Portuguese': 'Ops! Algo deu errado.\nTente novamente mais tarde.',
  },
  'okay': {
    'English': 'OKAY', 'French': 'OK', 'Spanish': 'VALE',
    'Dutch': 'OKÉ', 'German': 'OKAY', 'Turkish': 'TAMAM',
    'Swedish': 'OKEJ', 'Italian': 'OK', 'Japanese': 'OK',
    'Korean': '확인', 'Russian': 'ОК', 'Portuguese': 'OK',
  },
  'username': {
    'English': 'Username', 'French': 'Nom d’utilisateur',
    'Spanish': 'Nombre de usuario', 'Dutch': 'Gebruikersnaam',
    'German': 'Benutzername', 'Turkish': 'Kullanıcı Adı',
    'Swedish': 'Användarnamn', 'Italian': 'Nome utente',
    'Japanese': 'ユーザー名', 'Korean': '사용자 이름',
    'Russian': 'Имя пользователя', 'Portuguese': 'Nome de usuário',
  },
  'yourName': {
    'English': 'Your name', 'French': 'Ton nom', 'Spanish': 'Tu nombre',
    'Dutch': 'Je naam', 'German': 'Dein Name', 'Turkish': 'Adın',
    'Swedish': 'Ditt namn', 'Italian': 'Il tuo nome', 'Japanese': 'あなたの名前',
    'Korean': '이름', 'Russian': 'Твоё имя', 'Portuguese': 'Seu nome',
  },
  'createUsername': {
    'English': 'Create your user name',
    'French': 'Crée ton nom d’utilisateur',
    'Spanish': 'Crea tu nombre de usuario',
    'Dutch': 'Maak je gebruikersnaam',
    'German': 'Erstelle deinen Benutzernamen',
    'Turkish': 'Kullanıcı adını oluştur',
    'Swedish': 'Skapa ditt användarnamn',
    'Italian': 'Crea il tuo nome utente',
    'Japanese': 'ユーザー名を作成',
    'Korean': '사용자 이름을 만드세요',
    'Russian': 'Создай имя пользователя',
    'Portuguese': 'Crie seu nome de usuário',
  },
  'profile': {
    'English': 'Profile', 'French': 'Profil', 'Spanish': 'Perfil',
    'Dutch': 'Profiel', 'German': 'Profil', 'Turkish': 'Profil',
    'Swedish': 'Profil', 'Italian': 'Profilo', 'Japanese': 'プロフィール',
    'Korean': '프로필', 'Russian': 'Профиль', 'Portuguese': 'Perfil',
  },
  'unlockFrameLater': {
    'English': 'Unlock this frame later!',
    'French': 'Débloque ce cadre plus tard !',
    'Spanish': '¡Desbloquea este marco más tarde!',
    'Dutch': 'Ontgrendel dit kader later!',
    'German': 'Schalte diesen Rahmen später frei!',
    'Turkish': 'Bu çerçeveyi sonra aç!',
    'Swedish': 'Lås upp den här ramen senare!',
    'Italian': 'Sblocca questa cornice più tardi!',
    'Japanese': 'このフレームは後でアンロック！',
    'Korean': '이 프레임은 나중에 잠금 해제!',
    'Russian': 'Открой эту рамку позже!',
    'Portuguese': 'Desbloqueie esta moldura depois!',
  },
  'comingSoon': {
    'English': 'COMING SOON!', 'French': 'BIENTÔT !', 'Spanish': '¡PRÓXIMAMENTE!',
    'Dutch': 'BINNENKORT!', 'German': 'BALD VERFÜGBAR!', 'Turkish': 'YAKINDA!',
    'Swedish': 'KOMMER SNART!', 'Italian': 'IN ARRIVO!', 'Japanese': '近日公開！',
    'Korean': '출시 예정!', 'Russian': 'СКОРО!', 'Portuguese': 'EM BREVE!',
  },
  'avatar': {
    'English': 'AVATAR', 'French': 'AVATAR', 'Spanish': 'AVATAR',
    'Dutch': 'AVATAR', 'German': 'AVATAR', 'Turkish': 'AVATAR',
    'Swedish': 'AVATAR', 'Italian': 'AVATAR', 'Japanese': 'アバター',
    'Korean': '아바타', 'Russian': 'АВАТАР', 'Portuguese': 'AVATAR',
  },
  'frame': {
    'English': 'FRAME', 'French': 'CADRE', 'Spanish': 'MARCO',
    'Dutch': 'KADER', 'German': 'RAHMEN', 'Turkish': 'ÇERÇEVE',
    'Swedish': 'RAM', 'Italian': 'CORNICE', 'Japanese': 'フレーム',
    'Korean': '프레임', 'Russian': 'РАМКА', 'Portuguese': 'MOLDURA',
  },
  'badge': {
    'English': 'BADGE', 'French': 'BADGE', 'Spanish': 'INSIGNIA',
    'Dutch': 'BADGE', 'German': 'ABZEICHEN', 'Turkish': 'ROZET',
    'Swedish': 'MÄRKE', 'Italian': 'DISTINTIVO', 'Japanese': 'バッジ',
    'Korean': '배지', 'Russian': 'ЗНАЧОК', 'Portuguese': 'EMBLEMA',
  },
  'processing': {
    'English': 'PROCESSING', 'French': 'TRAITEMENT', 'Spanish': 'PROCESANDO',
    'Dutch': 'VERWERKEN', 'German': 'VERARBEITUNG', 'Turkish': 'İŞLENİYOR',
    'Swedish': 'BEARBETAR', 'Italian': 'ELABORAZIONE', 'Japanese': '処理中',
    'Korean': '처리 중', 'Russian': 'ОБРАБОТКА', 'Portuguese': 'PROCESSANDO',
  },
  'tutorialTap': {
    'English': 'Tap the glowing arrow to slide it off!',
    'French': 'Touche la flèche lumineuse pour la faire glisser !',
    'Spanish': '¡Toca la flecha brillante para deslizarla!',
    'Dutch': 'Tik op de oplichtende pijl om hem weg te schuiven!',
    'German': 'Tippe auf den leuchtenden Pfeil, um ihn wegzuschieben!',
    'Turkish': 'Parlayan oku kaydırmak için dokun!',
    'Swedish': 'Tryck på den lysande pilen för att skjuta bort den!',
    'Italian': 'Tocca la freccia luminosa per farla scorrere via!',
    'Japanese': '光る矢印をタップして外そう！',
    'Korean': '빛나는 화살표를 탭해서 밀어내세요!',
    'Russian': 'Нажми на светящуюся стрелку, чтобы убрать её!',
    'Portuguese': 'Toque na seta brilhante para deslizá-la!',
  },
  'newPower': {
    'English': 'NEW POWER', 'French': 'NOUVEAU POUVOIR',
    'Spanish': 'NUEVO PODER', 'Dutch': 'NIEUWE KRACHT',
    'German': 'NEUE KRAFT', 'Turkish': 'YENİ GÜÇ',
    'Swedish': 'NY KRAFT', 'Italian': 'NUOVO POTERE',
    'Japanese': '新パワー', 'Korean': '새 파워',
    'Russian': 'НОВАЯ СИЛА', 'Portuguese': 'NOVO PODER',
  },
  'gotIt': {
    'English': 'Got it!', 'French': 'Compris !', 'Spanish': '¡Entendido!',
    'Dutch': 'Begrepen!', 'German': 'Verstanden!', 'Turkish': 'Anladım!',
    'Swedish': 'Förstått!', 'Italian': 'Capito!', 'Japanese': 'わかった！',
    'Korean': '알겠어요!', 'Russian': 'Понятно!', 'Portuguese': 'Entendi!',
  },
  'pHint': {
    'English': 'Hint', 'French': 'Indice', 'Spanish': 'Pista',
    'Dutch': 'Hint', 'German': 'Tipp', 'Turkish': 'İpucu',
    'Swedish': 'Ledtråd', 'Italian': 'Indizio', 'Japanese': 'ヒント',
    'Korean': '힌트', 'Russian': 'Подсказка', 'Portuguese': 'Dica',
  },
  'pEraser': {
    'English': 'Eraser', 'French': 'Gomme', 'Spanish': 'Borrador',
    'Dutch': 'Gum', 'German': 'Radierer', 'Turkish': 'Silgi',
    'Swedish': 'Suddgummi', 'Italian': 'Gomma', 'Japanese': '消しゴム',
    'Korean': '지우개', 'Russian': 'Ластик', 'Portuguese': 'Borracha',
  },
  'pMagic': {
    'English': 'Magic', 'French': 'Magie', 'Spanish': 'Magia',
    'Dutch': 'Magie', 'German': 'Magie', 'Turkish': 'Sihir',
    'Swedish': 'Magi', 'Italian': 'Magia', 'Japanese': 'マジック',
    'Korean': '매직', 'Russian': 'Магия', 'Portuguese': 'Magia',
  },
  'pUndo': {
    'English': 'Undo', 'French': 'Annuler', 'Spanish': 'Deshacer',
    'Dutch': 'Ongedaan', 'German': 'Rückgängig', 'Turkish': 'Geri Al',
    'Swedish': 'Ångra', 'Italian': 'Annulla', 'Japanese': '元に戻す',
    'Korean': '되돌리기', 'Russian': 'Отмена', 'Portuguese': 'Desfazer',
  },
  'powerDescHint': {
    'English': 'Reveals an arrow you can move right now.',
    'French': 'Révèle une flèche que tu peux déplacer maintenant.',
    'Spanish': 'Muestra una flecha que puedes mover ahora.',
    'Dutch': 'Toont een pijl die je nu kunt verplaatsen.',
    'German': 'Zeigt einen Pfeil, den du sofort bewegen kannst.',
    'Turkish': 'Hemen oynatabileceğin bir oku gösterir.',
    'Swedish': 'Visar en pil du kan flytta just nu.',
    'Italian': 'Rivela una freccia che puoi muovere subito.',
    'Japanese': '今動かせる矢印を教えます。',
    'Korean': '지금 옮길 수 있는 화살표를 알려줘요.',
    'Russian': 'Показывает стрелку, которую можно сдвинуть сейчас.',
    'Portuguese': 'Revela uma seta que você pode mover agora.',
  },
  'powerDescUndo': {
    'English': 'Took a wrong turn? Take back your last move.',
    'French': 'Mauvais choix ? Annule ton dernier coup.',
    'Spanish': '¿Te equivocaste? Deshaz tu último movimiento.',
    'Dutch': 'Verkeerde zet? Maak je laatste zet ongedaan.',
    'German': 'Falsch gezogen? Mach deinen letzten Zug rückgängig.',
    'Turkish': 'Yanlış mı yaptın? Son hamleni geri al.',
    'Swedish': 'Fel drag? Ångra ditt senaste drag.',
    'Italian': 'Mossa sbagliata? Annulla l’ultima mossa.',
    'Japanese': '間違えた？直前の手を取り消します。',
    'Korean': '실수했나요? 마지막 수를 되돌리세요.',
    'Russian': 'Ошибся? Отмени последний ход.',
    'Portuguese': 'Errou? Desfaça sua última jogada.',
  },
  'powerDescEraser': {
    'English': 'Force-remove ANY arrow — even a blocked one.',
    'French': 'Retire N’IMPORTE quelle flèche — même bloquée.',
    'Spanish': 'Elimina CUALQUIER flecha — incluso bloqueada.',
    'Dutch': 'Verwijder ELKE pijl — zelfs een geblokkeerde.',
    'German': 'Entfernt JEDEN Pfeil — auch einen blockierten.',
    'Turkish': 'HERHANGİ bir oku kaldır — engelliyse bile.',
    'Swedish': 'Ta bort VILKEN pil som helst — även blockerad.',
    'Italian': 'Rimuove QUALSIASI freccia — anche bloccata.',
    'Japanese': 'どんな矢印も強制的に消します（詰まっていても）。',
    'Korean': '어떤 화살표든 강제로 제거해요 — 막힌 것도.',
    'Russian': 'Удаляет ЛЮБУЮ стрелку — даже заблокированную.',
    'Portuguese': 'Remove QUALQUER seta — até uma bloqueada.',
  },
  'powerDescMagic': {
    'English': 'Instantly slides a movable arrow off the board.',
    'French': 'Fait glisser instantanément une flèche hors du plateau.',
    'Spanish': 'Desliza al instante una flecha fuera del tablero.',
    'Dutch': 'Schuift direct een beweegbare pijl van het bord.',
    'German': 'Schiebt sofort einen Pfeil vom Brett.',
    'Turkish': 'Hareketli bir oku anında tahtadan kaydırır.',
    'Swedish': 'Skjuter direkt bort en flyttbar pil från brädet.',
    'Italian': 'Fa scorrere subito una freccia fuori dal tabellone.',
    'Japanese': '動かせる矢印を即座に盤外へ滑らせます。',
    'Korean': '움직일 수 있는 화살표를 즉시 보드 밖으로 밀어내요.',
    'Russian': 'Мгновенно сдвигает подвижную стрелку с поля.',
    'Portuguese': 'Desliza na hora uma seta para fora do tabuleiro.',
  },
};
