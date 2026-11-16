import Foundation

/// Every piece of text in the app, in Portuguese (PT-PT) and English.
///
/// The language is a choice the player makes inside the game, not something
/// inherited from the system locale, so the strings live here instead of in
/// `Localizable.strings`. Split into small tables to keep type-checking quick.
enum Strings {

    typealias Pair = (pt: String, en: String)

    static let all: [String: Pair] = {
        var table: [String: Pair] = [:]
        for group in [common, menu, hud, missions, settings, gameOver, highScores, howTo, about, a11y,
                      academy, drills] {
            table.merge(group) { _, new in new }
        }
        return table
    }()

    static let common: [String: Pair] = [
        "common.cancel": ("Cancelar", "Cancel"),
        "common.close": ("Fechar", "Close"),
    ]

    static let menu: [String: Pair] = [
        "menu.tagline": ("Mesa de arcade em néon", "A neon arcade table"),
        "menu.play": ("Jogar", "Play"),
        "menu.highScores": ("Recordes", "High Scores"),
        "menu.howToPlay": ("Como jogar", "How to Play"),
        "menu.settings": ("Definições", "Settings"),
        "menu.about": ("Sobre", "About"),
        "menu.academy": ("Academia de Flippers", "Flipper Academy"),
        "menu.academySubtitle": ("Aprende as técnicas dos jogadores a sério",
                                 "Learn the skills real players use"),
    ]

    static let hud: [String: Pair] = [
        "hud.ball": ("Bola", "Ball"),
        "hud.best": ("Melhor", "Best"),
        "hud.launch": ("Arrasta para baixo e larga para lançar",
                       "Drag down and release to launch"),
        "hud.launchKeyboard": ("Mantém o espaço e larga para lançar",
                               "Hold space and release to launch"),
        "hud.tilt": ("TILT", "TILT"),
        "hud.tiltWarning": ("CUIDADO", "CAREFUL"),
        "hud.multiball": ("MULTIBOLA", "MULTIBALL"),
        "hud.jackpot": ("JACKPOT", "JACKPOT"),
        "hud.superJackpot": ("SUPER JACKPOT", "SUPER JACKPOT"),
        "hud.ballSaved": ("BOLA SALVA", "BALL SAVED"),
        "hud.extraBall": ("BOLA EXTRA", "EXTRA BALL"),
        "hud.bonus": ("BÓNUS", "BONUS"),
        "hud.lastBall": ("ÚLTIMA BOLA", "LAST BALL"),
        "hud.missionComplete": ("MISSÃO COMPLETA", "MISSION COMPLETE"),
        "hud.missionFailed": ("MISSÃO FALHADA", "MISSION FAILED"),
        "hud.wizard": ("MODO FINAL", "WIZARD MODE"),
        "hud.skillShot": ("SKILL SHOT", "SKILL SHOT"),
        "hud.skillShotHint": ("Skill shot: acerta na pista a piscar",
                              "Skill shot: hit the flashing lane"),
        "hud.shootAgain": ("LANÇA OUTRA VEZ", "SHOOT AGAIN"),
        "hud.jackpotIsLit": ("JACKPOT ACESO", "JACKPOT IS LIT"),
        "hud.bonusTargets": ("Alvos", "Targets"),
        "hud.bonusLoops": ("Voltas", "Loops"),
        "hud.bonusMultiplier": ("Multiplicador", "Multiplier"),
        "hud.bonusTotal": ("Bónus total", "Total bonus"),
    ]

