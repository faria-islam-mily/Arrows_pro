/// Localized Support FAQ entries. Questions and category labels are translated
/// for every supported language so the article list reads natively; the longer
/// answer bodies are shared (English) content.
class FaqEntry {
  const FaqEntry({
    required this.category,
    required this.question,
    required this.answer,
  });
  final String category;
  final String question;
  final String answer;
}

/// The shared answer bodies, in order.
const List<String> _answers = [
  'Your progress saves automatically on this device after every level. '
      'Sign-in based cloud sync is on the way — for now, keep the game '
      'installed to keep your levels, coins and stars.',
  'You earn coins into the Piggy Bank as you clear levels. Once it reaches '
      'the minimum, you can break it to move every saved coin into your '
      'spendable balance at once.',
  'Progress is stored per device right now, so two phones keep separate '
      'progress. Cloud accounts that sync across devices are planned.',
  'Each level can be cleared for up to 3 stars. Stars add to your total, '
      'unlock new worlds, and show off how cleanly you solved a puzzle.',
  'You start with full lives. Failing a level costs one. Lives refill over '
      'time, or you can refill instantly with a free video, coins, or an '
      'infinite-lives bundle.',
  'Remove Ads removes banner and full-screen ads. Optional reward videos '
      '(for free coins or lives) stay, so you can still earn bonuses.',
  'If an ad will not close, wait a few seconds for the close button to '
      'appear, then tap it. If it is still stuck, restart the app — your '
      'progress is safe.',
  'Open Settings and tap Restore Purchase. The store re-delivers anything '
      'you have already bought (like Remove Ads) for free.',
];

