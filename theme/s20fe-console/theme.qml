// S20FE Console: tema do Pegasus para o projeto Galaxy S20 FE como console de mesa.
// Faixa de sistemas no topo (Batocera) + fileira de capas e fundo com a tela do jogo (PS5).
// Controles: ←/→ jogo, LB/RB ou ↑/↓ sistema, A joga, X favorito, Y troca de perfil.
// Perfis: a lista e o perfil escolhido ficam no api.memory ("perfis", "perfil"), que o Pegasus
// grava na hora em theme_settings/s20fe-console.json; o serviço scripts/perfis.sh lê esse arquivo e
// troca as pastas de saves dos emuladores. "Onde parei" (sistema/jogo) é guardado por perfil.
import QtQuick 2.12
import QtGraphicalEffects 1.12
import QtMultimedia 5.12

FocusScope {
    id: root
    focus: true

    // ---------- estado ----------
    property int sysIndex: 0          // posição na faixa (índice em "order")
    // Ordem da faixa: consoles em ordem alfabética e os apps Android no fim
    readonly property var order: {
        var consoles = [], apps = []
        for (var i = 0; i < api.collections.count; i++)
            (api.collections.get(i).shortName === "android" ? apps : consoles).push(i)
        return consoles.concat(apps)
    }
    readonly property var collection: order.length > 0 ? api.collections.get(order[sysIndex]) : null
    readonly property var game: collection && gameList.currentIndex >= 0 && collection.games.count > 0
                                ? collection.games.get(gameList.currentIndex) : null
    readonly property real vpx: height / 1080        // escala: tudo é desenhado pensando em 1080p
    function px(v) { return Math.round(v * vpx) }

    // Cores por sistema (Batocera); o resto usa a cor padrão
    readonly property var sysColors: ({
        "ps2": "#1f3fbf", "psx": "#7d7d7d", "psp": "#2b2b2b", "gc": "#5a3fb5", "wii": "#2aa0d8",
        "n64": "#1c8f3a", "snes": "#6a5acd", "nes": "#c62828", "gb": "#8bac0f", "gbc": "#7b1fa2",
        "gba": "#3949ab", "nds": "#455a64", "genesis": "#111111", "megadrive": "#111111",
        "mastersystem": "#b71c1c", "dreamcast": "#ef6c00", "saturn": "#37474f", "arcade": "#e65100",
        "android": "#2e7d32", "switch": "#e60012", "3ds": "#c62828"
    })
    function sysColor(c) { return (c && sysColors[c.shortName]) || "#0a3d91" }

    // ---------- perfis ----------
    readonly property var profileColors: ["#1f6feb", "#d81b60", "#43a047", "#fb8c00"]
    readonly property int maxProfiles: 4
    property var perfis: []
    property string perfil: ""
    property bool pickerOpen: false
    property int pickerIndex: 0
    property bool loadingProfile: false
    function mkey(k) { return perfil + "/" + k }          // memória "onde parei" por perfil
    function profileById(id) {
        for (var i = 0; i < perfis.length; i++) if (perfis[i].id === id) return perfis[i]
        return null
    }
    function loadProfiles() {
        var list = api.memory.has("perfis") ? api.memory.get("perfis") : []
        if (!list || list.length === 0) {
            list = [{ id: "p1", nome: "Principal", cor: profileColors[0] }]
            api.memory.set("perfis", list)
            // memória antiga (antes dos perfis) vira a do perfil Principal
            if (api.memory.has("sysIndex")) api.memory.set("p1/sysIndex", api.memory.get("sysIndex"))
            for (var i = 0; i < api.collections.count; i++) {
                var k = "game_" + api.collections.get(i).shortName
                if (api.memory.has(k)) api.memory.set("p1/" + k, api.memory.get(k))
            }
        }
        perfis = list
        var cur = api.memory.has("perfil") ? api.memory.get("perfil") : "p1"
        perfil = profileById(cur) ? cur : perfis[0].id
    }
    function openPicker() {
        pickerIndex = 0
        for (var i = 0; i < perfis.length; i++) if (perfis[i].id === perfil) pickerIndex = i
        pickerOpen = true
        picker.forceActiveFocus()
    }
    function newProfile() {
        var n = 0
        for (var i = 0; i < perfis.length; i++) n = Math.max(n, parseInt(perfis[i].id.substring(1)))
        var p = { id: "p" + (n + 1), nome: "Jogador " + (perfis.length + 1),
                  cor: profileColors[perfis.length % profileColors.length] }
        var list = perfis.slice(); list.push(p)
        perfis = list
        api.memory.set("perfis", list)
        return p.id
    }
    // escolhe o perfil; se mudou, espera o perfis.sh trocar as pastas de saves antes de liberar
    function chooseProfile(id) {
        var changed = !api.memory.has("perfil") || api.memory.get("perfil") !== id
        perfil = id
        api.memory.set("perfil", id)
        pickerOpen = false
        if (changed) { loadingProfile = true; loadTimer.restart() }
        else afterProfile()
    }
    function afterProfile() {
        loadingProfile = false
        sysIndex = api.memory.has(mkey("sysIndex")) ? Math.min(api.memory.get(mkey("sysIndex")), Math.max(0, order.length - 1)) : 0
        restoreGame()
        gameList.forceActiveFocus()
    }
    Timer { id: loadTimer; interval: 2500; onTriggered: root.afterProfile() }
    function timeAgo(ms) {
        var m = Math.round((Date.now() - ms) / 60000)
        if (m < 1) return "agora"
        if (m < 60) return "há " + m + " min"
        var h = Math.round(m / 60)
        if (h < 48) return "há " + h + " h"
        return "há " + Math.round(h / 24) + " dias"
    }

    // ---------- memória (volta onde parou) ----------
    // Toda abertura do Pegasus começa na escolha de perfil (boot, ligar pelo controle, "Sair" do
    // menu do Pegasus, que o Android reabre por ser a tela inicial). Quando os scripts reabrem o
    // Pegasus por baixo dos panos (controle novo, metadata atualizado), eles gravam "pularPerfil".
    Component.onCompleted: {
        loadProfiles()
        if (api.memory.has("pularPerfil")) { api.memory.unset("pularPerfil"); chooseProfile(perfil) }
        else openPicker()
    }
    function restoreGame() {
        var k = mkey("game_" + (collection ? collection.shortName : ""))
        gameList.currentIndex = api.memory.has(k) && collection ? Math.min(api.memory.get(k), collection.games.count - 1) : 0
        gameList.positionViewAtIndex(gameList.currentIndex, ListView.Beginning)
    }
    function changeSystem(delta) {
        if (order.length === 0) return
        sysIndex = (sysIndex + delta + order.length) % order.length
        api.memory.set(mkey("sysIndex"), sysIndex)
        restoreGame()
    }
    function launchGame() {
        if (!game || loadingProfile) return
        api.memory.set(mkey("sysIndex"), sysIndex)
        api.memory.set(mkey("game_" + collection.shortName), gameList.currentIndex)
        api.memory.set(mkey("ultimoJogo"), game.title)
        api.memory.set(mkey("ultimoEm"), Date.now())
        game.launch()
    }

    Keys.onPressed: {
        if (loadingProfile) { event.accepted = true; return }
        if (event.isAutoRepeat && (api.keys.isPrevPage(event) || api.keys.isNextPage(event))) return
        if (api.keys.isPrevPage(event) || event.key === Qt.Key_Up) { event.accepted = true; changeSystem(-1) }
        else if (api.keys.isNextPage(event) || event.key === Qt.Key_Down) { event.accepted = true; changeSystem(1) }
        else if (api.keys.isAccept(event)) { event.accepted = true; launchGame() }
        else if (api.keys.isDetails(event) && game) { event.accepted = true; game.favorite = !game.favorite }
        else if (api.keys.isFilters(event)) { event.accepted = true; openPicker() }
    }

    // ---------- fundo (PS5): azul profundo + tela do jogo desfocada ----------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#06112b" }
            GradientStop { position: 1.0; color: "#000308" }
        }
    }
    Image {
        id: hero
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: game ? (game.assets.background || game.assets.screenshot || "") : ""
        sourceSize { width: 640; height: 360 }      // leve: o blur esconde a resolução baixa
        visible: false
    }
    FastBlur {
        id: heroBlur
        anchors.fill: hero
        source: hero
        radius: 48
        opacity: hero.status === Image.Ready ? 0.55 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }
    Rectangle {        // escurece embaixo e à esquerda para o texto
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#99000000" }
            GradientStop { position: 0.45; color: "#33000000" }
            GradientStop { position: 1.0; color: "#e6000000" }
        }
    }

    // ---------- faixa de sistemas (Batocera) ----------
    ListView {
        id: sysBar
        anchors { top: parent.top; left: parent.left; right: clock.left; topMargin: px(36); leftMargin: px(80); rightMargin: px(30) }
        height: px(72)
        orientation: ListView.Horizontal
        spacing: px(14)
        model: root.order
        currentIndex: root.sysIndex
        highlightMoveDuration: 200
        preferredHighlightBegin: 0
        preferredHighlightEnd: width * 0.6
        highlightRangeMode: ListView.ApplyRange
        interactive: false
        delegate: Rectangle {
            readonly property bool sel: index === root.sysIndex
            height: sysBar.height
            width: label.implicitWidth + px(48)
            radius: height / 2
            readonly property var coll: api.collections.get(modelData)
            color: sel ? root.sysColor(coll) : "#26ffffff"
            border.width: sel ? px(3) : 0
            border.color: "white"
            scale: sel ? 1.0 : 0.85
            Behavior on scale { NumberAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                id: label
                anchors.centerIn: parent
                text: coll.shortName.toUpperCase()
                color: "white"
                font { pixelSize: px(30); bold: true; letterSpacing: px(2) }
            }
        }
    }

    // relógio e bateria (PS5)
    Row {
        id: clock
        anchors { top: parent.top; right: parent.right; topMargin: px(52); rightMargin: px(80) }
        spacing: px(28)
        Row {       // perfil atual (só aparece com mais de um perfil)
            spacing: px(12)
            visible: root.perfis.length > 1 && root.profileById(root.perfil) !== null
            readonly property var p: root.profileById(root.perfil)
            Rectangle {
                width: px(40); height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: parent.p ? parent.p.cor : "transparent"
                Text { anchors.centerIn: parent; text: parent.parent.p ? parent.parent.p.nome.charAt(0).toUpperCase() : ""
                       color: "white"; font { pixelSize: px(22); bold: true } }
            }
            Text { text: parent.p ? parent.p.nome : ""; color: "#d0d8ff"; font.pixelSize: px(30) }
        }
        Text {
            id: batt
            readonly property real pct: api.device ? api.device.batteryPercent : NaN
            visible: !isNaN(pct)
            text: Math.round(pct * 100) + "%"
            color: api.device && api.device.batteryCharging ? "#7ee787" : "#d0d8ff"
            font.pixelSize: px(30)
        }
        Text {
            id: timeText
            color: "white"
            font { pixelSize: px(34); bold: true }
            function update() { text = Qt.formatTime(new Date(), "hh:mm") }
            Component.onCompleted: update()
            Timer { interval: 10000; running: true; repeat: true; onTriggered: timeText.update() }
        }
    }

    // nome completo do sistema + contagem
    Text {
        id: sysTitle
        anchors { top: sysBar.bottom; left: parent.left; topMargin: px(28); leftMargin: px(80) }
        text: collection ? collection.name + "  ·  " + collection.games.count + (collection.games.count === 1 ? " jogo" : " jogos") : "Nenhum jogo encontrado"
        color: "#c8d2f0"
        font { pixelSize: px(28); letterSpacing: px(1) }
    }

    // ---------- fileira de capas (PS5) ----------
    ListView {
        id: gameList
        anchors { top: sysTitle.bottom; left: parent.left; right: parent.right; topMargin: px(26) }
        height: px(380)
        leftMargin: px(80)
        rightMargin: px(80)
        orientation: ListView.Horizontal
        spacing: px(26)
        focus: true
        model: collection ? collection.games : []
        highlightMoveDuration: 150
        preferredHighlightBegin: px(80)
        preferredHighlightEnd: px(80) + px(280)
        highlightRangeMode: ListView.StrictlyEnforceRange
        keyNavigationWraps: false
        cacheBuffer: px(2000)
        onCurrentIndexChanged: { videoDelay.restart(); video.stop() }
        delegate: Item {
            readonly property bool sel: ListView.isCurrentItem
            width: sel ? px(280) : px(220)
            height: gameList.height
            Behavior on width { NumberAnimation { duration: 150 } }
            Rectangle {     // moldura branca do selecionado
                anchors.fill: cover
                anchors.margins: -px(6)
                radius: px(14)
                color: "transparent"
                border.width: px(5)
                border.color: "white"
                visible: sel
            }
            Rectangle {
                id: cover
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: sel ? px(370) : px(296)
                Behavior on height { NumberAnimation { duration: 150 } }
                radius: px(10)
                color: "#1b2a4a"
                clip: true
                Image {
                    id: art
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize { width: px(300); height: px(400) }
                    source: modelData.assets.boxFront || modelData.assets.logo || modelData.assets.poster || ""
                }
                Text {      // sem capa: mostra o nome
                    anchors.fill: parent
                    anchors.margins: px(14)
                    visible: art.status !== Image.Ready
                    text: modelData.title
                    color: "white"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font { pixelSize: px(28); bold: true }
                }
                Text {      // favorito
                    anchors { top: parent.top; right: parent.right; margins: px(8) }
                    visible: modelData.favorite
                    text: "★"
                    color: "#ffd54f"
                    font.pixelSize: px(36)
                }
            }
        }
    }

    // ---------- detalhes do jogo + vídeo ----------
    Item {
        id: details
        anchors { top: gameList.bottom; left: parent.left; right: parent.right; bottom: hints.top
                  topMargin: px(24); leftMargin: px(80); rightMargin: px(80) }

        Column {
            anchors { left: parent.left; top: parent.top; right: videoBox.left; rightMargin: px(50) }
            spacing: px(12)
            Image {     // logo do jogo (wheel), se houver; senão, o título
                id: logo
                height: px(110)
                width: Math.min(px(620), parent.width)
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                asynchronous: true
                source: game ? (game.assets.logo || "") : ""
                visible: status === Image.Ready
            }
            Text {
                visible: !logo.visible
                width: parent.width
                text: game ? game.title : ""
                color: "white"
                elide: Text.ElideRight
                font { pixelSize: px(58); bold: true }
            }
            Text {
                width: parent.width
                text: game ? [game.releaseYear > 0 ? game.releaseYear : "", game.developer, game.genre]
                             .filter(function (s) { return s }).join("  ·  ") : ""
                color: "#9fb4e8"
                elide: Text.ElideRight
                font.pixelSize: px(28)
            }
            Text {
                width: parent.width
                text: game ? game.description : ""
                color: "#e6ebff"
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                lineHeight: 1.15
                font.pixelSize: px(26)
            }
        }

        Rectangle {
            id: videoBox
            anchors { right: parent.right; top: parent.top }
            width: px(560)
            height: px(315)
            radius: px(12)
            color: "#80000000"
            clip: true
            visible: shot.status === Image.Ready || video.playbackState === MediaPlayer.PlayingState
            Image {
                id: shot
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize { width: px(560); height: px(315) }
                source: game ? (game.assets.screenshot || "") : ""
            }
            Video {
                id: video
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                source: ""
                muted: false
                volume: 0.6
                loops: MediaPlayer.Infinite
                visible: playbackState === MediaPlayer.PlayingState
            }
            Timer {     // vídeo só depois de parar no jogo por um instante (economiza bateria/CPU)
                id: videoDelay
                interval: 1500
                onTriggered: {
                    if (game && game.assets.video) { video.source = game.assets.video; video.play() }
                }
            }
        }
    }

    // ---------- barra de botões ----------
    Row {
        id: hints
        anchors { bottom: parent.bottom; left: parent.left; bottomMargin: px(36); leftMargin: px(80) }
        spacing: px(46)
        Repeater {
            model: [ { b: "A", t: "Jogar", c: "#2e7d32" }, { b: "X", t: "Favorito", c: "#1565c0" },
                     { b: "Y", t: "Perfil", c: "#f9a825" },
                     { b: "LB RB", t: "Sistema", c: "#455a64" }, { b: "START", t: "Menu", c: "#455a64" } ]
            Row {
                spacing: px(12)
                Rectangle {
                    width: Math.max(px(46), hintKey.implicitWidth + px(20)); height: px(46); radius: height / 2
                    color: modelData.c
                    Text { id: hintKey; anchors.centerIn: parent; text: modelData.b; color: "white"; font { pixelSize: px(22); bold: true } }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: "#d0d8ff"; font.pixelSize: px(26) }
            }
        }
    }

    // ---------- escolha de perfil ("Quem vai jogar?") ----------
    FocusScope {
        id: picker
        anchors.fill: parent
        z: 10
        visible: root.pickerOpen
        readonly property int slots: root.perfis.length + (root.perfis.length < root.maxProfiles ? 1 : 0)
        readonly property var cur: root.pickerIndex < root.perfis.length ? root.perfis[root.pickerIndex] : null
        Keys.onPressed: {
            event.accepted = true
            if (event.isAutoRepeat && api.keys.isAccept(event)) return
            if (event.key === Qt.Key_Left) root.pickerIndex = Math.max(0, root.pickerIndex - 1)
            else if (event.key === Qt.Key_Right) root.pickerIndex = Math.min(slots - 1, root.pickerIndex + 1)
            else if (api.keys.isAccept(event))
                root.chooseProfile(cur ? cur.id : root.newProfile())
            else if (api.keys.isCancel(event)) root.chooseProfile(root.perfil)   // fica no perfil atual
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#f2081638" }
                GradientStop { position: 1.0; color: "#fa000308" }
            }
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: avatars.top; bottomMargin: px(80) }
            text: "Quem vai jogar?"
            color: "white"
            font { pixelSize: px(64); bold: true }
        }
        Row {
            id: avatars
            anchors.centerIn: parent
            spacing: px(70)
            Repeater {
                model: picker.slots
                Column {
                    readonly property bool isNew: index >= root.perfis.length
                    readonly property var p: isNew ? null : root.perfis[index]
                    readonly property bool sel: index === root.pickerIndex
                    spacing: px(22)
                    scale: sel ? 1.12 : 0.9
                    opacity: sel ? 1 : 0.75
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Rectangle {
                        width: px(200); height: width; radius: width / 2
                        color: parent.isNew ? "#26ffffff" : parent.p.cor
                        border.width: parent.sel ? px(8) : 0
                        border.color: "white"
                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.isNew ? "+" : parent.parent.p.nome.charAt(0).toUpperCase()
                            color: "white"
                            font { pixelSize: px(96); bold: true }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.isNew ? "Novo" : parent.p.nome
                        color: parent.sel ? "white" : "#9fb4e8"
                        font { pixelSize: px(34); bold: parent.sel }
                    }
                }
            }
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: avatars.bottom; topMargin: px(60) }
            text: !picker.cur ? "Cria um perfil novo, com saves separados"
                  : api.memory.has(picker.cur.id + "/ultimoJogo")
                    ? "Último jogo: " + api.memory.get(picker.cur.id + "/ultimoJogo") + "  ·  "
                      + root.timeAgo(api.memory.get(picker.cur.id + "/ultimoEm"))
                    : "Ainda não jogou"
            color: "#9fb4e8"
            font.pixelSize: px(30)
        }
        Row {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: px(50) }
            spacing: px(46)
            Repeater {
                model: [ { b: "A", t: "Entrar", c: "#2e7d32" }, { b: "B", t: "Voltar", c: "#c62828" } ]
                Row {
                    spacing: px(12)
                    Rectangle {
                        width: px(46); height: px(46); radius: height / 2; color: modelData.c
                        Text { anchors.centerIn: parent; text: modelData.b; color: "white"; font { pixelSize: px(22); bold: true } }
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: "#d0d8ff"; font.pixelSize: px(26) }
                }
            }
        }
    }

    // ---------- trocando os saves (espera o perfis.sh) ----------
    Rectangle {
        anchors.fill: parent
        z: 11
        visible: root.loadingProfile
        color: "#f2000308"
        Column {
            anchors.centerIn: parent
            spacing: px(30)
            readonly property var p: root.profileById(root.perfil)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: px(160); height: width; radius: width / 2
                color: parent.p ? parent.p.cor : "#1f6feb"
                Text { anchors.centerIn: parent; text: parent.parent.p ? parent.parent.p.nome.charAt(0).toUpperCase() : ""
                       color: "white"; font { pixelSize: px(76); bold: true } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Carregando os saves de " + (parent.p ? parent.p.nome : "") + "…"
                color: "white"
                font.pixelSize: px(36)
            }
        }
    }
}
