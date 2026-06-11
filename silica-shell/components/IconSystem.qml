pragma Singleton
import QtQuick

QtObject {
    id: icons

    readonly property string fontFamily: "Phosphor-Bold"
    readonly property int defaultSize: 14

    readonly property QtObject wifi: QtObject {
        readonly property string on: "\ue4ea"
        readonly property string searching: "\ue4f0"
        readonly property string off: "\ue4f2"
        readonly property string lock: "\ue308"
        readonly property string signal0: "\ue4f0"
        readonly property string signal1: "\ue4ec"
        readonly property string signal2: "\ue4ee"
        readonly property string signal3: "\ue4ea"
    }

    readonly property QtObject bluetooth: QtObject {
        readonly property string on: "\ue0da"
        readonly property string off: "\ue0de"
        readonly property string paired: "\ue182"
        readonly property string scanning: "\ue4f0"
        readonly property string connected: "\ue0dc"
        readonly property string disconnected: "\ue0de"
    }

    readonly property QtObject audio: QtObject {
        readonly property string volumeHigh: "\ue44a"
        readonly property string volumeMid: "\ue44c"
        readonly property string volumeLow: "\ue44e"
        readonly property string muted: "\ue456"
        readonly property string speaker: "\ue44a"
        readonly property string mic: "\ue326"
        readonly property string micMuted: "\ue328"
        readonly property string checkmark: "\ue182"
        readonly property string defaultDevice: "\ue184"
    }

    readonly property QtObject brightness: QtObject {
        readonly property string high: "\ue472"
        readonly property string medium: "\ue474"
        readonly property string low: "\ue5b6"
        readonly property string off: "\ue3da"
        readonly property string displayPort: "\ue32e"
        readonly property string hdmi: "\ue754"
        readonly property string generic: "\ue560"
    }

    readonly property QtObject battery: QtObject {
        readonly property string full: "\ue0c0"
        readonly property string high: "\ue0c2"
        readonly property string medium: "\ue0c6"
        readonly property string low: "\ue0c4"
        readonly property string critical: "\ue0be"
        readonly property string charging: "\ue0ba"
    }

    readonly property QtObject workspace: QtObject {
        readonly property string active: "\ue184"
        readonly property string inactive: "\ue18a"
        readonly property string hasWindow: "\ue192"
    }

    readonly property QtObject window: QtObject {
        readonly property string maximize: "\ue972"
        readonly property string minimize: "\ue970"
        readonly property string close: "\ue4f6"
    }

    readonly property QtObject action: QtObject {
        readonly property string refresh: "\ue036"
        readonly property string loading: "\ue036"
        readonly property string check: "\ue182"
        readonly property string error: "\ue4e2"
        readonly property string warning: "\ue4e0"
        readonly property string info: "\ue2ce"
        readonly property string settings: "\ue270"
        readonly property string menu: "\ue2f0"
        readonly property string disconnect: "\ue2e4"
        readonly property string connect: "\ue2e2"
        readonly property string forget: "\ue4a6"
        readonly property string eye: "\ue220"
        readonly property string eyeSlash: "\ue224"
        readonly property string link: "\ue2e2"
        readonly property string powerOff: "\ue3da"
    }

    readonly property QtObject app: QtObject {
        readonly property string firefox: "\ue0f4"
        readonly property string chrome: "\ue976"
        readonly property string terminal: "\ue47e"
        readonly property string code: "\ue1bc"
        readonly property string opencode: "\ue1bc"
        readonly property string folder: "\ue24a"
        readonly property string discord: "\ue61a"
        readonly property string spotify: "\ue66e"
        readonly property string steam: "\uead4"
        readonly property string lutris: "\ue26e"
        readonly property string gamepad: "\ue26e"
        readonly property string video: "\ue4da"
        readonly property string image: "\ue2ca"
        readonly property string edit: "\ue3ae"
        readonly property string envelope: "\ue214"
        readonly property string music: "\ue33c"
    }

    readonly property QtObject weather: QtObject {
        readonly property string clear: "\ue472"
        readonly property string partlyCloudy: "\ue540"
        readonly property string cloudy: "\ue1aa"
        readonly property string fog: "\ue53c"
        readonly property string rain: "\ue1b4"
        readonly property string heavyRain: "\ue1b6"
        readonly property string snow: "\ue1b8"
        readonly property string thunder: "\ue1b2"
        readonly property string tornado: "\ue53c"
    }

    readonly property QtObject colors: QtObject {
        readonly property string success: "#ffffff"
        readonly property string active: "#ffffff"
        readonly property string primary: "#ffffff"
        readonly property string secondary: "#ffffff"
        readonly property string accent: "#ffffff"
        readonly property string error: "#ffffff"
        readonly property string critical: "#ffffff"
        readonly property string disabled: "#ffffff"
        readonly property string muted: "#ffffff"
        readonly property string inactive: "#ffffff"
    }

    function batteryIcon(percentage) {
        if (percentage >= 80) return battery.full
        if (percentage >= 50) return battery.high
        if (percentage >= 20) return battery.medium
        if (percentage >= 5) return battery.low
        return battery.critical
    }

    function batteryColor(percentage) {
        return "#ffffff"
    }

    function audioIcon(volume, isMuted) {
        if (isMuted) return audio.muted
        if (volume > 0.65) return audio.volumeHigh
        if (volume > 0.30) return audio.volumeMid
        return audio.volumeLow
    }

    function brightnessIcon(brightnessLevel) {
        if (brightnessLevel > 0.75) return brightness.high
        if (brightnessLevel > 0.50) return brightness.medium
        if (brightnessLevel > 0.00) return brightness.low
        return brightness.off
    }

    function statusColor(isActive) {
        return "#ffffff"
    }

    function wifiIcon(connected, powerOn) {
        if (!powerOn) return wifi.off
        return connected ? wifi.on : wifi.off
    }

    function wifiIconColor(connected, powerOn) {
        return "#ffffff"
    }

    function wifiSignalIcon(intensity) {
        if (intensity >= 75) return wifi.signal3
        if (intensity >= 50) return wifi.signal2
        if (intensity >= 25) return wifi.signal1
        return wifi.signal0
    }

    function displayIcon(name) {
        if (name.indexOf("DP-") === 0) return brightness.displayPort
        if (name.indexOf("HDMI-") === 0) return brightness.hdmi
        return brightness.generic
    }

    function weatherIcon(code) {
        if (code === 0) return weather.clear
        if (code <= 3) return weather.partlyCloudy
        if (code <= 49) return weather.cloudy
        if (code <= 59) return weather.rain
        if (code <= 69) return weather.snow
        if (code <= 77) return weather.snow
        if (code <= 82) return weather.rain
        if (code <= 86) return weather.heavyRain
        if (code <= 99) return weather.tornado
        return weather.cloudy
    }

    function getAppIcon(clientClass) {
        if (!clientClass) return ""
        let cls = clientClass.toLowerCase()
        if (cls.indexOf("firefox") !== -1) return app.firefox
        if (cls.indexOf("chromium") !== -1 || cls.indexOf("chrome") !== -1) return app.chrome
        if (cls.indexOf("kitty") !== -1 || cls.indexOf("alacritty") !== -1 || cls.indexOf("foot") !== -1 || cls.indexOf("terminal") !== -1) return app.terminal
        if (cls.indexOf("opencode") !== -1) return app.opencode
        if (cls.indexOf("code") !== -1 || cls.indexOf("vscodium") !== -1) return app.code
        if (cls.indexOf("thunar") !== -1 || cls.indexOf("nemo") !== -1 || cls.indexOf("dolphin") !== -1 || cls.indexOf("nautilus") !== -1) return app.folder
        if (cls.indexOf("discord") !== -1) return app.discord
        if (cls.indexOf("spotify") !== -1) return app.spotify
        if (cls.indexOf("steam") !== -1) return app.steam
        if (cls.indexOf("lutris") !== -1) return app.lutris
        if (cls.indexOf("game") !== -1) return app.gamepad
        if (cls.indexOf("vlc") !== -1 || cls.indexOf("mpv") !== -1) return app.video
        if (cls.indexOf("gimp") !== -1) return app.image
        if (cls.indexOf("obsidian") !== -1) return app.edit
        if (cls.indexOf("mail") !== -1 || cls.indexOf("thunderbird") !== -1) return app.envelope
        return ""
    }
}