    static let missions: [String: Pair] = [
        "mission.warmUp.name": ("Aquecimento", "Warm-Up"),
        "mission.warmUp.goal": ("5 bumpers em 20 segundos", "5 pop bumpers in 20 seconds"),
        "mission.rampRush.name": ("Corrida de Rampas", "Ramp Rush"),
        "mission.rampRush.goal": ("4 rampas em 30 segundos", "4 ramps in 30 seconds"),
        "mission.targetFrenzy.name": ("Frenesim de Alvos", "Target Frenzy"),
        "mission.targetFrenzy.goal": ("Derruba 5 alvos sem perder a bola",
                                      "Drop 5 targets without draining"),
        "mission.orbitLoop.name": ("Volta Completa", "Orbit Loop"),
        "mission.orbitLoop.goal": ("3 orbits em 25 segundos", "3 orbits in 25 seconds"),
        "mission.lock3.name": ("Prender 3", "Lock 3"),
        "mission.lock3.goal": ("Acerta 3 vezes nos saucers", "Shoot the saucers 3 times"),
        "mission.jackpotHunt.name": ("Caça ao Jackpot", "Jackpot Hunt"),
        "mission.jackpotHunt.goal": ("3 jackpots nos alvos acesos", "3 jackpots on the lit targets"),
        "mission.finalShot.name": ("Tiro Final", "Final Shot"),
        "mission.finalShot.goal": ("12 tiros em 60 segundos", "12 shots in 60 seconds"),
    ]

    static let settings: [String: Pair] = [
        "settings.title": ("Definições", "Settings"),
        "settings.language": ("Idioma", "Language"),
        "settings.appearance": ("Aspeto", "Appearance"),
        "settings.theme.system": ("Sistema", "System"),
        "settings.theme.light": ("Claro", "Light"),
        "settings.theme.dark": ("Escuro", "Dark"),
        "settings.audio": ("Áudio", "Audio"),
        "settings.sound": ("Efeitos sonoros", "Sound effects"),
        "settings.music": ("Música", "Music"),
        "settings.haptics": ("Vibração", "Haptics"),
        "settings.controls": ("Controlos", "Controls"),
        "settings.autoPlunge": ("Lançamento automático", "Auto-plunge"),
        "settings.autoPlunge.hint": ("A bola parte sozinha", "The ball launches on its own"),
        "settings.game": ("Jogo", "Game"),
        "settings.balls": ("Bolas por partida", "Balls per game"),
        "settings.data": ("Dados", "Data"),
        "settings.resetScores": ("Apagar recordes", "Clear high scores"),
        "settings.resetConfirm": ("Apagar todos os recordes e estatísticas?",
                                  "Clear all high scores and stats?"),
    ]

    static let gameOver: [String: Pair] = [
        "gameover.title": ("Fim de jogo", "Game Over"),
        "gameover.score": ("Pontuação final", "Final score"),
        "gameover.best": ("Melhor de sempre", "All-time best"),
        "gameover.missions": ("Missões completas", "Missions completed"),
        "gameover.newHighScore": ("NOVO RECORDE", "NEW HIGH SCORE"),
        "gameover.initials": ("As tuas iniciais", "Your initials"),
        "gameover.save": ("Guardar", "Save"),
        "gameover.playAgain": ("Jogar outra vez", "Play again"),
        "gameover.menu": ("Menu principal", "Main menu"),
        "gameover.share": ("Partilhar", "Share"),
        "gameover.shareText": ("Fiz %@ pontos no iVidiPinball.", "I scored %@ in iVidiPinball."),
        "pause.title": ("Em pausa", "Paused"),
        "pause.resume": ("Retomar", "Resume"),
        "pause.restart": ("Recomeçar", "Restart"),
        "pause.menu": ("Sair para o menu", "Quit to menu"),
    ]

    static let highScores: [String: Pair] = [
        "highscores.title": ("Recordes", "High Scores"),
        "highscores.empty": ("Ainda não há recordes. Joga uma partida.",
                             "No scores yet. Go and play a game."),
        "highscores.stats": ("Estatísticas", "Lifetime stats"),
        "highscores.games": ("Partidas", "Games"),
        "highscores.balls": ("Bolas", "Balls"),
        "highscores.jackpots": ("Jackpots", "Jackpots"),
        "highscores.bestCombo": ("Melhor combo", "Best combo"),
        "highscores.playTime": ("Tempo de jogo", "Time played"),
    ]