// Per-language [category, question] pairs, one list per FAQ (same order as
// _answers). English is the fallback for any missing language.
const List<Map<String, List<String>>> _meta = [
  {
    'English': ['GETTING STARTED', 'How do I save my progress?'],
    'French': ['POUR COMMENCER', 'Comment sauvegarder ma progression ?'],
    'Spanish': ['PRIMEROS PASOS', '¿Cómo guardo mi progreso?'],
    'Dutch': ['AAN DE SLAG', 'Hoe sla ik mijn voortgang op?'],
    'German': ['ERSTE SCHRITTE', 'Wie speichere ich meinen Fortschritt?'],
    'Turkish': ['BAŞLARKEN', 'İlerlememi nasıl kaydederim?'],
    'Swedish': ['KOM IGÅNG', 'Hur sparar jag mina framsteg?'],
    'Italian': ['PER INIZIARE', 'Come salvo i miei progressi?'],
    'Japanese': ['はじめに', '進捗はどう保存されますか？'],
    'Korean': ['시작하기', '진행 상황은 어떻게 저장되나요?'],
    'Russian': ['НАЧАЛО', 'Как сохраняется мой прогресс?'],
    'Portuguese': ['COMEÇANDO', 'Como salvo meu progresso?'],
  },
  {
    'English': ['PIGGY BANK', 'How does the Piggy Bank work?'],
    'French': ['TIRELIRE', 'Comment fonctionne la tirelire ?'],
    'Spanish': ['HUCHA', '¿Cómo funciona la hucha?'],
    'Dutch': ['SPAARPOT', 'Hoe werkt de spaarpot?'],
    'German': ['SPARSCHWEIN', 'Wie funktioniert das Sparschwein?'],
    'Turkish': ['KUMBARA', 'Kumbara nasıl çalışır?'],
    'Swedish': ['SPARGRIS', 'Hur fungerar spargrisen?'],
    'Italian': ['SALVADANAIO', 'Come funziona il salvadanaio?'],
    'Japanese': ['貯金箱', '貯金箱はどう機能しますか？'],
    'Korean': ['저금통', '저금통은 어떻게 작동하나요?'],
    'Russian': ['КОПИЛКА', 'Как работает копилка?'],
    'Portuguese': ['COFRINHO', 'Como funciona o cofrinho?'],
  },
  {
    'English': ['MY ACCOUNT & PROGRESS', 'Can I play on two phones at once?'],
    'French': ['COMPTE & PROGRESSION', 'Puis-je jouer sur deux téléphones ?'],
    'Spanish': ['CUENTA Y PROGRESO', '¿Puedo jugar en dos teléfonos?'],
    'Dutch': ['ACCOUNT & VOORTGANG', 'Kan ik op twee telefoons spelen?'],
    'German': ['KONTO & FORTSCHRITT', 'Kann ich auf zwei Handys spielen?'],
    'Turkish': ['HESAP & İLERLEME', 'İki telefonda oynayabilir miyim?'],
    'Swedish': ['KONTO & FRAMSTEG', 'Kan jag spela på två telefoner?'],
    'Italian': ['ACCOUNT E PROGRESSI', 'Posso giocare su due telefoni?'],
    'Japanese': ['アカウントと進捗', '2台のスマホで遊べますか？'],
    'Korean': ['계정 및 진행', '두 대의 폰에서 할 수 있나요?'],
    'Russian': ['АККАУНТ И ПРОГРЕСС', 'Можно играть на двух телефонах?'],
    'Portuguese': ['CONTA E PROGRESSO', 'Posso jogar em dois telefones?'],
  },
  {
    'English': ['HOW TO PLAY', 'What are stars and why do they matter?'],
    'French': ['COMMENT JOUER', 'À quoi servent les étoiles ?'],
    'Spanish': ['CÓMO JUGAR', '¿Qué son las estrellas y para qué sirven?'],
    'Dutch': ['HOE TE SPELEN', 'Wat zijn sterren en waarom tellen ze?'],
    'German': ['SPIELANLEITUNG', 'Was bringen Sterne?'],
    'Turkish': ['NASIL OYNANIR', 'Yıldızlar nedir ve neden önemli?'],
    'Swedish': ['SÅ SPELAR DU', 'Vad är stjärnor och varför spelar de roll?'],
    'Italian': ['COME GIOCARE', 'Cosa sono le stelle e a cosa servono?'],
    'Japanese': ['遊び方', 'スターとは何で、なぜ重要ですか？'],
    'Korean': ['플레이 방법', '별은 무엇이고 왜 중요한가요?'],
    'Russian': ['КАК ИГРАТЬ', 'Что такое звёзды и зачем они?'],
    'Portuguese': ['COMO JOGAR', 'O que são estrelas e por que importam?'],
  },
  {
    'English': ['HOW TO PLAY', 'How do lives work?'],
    'French': ['COMMENT JOUER', 'Comment fonctionnent les vies ?'],
    'Spanish': ['CÓMO JUGAR', '¿Cómo funcionan las vidas?'],
    'Dutch': ['HOE TE SPELEN', 'Hoe werken levens?'],
    'German': ['SPIELANLEITUNG', 'Wie funktionieren Leben?'],
    'Turkish': ['NASIL OYNANIR', 'Canlar nasıl çalışır?'],
    'Swedish': ['SÅ SPELAR DU', 'Hur fungerar liv?'],
    'Italian': ['COME GIOCARE', 'Come funzionano le vite?'],
    'Japanese': ['遊び方', 'ライフはどう機能しますか？'],
    'Korean': ['플레이 방법', '라이프는 어떻게 작동하나요?'],
    'Russian': ['КАК ИГРАТЬ', 'Как работают жизни?'],
    'Portuguese': ['COMO JOGAR', 'Como funcionam as vidas?'],
  },
  {
    'English': ['REMOVE ADS', 'Does Remove Ads get rid of all ads?'],
    'French': ['SANS PUB', 'Sans Pub supprime-t-il toutes les pubs ?'],
    'Spanish': ['SIN ANUNCIOS', '¿Sin Anuncios elimina todos los anuncios?'],
    'Dutch': ['GEEN ADS', 'Verwijdert Geen Ads alle advertenties?'],
    'German': ['KEINE WERBUNG', 'Entfernt „Keine Werbung“ alle Anzeigen?'],
    'Turkish': ['REKLAMSIZ', 'Reklamsız tüm reklamları kaldırır mı?'],
    'Swedish': ['INGA ANNONSER', 'Tar Inga Annonser bort alla annonser?'],
    'Italian': ['NO PUB', 'No Pub rimuove tutte le pubblicità?'],
    'Japanese': ['広告なし', '「広告なし」は全広告を消しますか？'],
    'Korean': ['광고 제거', '광고 제거는 모든 광고를 없애나요?'],
    'Russian': ['БЕЗ РЕКЛАМЫ', 'Убирает ли «Без рекламы» всю рекламу?'],
    'Portuguese': ['SEM ANÚNCIOS', 'Sem Anúncios remove todos os anúncios?'],
  },
  {
    'English': ['AD ISSUES', 'I cannot close an ad'],
    'French': ['PROBLÈMES DE PUB', 'Je ne peux pas fermer une pub'],
    'Spanish': ['PROBLEMAS DE ANUNCIOS', 'No puedo cerrar un anuncio'],
    'Dutch': ['ADVERTENTIEPROBLEMEN', 'Ik kan een advertentie niet sluiten'],
    'German': ['WERBEPROBLEME', 'Ich kann eine Anzeige nicht schließen'],
    'Turkish': ['REKLAM SORUNLARI', 'Bir reklamı kapatamıyorum'],
    'Swedish': ['ANNONSPROBLEM', 'Jag kan inte stänga en annons'],
    'Italian': ['PROBLEMI PUBBLICITÀ', 'Non riesco a chiudere una pubblicità'],
    'Japanese': ['広告の問題', '広告が閉じられません'],
    'Korean': ['광고 문제', '광고를 닫을 수 없어요'],
    'Russian': ['ПРОБЛЕМЫ С РЕКЛАМОЙ', 'Не могу закрыть рекламу'],
    'Portuguese': ['PROBLEMAS DE ANÚNCIO', 'Não consigo fechar um anúncio'],
  },
  {
    'English': ['PURCHASES', 'How do I restore a purchase?'],
    'French': ['ACHATS', 'Comment restaurer un achat ?'],
    'Spanish': ['COMPRAS', '¿Cómo restauro una compra?'],
    'Dutch': ['AANKOPEN', 'Hoe herstel ik een aankoop?'],
    'German': ['KÄUFE', 'Wie stelle ich einen Kauf wieder her?'],
    'Turkish': ['SATIN ALMALAR', 'Bir satın almayı nasıl geri yüklerim?'],
    'Swedish': ['KÖP', 'Hur återställer jag ett köp?'],
    'Italian': ['ACQUISTI', 'Come ripristino un acquisto?'],
    'Japanese': ['購入', '購入をどう復元しますか？'],
    'Korean': ['구매', '구매를 어떻게 복원하나요?'],
    'Russian': ['ПОКУПКИ', 'Как восстановить покупку?'],
    'Portuguese': ['COMPRAS', 'Como restauro uma compra?'],
  },
];

/// The FAQ list with questions/categories translated for [lang].
List<FaqEntry> localizedFaqs(String lang) {
  return [
    for (var i = 0; i < _answers.length; i++)
      FaqEntry(
        category: (_meta[i][lang] ?? _meta[i]['English']!)[0],
        question: (_meta[i][lang] ?? _meta[i]['English']!)[1],
        answer: _answers[i],
      ),
  ];
}
