import QtQuick
import "astronomy.js" as Astronomy
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: skyView
    implicitWidth:  500
    implicitHeight: 340

    // ── Location ──────────────────────────────────────────────────────
    property real userLat: Plasmoid.configuration.userLat
    property real userLon: Plasmoid.configuration.userLon

    onUserLatChanged: {
        objects = computeObjects()
        cv.requestPaint()
    }
    onUserLonChanged: {
        objects = computeObjects()
        cv.requestPaint()
    }

    property real planetScale: Plasmoid.configuration.planetScale
    property real bgOpacity:   Plasmoid.configuration.bgOpacity

    onPlanetScaleChanged: { objects = computeObjects(); cv.requestPaint() }
    onBgOpacityChanged:   { cv.requestPaint() }

    // ── Icon config ───────────────────────────────────────────────────
    property var iconConfig: ({
        "Sun":     { mode: "image", image: "Sun.png",     size: 25 },
        "Moon":    { mode: "image", size: 16,
                     images: ["Moon0.png","Moon1.png","Moon2.png","Moon3.png",
                              "Moon4.png","Moon5.png","Moon6.png","Moon7.png"] },
        "Mercury": { mode: "image", image: "Mercury.png", size: 7 },
        "Venus":   { mode: "image", image: "Venus.png",   size: 7 },
        "Mars":    { mode: "image", image: "Mars.png",    size: 7 },
        "Jupiter": { mode: "image", size: 13,
                     images: ["Jupiter0.png","Jupiter1.png","Jupiter2.png",
                              "Jupiter3.png","Jupiter4.png"] },
        "Saturn":  { mode: "image", size: 13,
                     images: ["Saturn0.png","Saturn1.png","Saturn2.png",
                              "Saturn3.png","Saturn4.png"] },
        "Uranus":  { mode: "image", image: "Uranus.png",  size: 7 },
        "Neptune": { mode: "image", image: "Neptune.png", size: 7 }
    })

    function iconUrl(name) {
        return Qt.resolvedUrl("icons/" + name)
    }

    property var objects: []
    property real timeOffsetHours: 0

    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        color: "white"
        font.pixelSize: 11
        z: 99
    }

    Canvas {
        id: cv
        anchors.fill: parent

        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
        onImageLoaded:   requestPaint()

        Component.onCompleted: {


            try {
                objects = computeObjects()
            } catch(e) {
                console.log("computeObjects failed:", e)
            }



            loadAllImages()
            requestPaint()
        }

        Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: {
                skyView.objects = computeObjects()
                cv.requestPaint()
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            var W = width
            var H = height
            ctx.clearRect(0, 0, W, H)

            //Background fill
            ctx.fillStyle = "rgba(17,24,39," + skyView.bgOpacity + ")"
            ctx.beginPath()
            if (typeof ctx.roundRect === "function") {
                ctx.roundRect(0, 0, W, H, 10)
            } else {
                ctx.rect(0, 0, W, H)
            }
            ctx.fill()

            if (W < 40 || H < 40) return

            var pad = 40
            var cx  = W / 2
            var hy  = H * 0.75
            var R   = Math.min(cx - pad, hy - 16)

            ctx.save()
            ctx.beginPath()
            ctx.rect(0, 0, W, H)
            ctx.clip()

            // Horizon line
            ctx.beginPath()
            ctx.moveTo(cx - R - 8, hy)
            ctx.lineTo(cx + R + 8, hy)
            ctx.strokeStyle = "rgba(255,255,255,0.30)"
            ctx.lineWidth = 1.5
            ctx.stroke()

            // Horizon end ticks
            ctx.beginPath()
            ctx.moveTo(cx - R, hy - 7)
            ctx.lineTo(cx - R, hy + 7)
            ctx.strokeStyle = "rgba(255,255,255,0.25)"
            ctx.lineWidth = 1.5
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx + R, hy - 7)
            ctx.lineTo(cx + R, hy + 7)
            ctx.strokeStyle = "rgba(255,255,255,0.25)"
            ctx.lineWidth = 1.5
            ctx.stroke()

            // Zenith marker
            ctx.beginPath()
            ctx.moveTo(cx, hy - R - 8)
            ctx.lineTo(cx, hy - R + 8)
            ctx.strokeStyle = "rgba(255,255,255,0.22)"
            ctx.lineWidth = 1
            ctx.stroke()
            ctx.fillStyle = "rgba(255,255,255,0.35)"
            ctx.font = "11px sans-serif"
            ctx.textAlign = "center"
            ctx.fillText("Zenith", cx, hy - R - 12)

            // Clock
            var now = new Date(new Date().getTime() + skyView.timeOffsetHours * 3600000)
            var hh = now.getHours()
            var mm = now.getMinutes()
            var timeStr = (hh < 10 ? "0" : "") + hh + ":" + (mm < 10 ? "0" : "") + mm
            ctx.fillStyle = "rgba(255,255,255,0.45)"
            ctx.font = "20px sans-serif"
            ctx.textAlign = "right"
            ctx.fillText(timeStr, W - pad + 15, hy - R - 8)

            // Outer sky arc
            ctx.beginPath()
            ctx.arc(cx, hy, R, Math.PI, 0, false)
            ctx.strokeStyle = "rgba(255,255,255,0.20)"
            ctx.lineWidth = 1.5
            ctx.stroke()

            // Objects
            for (var i = 0; i < skyView.objects.length; i++) {
                var o = skyView.objects[i]

                var altRad = o.maxAlt * Math.PI / 180
                var acy = hy + R * Math.cos(altRad)

                // Trajectory arc
                ctx.beginPath()
                ctx.arc(cx, acy, R, Math.PI, 0, false)
                ctx.strokeStyle = "rgba(200,215,235,0.13)"
                ctx.lineWidth = 1
                ctx.stroke()

                var riseAngle  = Math.PI / 2 + altRad
                var setAngle   = Math.PI / 2 - altRad
                var renderFrac = Math.max(-0.15, Math.min(1.15, o.frac))
                var angle = riseAngle + (setAngle - riseAngle) * renderFrac
                var ox = cx + R * Math.cos(angle)
                var oy = acy - R * Math.sin(angle)
                var above = oy < hy + 15

                if (above) {
                    var sz = o.size

                    if (o.mode === "image") {
                        var src = (o.images && o.images.length > 0)
                            ? iconUrl(o.images[o.imageIndex || 0])
                            : iconUrl(o.image)



                            ctx.save()
                            ctx.beginPath()
                            ctx.arc(ox, oy, sz, 0, Math.PI * 2)
                            ctx.clip()
                            if (o.imageFlip) {
                                ctx.translate(ox, oy)
                                ctx.scale(-1, 1)
                                ctx.drawImage(src, -sz, -sz, sz * 2, sz * 2)
                            } else {
                                ctx.drawImage(src, ox - sz, oy - sz, sz * 2, sz * 2)
                            }
                            ctx.restore()




                        // Reddish tint near horizon for Sun and Moon
                        if (o.name === "Sun" || o.name === "Moon") {
                            var horizonDist = (hy - oy) / R
                            var tint = Math.max(0, 1 - horizonDist * 4)
                            if (tint > 0) {
                                ctx.save()
                                ctx.beginPath()
                                ctx.arc(ox, oy, sz, 0, Math.PI * 2)
                                ctx.clip()

                                if (o.name === "Moon") {ctx.fillStyle = "rgba(200,40,10," + (tint * 0.35) + ")"}else{ctx.fillStyle = "rgba(200,80,20," + (tint * 0.6) + ")"}

                                ctx.fillRect(ox - sz, oy - sz, sz * 2, sz * 2)
                                ctx.restore()
                            }
                        }

                    } else {
                        var g2 = ctx.createRadialGradient(ox, oy, 0, ox, oy, sz * 3.5)
                        g2.addColorStop(0, o.halo || "rgba(255,255,255,0.15)")
                        g2.addColorStop(1, "rgba(0,0,0,0)")
                        ctx.beginPath()
                        ctx.arc(ox, oy, sz * 3.5, 0, Math.PI * 2)
                        ctx.fillStyle = g2
                        ctx.fill()
                        ctx.beginPath()
                        ctx.arc(ox, oy, sz, 0, Math.PI * 2)
                        ctx.fillStyle = o.color
                        ctx.fill()
                    }

                    // Label
                    ctx.fillStyle = "rgba(255,255,255,0.55)"
                    ctx.font = "11px sans-serif"
                    ctx.textAlign = "center"
                    ctx.fillText(o.name, ox, oy + sz + 14)

                } else {
                    // Below horizon ghost
                    ctx.beginPath()
                    ctx.arc(ox, oy, o.size * 0.5, 0, Math.PI * 2)
                    ctx.fillStyle = "rgba(255,255,255,0.10)"
                    ctx.fill()
                }
            }

            ctx.restore()

            // Fade below horizon
            var fade = ctx.createLinearGradient(0, hy, 0, hy + 50)
            fade.addColorStop(0, "rgba(17,24,39,0)")
            fade.addColorStop(1, "rgba(17,24,39,1)")
            ctx.fillStyle = fade
            ctx.fillRect(0, hy, W, 500)
        }
    }

    // ── Time slider ───────────────────────────────────────────────────
    //Slider disabled because of performance issues
    /*MouseArea {
        id: sliderArea
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        anchors.bottomMargin: 8

        property bool dragging: false

        onPressed:  { dragging = true }
        onReleased: {
            dragging = false
            skyView.timeOffsetHours = 0
            skyView.objects = computeObjects()
            cv.requestPaint()
        }
        onMouseXChanged: {
            if (!dragging) return
                var newOffset = Math.round((mouseX / width - 0.5) * 24 * 2) / 2  // snap to 0.5h steps
                if (newOffset === skyView.timeOffsetHours) return  // no change, skip
                    skyView.timeOffsetHours = newOffset
                    skyView.objects = computeObjects()
                    cv.requestPaint()
        }

        // Track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 2
            color: "#1fffffff"
            radius: 1

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 6
                color: "#40ffffff"
            }
        }

        // Thumb
        Rectangle {
            width: 14; height: 14; radius: 7
            color: skyView.timeOffsetHours === 0 ? "#4dffffff" : "#b3ffffff"
            anchors.verticalCenter: parent.verticalCenter
            x: ((skyView.timeOffsetHours / 24) + 0.5) * (sliderArea.width - 32) + 16 - 7
        }

        // Offset label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 2
            text: skyView.timeOffsetHours === 0 ? "" :
                  (skyView.timeOffsetHours > 0 ? "+" : "") +
                  skyView.timeOffsetHours.toFixed(1) + "h"
            color: "#73ffffff"
            font.pixelSize: 10
            visible: sliderArea.dragging
        }
    }*/

    Item {
        id: infoPanel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56
        anchors.bottomMargin: 4

        Row {
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: skyView.objects.filter(function(o) { return o.frac >= 0 && o.frac <= 1 })

                delegate: Rectangle {
                    width: 58
                    height: 48
                    radius: 6
                    color: "#12ffffff"
                    border.color: "#1fffffff"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            color: "#d9ffffff"
                            font.pixelSize: 10
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.riseTime ? formatTime(modelData.riseTime) : "--:--"
                            color: "#ffc864"
                            font.pixelSize: 9
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.setTime ? formatTime(modelData.setTime) : "--:--"
                            color: "#64b4ff"
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }
    }

    // ── Astronomy calculations ────────────────────────────────────────

function computeObjects() {

    var date = new Date(new Date().getTime() + skyView.timeOffsetHours * 3600000)

    try {
        var observer = new Astronomy.Observer(userLat, userLon, 0)
    } catch(e) {
        console.log("Astronomy not available:", e)
        return []
    }

    var bodyNames = ["Sun","Moon","Mercury","Venus","Mars","Jupiter","Saturn","Uranus","Neptune"]
    var result = []

    for (var i = 0; i < bodyNames.length; i++) {
        var name = bodyNames[i]
        var body = Astronomy.Body[name]
        var cfg  = iconConfig[name] || { mode: "color", color: "#ffffff", halo: "#33ffffff", size: 7 }

        // Current altitude
        var eq  = Astronomy.Equator(body, date, observer, true, true)
        var hor = Astronomy.Horizon(date, observer, eq.ra, eq.dec, "normal")
        var alt = hor.altitude

        var rise, set, frac = 0

        if (alt >= 0) {
            rise = Astronomy.SearchRiseSet(body, observer, +1, date, -1)
            set  = Astronomy.SearchRiseSet(body, observer, -1, date, +1)
            if (rise && set)
                frac = (date.getTime() - rise.date.getTime()) /
                       (set.date.getTime()  - rise.date.getTime())
        } else {
            var lastSet  = Astronomy.SearchRiseSet(body, observer, -1, date, -1)
            var nextRise = Astronomy.SearchRiseSet(body, observer, +1, date, +1)

            var dtLastSet  = lastSet  ? date.getTime() - lastSet.date.getTime()  : Infinity
            var dtNextRise = nextRise ? nextRise.date.getTime() - date.getTime() : Infinity

            if (dtLastSet <= dtNextRise && lastSet) {
                rise = Astronomy.SearchRiseSet(body, observer, +1, lastSet.date, -1)
                set  = lastSet
            } else if (nextRise) {
                rise = nextRise
                set  = Astronomy.SearchRiseSet(body, observer, -1, nextRise.date, +1)
            }
            if (rise && set)
                frac = (date.getTime() - rise.date.getTime()) /
                       (set.date.getTime()  - rise.date.getTime())
        }

        // Transit altitude (maxAlt)
        var transit = Astronomy.SearchHourAngle(body, observer, 0, date, +1)
        var maxAlt  = (transit && transit.hor) ? transit.hor.altitude : Math.max(alt, 10)
        maxAlt = Math.max(5, Math.min(90, maxAlt))

        // Moon phase index (0-7)
        var moonImageIndex = 0
        if (name === "Moon") {
            var phase = Astronomy.MoonPhase(date)
            var phaseMap = [4, 3, 2, 1, 0, 7, 6, 5]
            moonImageIndex = phaseMap[Math.floor(phase / 45) % 8]
        }

        // Saturn ring tilt index (0-4) with flip
        var saturnImageIndex = 4
        var saturnFlip = false
        if (name === "Saturn") {
            var illum = Astronomy.Illumination(body, date)
            var tilt = illum.ring_tilt || 0
            saturnFlip = tilt > 0
            saturnImageIndex = 4 - Math.min(4, Math.floor(Math.abs(tilt) / 6))
        }

        // Jupiter rotation index (0-4) with flip
        var jupiterImageIndex = 0
        var jupiterFlip = false
        if (name === "Jupiter") {
            // Jupiter System II (GRS) period: 9h 55m 30s
            var periodMs = 9.925 * 3600000

            // CML at J2000 epoch (System II) = 138°
            // Adjust epochOffset in hours to calibrate against a real observation
            var epochOffset = 9.5
            var epoch = new Date("2000-01-01T12:00:00Z").getTime() + epochOffset * 3600000

            var elapsed = date.getTime() - epoch
            var cml = ((-(elapsed % periodMs) / periodMs * 360) + 360) % 360

            // GRS is visible when CML is near 0°/360° — occupies ~60° either side
            var grsDist = Math.min(cml, 360 - cml)  // 0=facing us, 180=far side
            var pos = grsDist / 180  // 0→1, 0=center, 1=far side

            if (pos < 0.5) {
                // GRS visible
                var spotPos = pos * 2  // 0=center, 1=limb
                var step = Math.floor(spotPos * 4)
                jupiterImageIndex = 4 - step  // 4=center, 1=limb
                jupiterFlip = cml > 180  // mirror for left/right side
            }
            // else: GRS on far side, jupiterImageIndex stays 0
        }

        result.push({
            name:       name,
            maxAlt:     maxAlt,
            riseTime: rise ? rise.date : null,
            setTime:  set  ? set.date  : null,
            frac:       frac,
            mode:       cfg.mode,
            size:       cfg.size * skyView.planetScale,
            color:      cfg.color  || "#ffffff",
            halo:       cfg.halo   || "#33ffffff",
            image:      cfg.image  || (cfg.images ? cfg.images[0] : ""),
            images:     cfg.images || null,
            imageIndex: name === "Moon"    ? moonImageIndex
                      : name === "Saturn"  ? saturnImageIndex
                      : name === "Jupiter" ? jupiterImageIndex
                      : 0,
            imageFlip:  name === "Jupiter" ? jupiterFlip
                      : name === "Saturn"  ? saturnFlip
                      : false
        })
    }
    return result
}

function formatTime(d) {
    var local = new Date(d.getTime())
    var hh = local.getHours()
    var mm = local.getMinutes()
    return (hh < 10 ? "0" : "") + hh + ":" + (mm < 10 ? "0" : "") + mm
}

function loadAllImages() {
    var allImages = [
        "Sun.png", "Mercury.png", "Venus.png",
        "Mars.png", "Uranus.png", "Neptune.png"
    ]
    var multi  = ["moon", "Jupiter", "Saturn"]
    var counts = { moon: 8, Jupiter: 5, Saturn: 5 }
    for (var m = 0; m < multi.length; m++) {
        var nm = multi[m]
        for (var k = 0; k < counts[nm]; k++)
            allImages.push(nm + k + ".png")
    }
    for (var n = 0; n < allImages.length; n++)
        cv.loadImage(iconUrl(allImages[n]))
}
}