    static let howTo: [String: Pair] = [
        "howto.title": ("Como jogar", "How to Play"),
        "howto.basics.title": ("O básico", "The basics"),
        "howto.basics.body": (
            "Tens 3 bolas por partida, ou 5 se mudares nas Definições. Arrasta para baixo e larga para lançar. Mantém a bola viva com os flippers e faz pontos em tudo o que acertares.",
            "You get 3 balls a game, or 5 if you change it in Settings. Drag down and release to launch. Keep the ball alive with the flippers and score off everything you hit."),
        "howto.controls.title": ("Controlos", "Controls"),
        "howto.controls.body": (
            "Toca na metade esquerda ou direita do ecrã para o flipper desse lado. Um deslize horizontal curto abana a mesa. No Mac: setas esquerda e direita para os flippers, espaço para lançar, N e M para abanar.",
            "Tap the left or right half of the screen for that flipper. A short horizontal swipe nudges the table. On the Mac: left and right arrows for the flippers, space to launch, N and M to nudge."),
        "howto.tilt.title": ("Abanar e tilt", "Nudge and tilt"),
        "howto.tilt.body": (
            "Abanar desvia a bola, mas três abanões em dois segundos dão TILT: perdes os flippers e a bola.",
            "Nudging shifts the ball, but three nudges in two seconds cause a TILT: you lose the flippers and the ball."),
        "howto.combos.title": ("Combos e multiplicadores", "Combos and multipliers"),
        "howto.combos.body": (
            "Rampas e orbits seguidas em menos de 4 segundos sobem o combo até 8×. Completar as pistas P-I-N-B sobe o multiplicador de jogador até 5×. Os flippers mudam as luzes das pistas de lugar, para desviares uma letra acesa da pista onde a bola vai cair. No lançamento, uma das pistas pisca: acerta nela com o plunger para ganhar o skill shot.",
            "Back-to-back ramps and orbits within 4 seconds build the combo up to 8×. Completing the P-I-N-B lanes raises the player multiplier up to 5×. The flippers move the lane lights along, so you can steer a lit letter away from the lane the ball is heading for. On the launch one lane flashes: plunge into it for the skill shot."),
        "howto.missions.title": ("Missões", "Missions"),
        "howto.missions.body": (
            "Acerta num saucer para começar uma missão: os dois piscam quando há uma à tua espera. Completa as seis para desbloquear o Tiro Final. A missão Prender 3 lança a multibola, onde tudo vale a dobrar. As luzes no topo da mesa mostram o caminho: a missão em curso pisca, as completas ficam acesas e a estrela pisca quando o Tiro Final está à tua espera. Vence o Tiro Final e as missões recomeçam do princípio.",
            "Shoot a saucer to start a mission: both flash when one is waiting. Complete all six to unlock Final Shot. The Lock 3 mission starts multiball, where everything scores double. The lamps at the top of the table track your way there: the mission in play flashes, finished ones stay lit, and the star flashes when Final Shot is waiting. Beat Final Shot and the missions start over."),
        "howto.save.title": ("Bola salva", "Ball save"),
        "howto.save.body": (
            "Os primeiros 8 segundos de cada bola estão protegidos: a luz SHOOT AGAIN pisca entre os flippers. Se drenares nesse tempo, a bola volta. No fim de cada bola, o visor conta o bónus dos alvos e das voltas, vezes o multiplicador.",
            "The first 8 seconds of every ball are covered: the SHOOT AGAIN light flashes between the flippers. Drain in that window and the ball comes back. At the end of every ball the display counts out the bonus for targets and loops, times your multiplier."),
        "howto.academy.title": ("Academia de Flippers", "Flipper Academy"),
        "howto.academy.body": (
            "No menu, a Academia ensina as técnicas dos jogadores a sério na mesma mesa: cradle, apanhada, passe com toque e tiros apontados. Cada exercício tem 10 tentativas, diz-te porque falhaste, mostra o momento em milissegundos ou o ponto do flipper onde flipaste, e tem câmara lenta para aprenderes o gesto.",
            "From the menu, the Academy teaches the skills real players use, on the same table: cradle, dead-flipper catch, tap pass and aimed shots. Each drill gives you 10 attempts, tells you why you missed, shows your timing in milliseconds or the spot on the flipper you flipped from, and has slow motion for learning the move."),
        "howto.scoring.title": ("Pontuação", "Scoring"),
        "howto.score.bumper": ("Bumper", "Pop bumper"),
        "howto.score.target": ("Alvo fixo", "Standup target"),
        "howto.score.dropTarget": ("Alvo rebatível", "Drop target"),
        "howto.score.ramp": ("Rampa", "Ramp"),
        "howto.score.orbit": ("Orbit", "Orbit"),
        "howto.score.laneSet": ("P-I-N-B completo", "P-I-N-B complete"),
        "howto.score.jackpot": ("Jackpot", "Jackpot"),
        "howto.score.superJackpot": ("Super jackpot", "Super jackpot"),
    ]

