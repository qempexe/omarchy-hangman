import QtQuick

// the drawing that changes with every wrong letter.
// style: gallows | balloons | snowman | hearts
// shown follows wrong with an animation, so parts fade/grow in instead of popping
Canvas {
    id: fig

    property var ui: null
    property string style: "gallows"
    property int wrong: 0
    property int lives: 6
    property string status: "playing"     // playing | won | lost
    property real shown: wrong
    property bool animate: ui ? ui.animations : true
    Behavior on shown { enabled: fig.animate; NumberAnimation { duration: fig.ui ? fig.ui.speed * 1.6 : 300; easing.type: Easing.OutCubic } }

    // little loop for wins (and the settings tiles)
    property real bob: 0
    SequentialAnimation on bob {
        running: fig.status === "won" && fig.animate && fig.visible
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 600; easing.type: Easing.InOutSine }
        onRunningChanged: if (!running) fig.bob = 0
    }

    readonly property color ink: ui ? ui.fg : "white"
    readonly property color accent: ui ? ui.accent : "orange"
    readonly property color bad: ui ? ui.bad : "red"
    readonly property real lost: lives > 0 ? Math.max(0, Math.min(1, shown / lives)) : 0

    onShownChanged: requestPaint()
    onBobChanged: requestPaint()
    onStyleChanged: requestPaint()
    onStatusChanged: requestPaint()
    onLivesChanged: requestPaint()
    onInkChanged: requestPaint()
    onAccentChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function rgba(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (width < 4 || height < 4) return
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        if (style === "balloons") drawBalloons(ctx)
        else if (style === "snowman") drawSnowman(ctx)
        else if (style === "hearts") drawHearts(ctx)
        else drawGallows(ctx)
    }

    // ---- gallows: frame is there from the start, the figure comes a part at a time

    function line(ctx, x1, y1, x2, y2, t) {
        if (t <= 0) return
        ctx.beginPath()
        ctx.moveTo(x1, y1)
        ctx.lineTo(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t)
        ctx.stroke()
    }

    function drawGallows(ctx) {
        const s = Math.min(width / 1.0, height / 1.15)
        const ox = (width - s) / 2, oy = (height - s * 1.15) / 2
        function X(v) { return ox + v * s }
        function Y(v) { return oy + v * s }
        const w = Math.max(2, s * 0.028)

        ctx.lineWidth = w
        ctx.strokeStyle = rgba(ink, 0.55)
        line(ctx, X(0.12), Y(1.08), X(0.72), Y(1.08), 1)       // ground
        line(ctx, X(0.28), Y(1.08), X(0.28), Y(0.08), 1)       // pole
        line(ctx, X(0.28), Y(0.08), X(0.70), Y(0.08), 1)       // beam
        line(ctx, X(0.28), Y(0.26), X(0.46), Y(0.08), 1)       // brace
        ctx.strokeStyle = rgba(ink, 0.4)
        line(ctx, X(0.70), Y(0.08), X(0.70), Y(0.22), 1)       // rope

        // 6 parts spread over however many lives there are
        const parts = lost * 6
        const dead = status === "lost"
        const col = dead ? bad : (status === "won" ? accent : ink)
        const lift = status === "won" ? -bob * s * 0.02 : 0
        ctx.strokeStyle = col
        ctx.lineWidth = w
        const hx = X(0.70), hy = Y(0.30) + lift, hr = s * 0.08
        const t = clamp01(parts)
        if (t > 0) {                                             // head
            ctx.beginPath()
            ctx.arc(hx, hy, hr, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * t, false)
            ctx.stroke()
        }
        line(ctx, hx, hy + hr, hx, Y(0.66) + lift, clamp01(parts - 1))                // body
        line(ctx, hx, Y(0.45) + lift, X(0.58), Y(0.57) + lift, clamp01(parts - 2))    // arms
        line(ctx, hx, Y(0.45) + lift, X(0.82), Y(0.57) + lift, clamp01(parts - 3))
        line(ctx, hx, Y(0.66) + lift, X(0.60), Y(0.84) + lift, clamp01(parts - 4))    // legs
        line(ctx, hx, Y(0.66) + lift, X(0.80), Y(0.84) + lift, clamp01(parts - 5))

        if (t >= 1) face(ctx, hx, hy, hr, dead ? "x" : (status === "won" ? "smile" : "worry"), col)
    }

    function face(ctx, cx, cy, r, kind, col) {
        ctx.save()
        ctx.lineWidth = Math.max(1.2, r * 0.16)
        ctx.strokeStyle = col
        ctx.fillStyle = col
        const ex = r * 0.38, ey = -r * 0.18
        if (kind === "x") {
            const k = r * 0.16
            for (let side = -1; side <= 1; side += 2) {
                line(ctx, cx + side * ex - k, cy + ey - k, cx + side * ex + k, cy + ey + k, 1)
                line(ctx, cx + side * ex + k, cy + ey - k, cx + side * ex - k, cy + ey + k, 1)
            }
            line(ctx, cx - r * 0.3, cy + r * 0.42, cx + r * 0.3, cy + r * 0.42, 1)
        } else {
            for (let s2 = -1; s2 <= 1; s2 += 2) {
                ctx.beginPath(); ctx.arc(cx + s2 * ex, cy + ey, Math.max(1, r * 0.1), 0, Math.PI * 2); ctx.fill()
            }
            ctx.beginPath()
            if (kind === "smile") ctx.arc(cx, cy + r * 0.12, r * 0.38, 0.15 * Math.PI, 0.85 * Math.PI, false)
            else ctx.arc(cx, cy + r * 0.62, r * 0.3, 1.2 * Math.PI, 1.8 * Math.PI, false)
            ctx.stroke()
        }
        ctx.restore()
    }

    // ---- balloons: one per life, a wrong letter pops one

    function drawBalloons(ctx) {
        const n = Math.max(1, lives)
        const s = Math.min(width, height * 0.95)
        const cx = width / 2
        const dead = status === "lost"
        const drop = dead ? clamp01(shown - lives + 1) * height * 0.12 : 0
        const by = height * 0.82 + drop - (status === "won" ? bob * s * 0.03 : 0)    // basket
        const bw = s * 0.16, bh = s * 0.1
        const top = height * 0.06
        const r = Math.min(s * 0.11, (width * 0.86) / (n * 1.25) * 0.9)
        for (let i = 0; i < n; i++) {
            const popped = clamp01(shown - (n - 1 - i))      // the right-most ones go first
            if (popped >= 1) continue
            const fx = n === 1 ? 0.5 : i / (n - 1)
            const bx = cx + (fx - 0.5) * Math.min(width * 0.78, n * r * 2.3)
            const yy = top + r + (i % 2) * r * 0.55 + (status === "won" ? Math.sin(i + bob * 3) * r * 0.08 : 0)
            const hue = ui && ui.mono ? 0 : (i * 0.13) % 1
            const col = ui && ui.mono ? rgba(ink, 0.8)
                : Qt.hsla((accent.hslHue + hue) % 1, Math.max(0.45, accent.hslSaturation), Math.min(0.7, Math.max(0.45, accent.hslLightness)), 1)
            const sc = 1 + popped * 0.5
            const a = 1 - popped
            ctx.globalAlpha = a
            ctx.strokeStyle = rgba(ink, 0.45)
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(bx, yy + r * 1.15)
            ctx.quadraticCurveTo(bx + (cx - bx) * 0.3, (yy + by) / 2, cx, by - bh / 2)
            ctx.stroke()
            ctx.fillStyle = col
            ctx.beginPath()
            ctx.ellipse(bx - r * sc, yy - r * 1.15 * sc, r * 2 * sc, r * 2.3 * sc)
            ctx.fill()
            ctx.fillStyle = rgba(Qt.rgba(1, 1, 1, 1), 0.35)
            ctx.beginPath()
            ctx.ellipse(bx - r * 0.55, yy - r * 0.8, r * 0.45, r * 0.6)
            ctx.fill()
            ctx.globalAlpha = 1
        }
        // basket + a little passenger
        const col2 = dead ? bad : ink
        ctx.strokeStyle = col2
        ctx.lineWidth = Math.max(1.5, s * 0.014)
        ctx.strokeRect(cx - bw / 2, by - bh / 2, bw, bh)
        ctx.beginPath()
        ctx.arc(cx, by - bh / 2 - s * 0.045, s * 0.035, 0, Math.PI * 2)
        ctx.stroke()
        if (!dead) {
            ctx.strokeStyle = rgba(ink, 0.3)
            line(ctx, width * 0.1, height * 0.97, width * 0.9, height * 0.97, 1)
        } else {
            ctx.strokeStyle = rgba(bad, 0.5)
            line(ctx, width * 0.1, height * 0.97, width * 0.9, height * 0.97, 1)
        }
    }

    // ---- snowman: melts a bit with every wrong letter

    function drawSnowman(ctx) {
        const s = Math.min(width, height)
        const cx = width / 2
        const ground = height * 0.92
        const p = lost
        const squash = 1 - 0.72 * p
        const col = status === "lost" ? bad : ink
        const won = status === "won"

        // sun, it gets bigger as things go wrong
        ctx.fillStyle = rgba(accent, 0.85)
        const sr = s * (0.05 + 0.05 * p)
        ctx.beginPath(); ctx.arc(width * 0.84, height * 0.14, sr, 0, Math.PI * 2); ctx.fill()
        ctx.strokeStyle = rgba(accent, 0.6)
        ctx.lineWidth = Math.max(1, s * 0.01)
        for (let k = 0; k < 8; k++) {
            const ang = k * Math.PI / 4 + (won ? bob * 0.4 : 0)
            line(ctx, width * 0.84 + Math.cos(ang) * sr * 1.35, height * 0.14 + Math.sin(ang) * sr * 1.35,
                      width * 0.84 + Math.cos(ang) * sr * 1.8, height * 0.14 + Math.sin(ang) * sr * 1.8, 1)
        }

        // puddle
        ctx.fillStyle = rgba(ink, 0.12 + 0.1 * p)
        ctx.beginPath()
        ctx.ellipse(cx - s * (0.2 + 0.18 * p), ground - s * 0.03, s * (0.4 + 0.36 * p), s * 0.06)
        ctx.fill()

        const r1 = s * 0.17, r2 = s * 0.125, r3 = s * 0.09
        const y1 = ground - r1 * squash
        const y2 = y1 - (r1 + r2 * 0.92) * squash
        const y3 = y2 - (r2 + r3 * 0.92) * squash - (won ? bob * s * 0.015 : 0)
        ctx.lineWidth = Math.max(1.5, s * 0.016)
        ctx.strokeStyle = col
        ctx.fillStyle = rgba(ink, 0.08)
        const balls = [[y1, r1], [y2, r2], [y3, r3]]
        for (let b = 0; b < 3; b++) {
            ctx.beginPath()
            ctx.ellipse(cx - balls[b][1], balls[b][0] - balls[b][1] * squash, balls[b][1] * 2, balls[b][1] * 2 * squash)
            ctx.fill(); ctx.stroke()
        }
        // things fall off in this order
        const keep = at => clamp01((at - p) * 6)
        let a
        if ((a = keep(0.2)) > 0) {          // hat
            ctx.globalAlpha = a
            ctx.fillStyle = col
            const hy = y3 - r3 * 2 * squash + r3 * 0.25 - (1 - a) * s * 0.1
            ctx.fillRect(cx - r3 * 0.9, hy - s * 0.012, r3 * 1.8, s * 0.024)
            ctx.fillRect(cx - r3 * 0.55, hy - r3 * 1.1, r3 * 1.1, r3 * 1.1)
            ctx.fillStyle = accent
            ctx.fillRect(cx - r3 * 0.55, hy - r3 * 0.35, r3 * 1.1, r3 * 0.22)
        }
        if ((a = keep(0.38)) > 0) {         // left arm
            ctx.globalAlpha = a
            ctx.strokeStyle = col
            line(ctx, cx - r2 * 0.9, y2 - r2 * squash, cx - r2 * 2.1, y2 - r2 * (1.6 + (won ? bob * 0.6 : 0)) * squash, 1)
        }
        if ((a = keep(0.55)) > 0) {         // right arm
            ctx.globalAlpha = a
            ctx.strokeStyle = col
            line(ctx, cx + r2 * 0.9, y2 - r2 * squash, cx + r2 * 2.1, y2 - r2 * (1.6 + (won ? bob * 0.6 : 0)) * squash, 1)
        }
        if ((a = keep(0.72)) > 0) {         // nose
            ctx.globalAlpha = a
            ctx.fillStyle = ui && ui.mono ? col : Qt.rgba(0.95, 0.55, 0.2, 1)
            const ny = y3 - r3 * squash
            ctx.beginPath(); ctx.moveTo(cx, ny - r3 * 0.12); ctx.lineTo(cx + r3 * 0.9, ny); ctx.lineTo(cx, ny + r3 * 0.12); ctx.fill()
        }
        ctx.globalAlpha = 1
        if (p < 0.9) {                      // eyes + buttons
            ctx.fillStyle = col
            const ey = y3 - r3 * 1.3 * squash
            ctx.beginPath(); ctx.arc(cx - r3 * 0.35, ey, Math.max(1, s * 0.011), 0, Math.PI * 2); ctx.fill()
            ctx.beginPath(); ctx.arc(cx + r3 * 0.35, ey, Math.max(1, s * 0.011), 0, Math.PI * 2); ctx.fill()
            for (let bt = 0; bt < 3; bt++) {
                ctx.beginPath(); ctx.arc(cx, y2 - r2 * (0.5 + bt * 0.5) * squash, Math.max(1, s * 0.012), 0, Math.PI * 2); ctx.fill()
            }
        }
    }

    // ---- hearts: one per life

    function heart(ctx, x, y, r) {
        ctx.beginPath()
        ctx.moveTo(x, y + r * 0.35)
        ctx.bezierCurveTo(x, y - r * 0.35, x - r, y - r * 0.35, x - r, y + r * 0.2)
        ctx.bezierCurveTo(x - r, y + r * 0.75, x - r * 0.2, y + r * 1.1, x, y + r * 1.35)
        ctx.bezierCurveTo(x + r * 0.2, y + r * 1.1, x + r, y + r * 0.75, x + r, y + r * 0.2)
        ctx.bezierCurveTo(x + r, y - r * 0.35, x, y - r * 0.35, x, y + r * 0.35)
        ctx.closePath()
    }

    function drawHearts(ctx) {
        const n = Math.max(1, lives)
        const cols = n <= 5 ? n : Math.ceil(n / 2)
        const rows = Math.ceil(n / cols)
        const cell = Math.min(width / cols, height / rows / 1.15)
        const r = cell * 0.36
        const ox = (width - cols * cell) / 2, oy = (height - rows * cell * 1.15) / 2
        for (let i = 0; i < n; i++) {
            const row = Math.floor(i / cols), c = i % cols
            const inRow = Math.min(cols, n - row * cols)
            const x = ox + (c + 0.5) * cell + (cols - inRow) * cell / 2
            const y = oy + row * cell * 1.15 + cell * 0.3
            const gone = clamp01(shown - (n - 1 - i))
            const beat = status === "won" ? 1 + bob * 0.08 : 1
            ctx.lineWidth = Math.max(1.2, r * 0.12)
            ctx.strokeStyle = status === "lost" ? rgba(bad, 0.7) : rgba(ink, 0.35)
            heart(ctx, x, y - r * (beat - 1), r * beat)
            ctx.stroke()
            if (gone < 1) {
                ctx.globalAlpha = 1 - gone
                ctx.fillStyle = accent
                const rr = r * beat * (1 - gone * 0.4)
                heart(ctx, x, y + (r - rr) * 0.6, rr)
                ctx.fill()
                ctx.globalAlpha = 1
            }
        }
    }
}