    static let about: [String: Pair] = [
        "about.title": ("Sobre", "About"),
        "about.developedBy": ("Developed by David Arsénio Martins",
                              "Developed by David Arsénio Martins"),
        "about.website": ("Site", "Website"),
        "about.github": ("GitHub", "GitHub"),
        "about.version": ("Versão", "Version"),
        "about.privacy": ("Privacidade", "Privacy"),
        "about.credits": ("Feito em Cascais, Portugal.", "Made in Cascais, Portugal."),
    ]

    static let academy: [String: Pair] = [
        "academy.title": ("Academia de Flippers", "Flipper Academy"),
        "academy.intro": (
            "O pinball não é sorte. Os jogadores a sério param a bola, passam-na de um flipper para o outro e escolhem onde acertam. Cada exercício treina uma técnica na mesa verdadeira, com 10 tentativas e o motivo de cada falha.",
            "Pinball is not luck. Real players stop the ball, pass it from one flipper to the other and choose what they hit. Each drill practises one skill on the real table, with 10 attempts and the reason behind every miss."),
        "academy.stars": ("%d de %d estrelas", "%d of %d stars"),
        "academy.best": ("Melhor: %d/10", "Best: %d/10"),
        "academy.notTried": ("Por experimentar", "Not tried yet"),
        "academy.group.control": ("Controlo da bola", "Ball control"),
        "academy.group.aim": ("Pontaria", "Aiming"),
        "academy.back": ("Voltar", "Back"),
        "academy.start": ("Começar", "Start"),
        "academy.what": ("O que é", "What it is"),
        "academy.how": ("Como fazer", "How to do it"),
        "academy.why": ("Para que serve", "Why it matters"),
        "academy.attempt": ("Tentativa %d/%d", "Attempt %d/%d"),
        "academy.successes": ("%d certas", "%d made"),
        "academy.slowMotion": ("Câmara lenta", "Slow motion"),
        "academy.side.left": ("Bola para o flipper esquerdo", "Ball to the left flipper"),
        "academy.side.right": ("Bola para o flipper direito", "Ball to the right flipper"),
        "academy.timing": ("Carregaste %d ms antes de a bola chegar", "You pressed %d ms before the ball landed"),
        "academy.timingLate": ("Carregaste %d ms depois de a bola chegar", "You pressed %d ms after the ball landed"),
        "academy.blade": ("Flipaste com a bola a %d%% do flipper", "You flipped with the ball %d%% along the flipper"),
        "academy.struck": ("Bateu primeiro: %@", "It hit first: %@"),
        "academy.struck.ramp": ("a rampa", "the ramp"),
        "academy.struck.dropTarget": ("os alvos rebatíveis", "the drop targets"),
        "academy.struck.standup": ("um alvo fixo", "a standup"),
        "academy.struck.bumper": ("um bumper", "a pop bumper"),
        "academy.struck.saucer": ("um saucer", "a saucer"),
        "academy.struck.orbit": ("uma orbit", "an orbit"),
        "academy.struck.spinner": ("o spinner", "the spinner"),
        "academy.struck.lane": ("uma pista de cima", "a top lane"),
        "academy.bladeTitle": ("Onde flipaste", "Where you flipped"),
        "academy.bladeBase": ("Base", "Base"),
        "academy.bladeTip": ("Ponta", "Tip"),
        "academy.sweetSpot": ("Os teus acertos costumam ser entre %d%% e %d%%",
                              "Your hits usually come between %d%% and %d%%"),
        "academy.sweetSpotNone": ("Acerta 3 vezes para veres onde fica o teu ponto certo",
                                  "Make 3 hits to see where your sweet spot is"),
        "academy.done": ("Exercício terminado", "Drill complete"),
        "academy.score": ("%d de 10", "%d out of 10"),
        "academy.newBest": ("NOVO MELHOR", "NEW BEST"),
        "academy.again": ("Repetir", "Try again"),
        "academy.toList": ("Academia", "Academy"),
        "academy.next": ("Próximo exercício", "Next drill"),
        "academy.mastery.0": ("Continua a treinar: 5 certas dão a primeira estrela.",
                              "Keep practising: 5 made earns the first star."),
        "academy.mastery.1": ("Bronze. 7 certas dão a prata.", "Bronze. 7 made earns silver."),
        "academy.mastery.2": ("Prata. 9 certas dão o ouro.", "Silver. 9 made earns gold."),
        "academy.mastery.3": ("Ouro. Técnica dominada.", "Gold. Skill mastered."),

        "academy.fb.cradled": ("CRADLE", "CRADLED"),
        "academy.fb.cradled.tip": ("Bola parada e sob controlo. Agora podes escolher o próximo tiro com calma.",
                                   "Ball stopped and under control. Now you can line up the next shot calmly."),
        "academy.fb.caught": ("APANHADA", "CAUGHT"),
        "academy.fb.caught.tip": ("O flipper levantado absorveu a queda e a bola rolou para a base.",
                                  "The raised flipper soaked up the fall and the ball rolled to the base."),
        "academy.fb.passed": ("PASSE", "PASSED"),
        "academy.fb.passed.tip": ("A bola mudou de flipper sem subir a mesa. É assim que se prepara o tiro do outro lado.",
                                  "The ball changed flippers without going up the table. That is how you set up a shot from the other side."),
        "academy.fb.hit": ("ACERTASTE", "HIT"),
        "academy.fb.hit.tip": ("Lembra-te de onde estava a bola no flipper: é esse o ponto para este tiro.",
                               "Remember where the ball was on the flipper: that is the spot for this shot."),
        "academy.fb.noFlip": ("SEM FLIPPER", "NO FLIP"),
        "academy.fb.noFlip.tip": ("Não levantaste o flipper. Mantém-no levantado antes de a bola chegar.",
                                  "You never raised the flipper. Hold it up before the ball gets there."),
        "academy.fb.flippedIntoIt": ("BATESTE NA BOLA", "FLIPPED INTO IT"),
        "academy.fb.flippedIntoIt.tip": ("O flipper ainda estava a subir quando a bola chegou e atirou-a. Levanta-o mais cedo e não largues.",
                                         "The flipper was still rising when the ball arrived and batted it away. Raise it earlier and keep holding."),
        "academy.fb.flippedLate": ("TARDE DEMAIS", "TOO LATE"),
        "academy.fb.flippedLate.tip": ("A bola ficou, mas porque o flipper a apanhou a subir. Numa apanhada a sério, o flipper já está levantado à espera.",
                                       "The ball stayed, but only because the rising flipper scooped it. In a real catch the flipper is already up and waiting."),
        "academy.fb.drained": ("DRENOU", "DRAINED"),
        "academy.fb.drained.tip": ("A bola passou pelos flippers. Mantém o flipper do lado da bola levantado até ela parar.",
                                   "The ball got past the flippers. Keep the flipper on the ball's side up until it stops."),
        "academy.fb.timeout": ("TEMPO", "TIME"),
        "academy.fb.timeout.tip": ("A bola não chegou a ficar parada. Segura o flipper firme até ela assentar na base.",
                                   "The ball never settled. Hold the flipper steady until it rests at the base."),
        "academy.fb.tooHard": ("FORTE DEMAIS", "TOO HARD"),
        "academy.fb.tooHard.tip": ("A bola subiu a mesa. Baixa o flipper, deixa a bola rolar e dá só um toque curto quando ela chegar à ponta.",
                                   "The ball went up the table. Drop the flipper, let the ball roll and give it only a short tap as it reaches the tip."),
        "academy.fb.neverCradled": ("SEM CONTROLO", "NO CONTROL"),
        "academy.fb.neverCradled.tip": ("Primeiro faz cradle: só se passa uma bola que já está parada.",
                                        "Cradle it first: you can only pass a ball that is already stopped."),
        "academy.fb.missed": ("FALHASTE", "MISSED"),
        "academy.fb.missed.tip": ("Muda o momento: flipar mais cedo ou mais tarde muda o ponto do flipper e, com ele, a direção da bola.",
                                  "Change your timing: flipping earlier or later changes the spot on the flipper, and with it the ball's direction."),
    ]

    static let drills: [String: Pair] = [
        "drill.cradle.name": ("Cradle", "Cradle"),
        "drill.cradle.skill": ("Parar a bola no flipper", "Stop the ball on a flipper"),
        "drill.cradle.what": (
            "Prender a bola entre o flipper levantado e a parede, parada. É a primeira coisa que um jogador a sério aprende: uma bola parada não drena.",
            "Trapping the ball, stopped, in the crook of a raised flipper. It is the first thing a real player learns: a stopped ball cannot drain."),
        "drill.cradle.how": (
            "1. A bola desce pela inlane.\n2. Levanta o flipper desse lado antes de ela chegar.\n3. Não largues: a bola rola para a base e para.\n4. Segura 1 segundo com a bola parada.",
            "1. The ball rolls down the inlane.\n2. Raise that side's flipper before it arrives.\n3. Keep holding: the ball rolls to the base and stops.\n4. Hold for 1 second with the ball still."),
        "drill.cradle.why": (
            "Com a bola parada respiras, vês o que está aceso e escolhes o tiro, em vez de bater em tudo o que aparece.",
            "With the ball stopped you get a breath, see what is lit and choose a shot, instead of swatting at whatever comes."),

        "drill.deadCatch.name": ("Apanhada", "Dead-Flipper Catch"),
        "drill.deadCatch.skill": ("Apanhar uma bola que cai", "Catch a falling ball"),
        "drill.deadCatch.what": (
            "A bola cai do meio da mesa para cima de um flipper. Com o flipper já levantado, a queda perde força e a bola acaba parada na base.",
            "The ball drops from the middle of the table on to a flipper. With the flipper already up, the fall loses its energy and the ball ends up resting at the base."),
        "drill.deadCatch.how": (
            "1. Vê de que lado vem a bola.\n2. Levanta esse flipper cedo, antes de a bola lhe tocar.\n3. Não flipes quando a bola bate: isso atira-a.\n4. Segura até a bola parar.",
            "1. Watch which side the ball is coming to.\n2. Raise that flipper early, before the ball touches it.\n3. Do not flip as it lands: that bats it away.\n4. Hold until the ball stops."),
        "drill.deadCatch.why": (
            "A maioria das bolas perdidas são bolas que caem do meio e levam um flipper à toa. Apanhá-las transforma o caos em controlo.",
            "Most lost balls are ones that drop from the middle and get a panicked flip. Catching them turns chaos into control."),

        "drill.tapPass.name": ("Passe com toque", "Tap Pass"),
        "drill.tapPass.skill": ("Passar a bola para o outro flipper", "Move the ball to the other flipper"),
        "drill.tapPass.what": (
            "Levar uma bola parada de um flipper para o outro sem a mandar mesa acima. Muitos tiros só se fazem bem a partir de um dos lados.",
            "Moving a stopped ball from one flipper to the other without sending it up the table. Many shots can only be made well from one side."),
        "drill.tapPass.how": (
            "1. Faz cradle à bola.\n2. Baixa o flipper e deixa-a rolar.\n3. Quando chega à ponta, um toque curtíssimo atira-a para o outro lado.\n4. Levanta o outro flipper e faz cradle lá.",
            "1. Cradle the ball.\n2. Drop the flipper and let it roll.\n3. As it reaches the tip, a very short tap pops it across.\n4. Raise the other flipper and cradle it there."),
        "drill.tapPass.why": (
            "Quem só joga de um lado só tem metade dos tiros. Passar a bola dá-te a mesa inteira.",
            "A player stuck on one side only has half the shots. Passing gives you the whole table."),

        "drill.rampShot.name": ("Tiro à rampa", "Ramp Shot"),
        "drill.rampShot.skill": ("Meter a bola numa rampa", "Put the ball up a ramp"),
        "drill.rampShot.what": (
            "Fazer subir a bola por uma das rampas. A direção da bola depende do ponto do flipper em que ela está quando carregas.",
            "Sending the ball up one of the ramps. Where the ball goes depends on where it is on the flipper when you press."),
        "drill.rampShot.how": (
            "1. Faz cradle.\n2. Baixa o flipper: a bola rola da base para a ponta.\n3. Flipa no ponto certo do percurso.\n4. Vê no fim onde flipaste e acerta o momento.",
            "1. Cradle the ball.\n2. Drop the flipper: the ball rolls from the base to the tip.\n3. Flip at the right point of that roll.\n4. Check where you flipped afterwards and adjust."),
        "drill.rampShot.why": (
            "As rampas valem combos e missões. Acertar de propósito, e não por acaso, é o que separa um jogador de um batedor.",
            "Ramps feed combos and missions. Making them on purpose, not by accident, is what separates a player from a flailer."),

        "drill.standupShot.name": ("Alvos do jackpot", "Jackpot Targets"),
        "drill.standupShot.skill": ("Acertar nos alvos fixos da direita", "Hit the standups on the right"),
        "drill.standupShot.what": (
            "Acertar num dos alvos fixos do lado direito da mesa. Na missão Caça ao Jackpot e na multibola são eles que pagam os jackpots.",
            "Hitting one of the standup targets on the right of the table. In Jackpot Hunt and in multiball they are what pays the jackpots."),
        "drill.standupShot.how": (
            "1. Faz cradle.\n2. Baixa o flipper e deixa a bola rolar.\n3. Tiro estreito: costuma sair com a bola ainda perto da base, por isso deixa-a rolar só um pouco antes de flipares.\n4. Usa o guia do flipper para repetir o ponto que resultou.",
            "1. Cradle the ball.\n2. Drop the flipper and let the ball roll.\n3. A narrow shot: it usually comes with the ball still near the base, so let it roll only a little before you flip.\n4. Use the flipper guide to repeat the spot that worked."),
        "drill.standupShot.why": (
            "Um jackpot aceso só vale se lhe acertares. Treinar este tiro com calma é o que o torna possível no meio da multibola.",
            "A lit jackpot is only worth something if you hit it. Practising this shot calmly is what makes it possible in the middle of multiball."),

        "drill.dropShot.name": ("Alvos rebatíveis", "Drop Targets"),
        "drill.dropShot.skill": ("Acertar num alvo pequeno", "Hit a small target"),
        "drill.dropShot.what": (
            "Derrubar um dos cinco alvos do banco, a partir de um cradle. Conta só se for a primeira coisa em que a bola bate.",
            "Knocking down one of the five targets in the bank from a cradle. It only counts if it is the first thing the ball strikes."),
        "drill.dropShot.how": (
            "1. Faz cradle.\n2. Baixa o flipper: a bola rola da base para a ponta.\n3. Flipa num ponto do percurso e vê o que a bola apanhou primeiro.\n4. Se bateu à esquerda ou à direita do banco, muda o momento, e usa o guia do flipper para repetir o ponto que resultou.",
            "1. Cradle the ball.\n2. Drop the flipper: the ball rolls from the base to the tip.\n3. Flip at a point on that roll and see what the ball struck first.\n4. If it went left or right of the bank, change your timing, and use the flipper guide to repeat the spot that worked."),
        "drill.dropShot.why": (
            "Limpar o banco dá multiplicador e bónus. Saber onde a bola vai bater é o primeiro passo para tiros a sério.",
            "Clearing the bank raises your multiplier and bonus. Knowing where the ball will hit is the first step to real shooting."),
    ]

    static let a11y: [String: Pair] = [
        "a11y.leftFlipper": ("Flipper esquerdo", "Left flipper"),
        "a11y.rightFlipper": ("Flipper direito", "Right flipper"),
        "a11y.plunger": ("Lançador", "Plunger"),
        "a11y.pause": ("Pausar o jogo", "Pause the game"),
        "a11y.scoreValue": ("Pontuação: %@", "Score: %@"),
        "a11y.ballValue": ("Bola %d de %d", "Ball %d of %d"),
        "a11y.languageToggle": ("Mudar idioma", "Switch language"),
        "a11y.openWebsite": ("Abrir ividi.dev", "Open ividi.dev"),
        "a11y.openGitHub": ("Abrir GitHub", "Open GitHub"),
        "a11y.openPrivacy": ("Abrir a política de privacidade", "Open the privacy policy"),
    ]
}
