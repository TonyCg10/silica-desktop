use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::Path;

fn buscar_icono_en_dir(dir: &str, nombre: &str) -> Option<String> {
    let sizes = [
        "scalable", "48x48", "64x64", "32x32", "24x24", "22x22", "16x16",
    ];
    let exts = [".svg", ".png", ".xpm"];

    for size in &sizes {
        for ext in &exts {
            let path = format!("{}/{}/apps/{}{}", dir, size, nombre, ext);
            if Path::new(&path).exists() {
                return Some(path);
            }
        }
    }

    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let name = entry.file_name();
            let name_str = name.to_string_lossy().to_string();
            let subdir = format!("{}/{}", dir, name_str);
            if entry.file_type().map(|t| t.is_dir()).unwrap_or(false) {
                for ext in &exts {
                    let path = format!("{}/apps/{}{}", subdir, nombre, ext);
                    if Path::new(&path).exists() {
                        return Some(path);
                    }
                }
            }
        }
    }

    None
}

fn buscar_en_pixmaps(nombre: &str) -> Option<String> {
    let pixmaps = "/usr/share/pixmaps";
    let exts = [".svg", ".png", ".xpm"];

    for ext in &exts {
        let path = format!("{}/{}{}", pixmaps, nombre, ext);
        if Path::new(&path).exists() {
            return Some(path);
        }
    }

    None
}

fn leer_tema_iconos() -> String {
    let home = env::var("HOME").unwrap_or_default();
    let gtk_config = format!("{}/.config/gtk-3.0/settings.ini", home);

    if let Ok(content) = fs::read_to_string(&gtk_config) {
        for line in content.lines() {
            let line = line.trim();
            if let Some(valor) = line.strip_prefix("gtk-icon-theme-name=") {
                return valor.trim().to_string();
            }
        }
    }

    if let Ok(output) = std::process::Command::new("gsettings")
        .args(["get", "org.gnome.desktop.interface", "icon-theme"])
        .output()
    {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let tema = stdout.trim().trim_matches('\'');
        if !tema.is_empty() && tema != "org.gnome.desktop.interface" {
            return tema.to_string();
        }
    }

    "hicolor".to_string()
}

fn resolver_ruta_icono(nombre: &str) -> String {
    if nombre.is_empty() {
        return String::new();
    }

    let tema = leer_tema_iconos();
    let home = env::var("HOME").unwrap_or_default();

    let data_dirs = [
        format!("{}/.local/share/icons/{}", home, tema),
        format!("/usr/share/icons/{}", tema),
        format!("{}/.local/share/icons/hicolor", home),
        "/usr/share/icons/hicolor".to_string(),
        // Rutas de exportación de Flatpak
        format!("{}/.local/share/flatpak/exports/share/icons/hicolor", home),
        "/var/lib/flatpak/exports/share/icons/hicolor".to_string(),
    ];

    for base in &data_dirs {
        if let Some(path) = buscar_icono_en_dir(base, nombre) {
            return path;
        }
    }

    let theme_index = format!("/usr/share/icons/{}/index.theme", tema);
    if let Ok(content) = fs::read_to_string(&theme_index) {
        let mut en_icon_theme = false;
        for line in content.lines() {
            let line = line.trim();
            if line == "[Icon Theme]" {
                en_icon_theme = true;
                continue;
            }
            if en_icon_theme && line.starts_with('[') {
                break;
            }
            if en_icon_theme {
                if let Some(inherits) = line.strip_prefix("Inherits=") {
                    for padre in inherits.split(',') {
                        let padre = padre.trim();
                        let dirs = [
                            format!("{}/.local/share/icons/{}", home, padre),
                            format!("/usr/share/icons/{}", padre),
                            // Rutas de herencia de Flatpak
                            format!(
                                "{}/.local/share/flatpak/exports/share/icons/{}",
                                home, padre
                            ),
                            format!("/var/lib/flatpak/exports/share/icons/{}", padre),
                        ];
                        for base in &dirs {
                            if let Some(path) = buscar_icono_en_dir(&base, nombre) {
                                return path;
                            }
                        }
                    }
                }
            }
        }
    }

    if let Some(path) = buscar_en_pixmaps(nombre) {
        return path;
    }

    String::new()
}

fn extraer_icono_desde_contenido(contenido: &str) -> Option<String> {
    for line in contenido.lines() {
        let line = line.trim();
        if let Some(valor) = line.strip_prefix("Icon=") {
            let icono = valor.trim().to_string();
            if icono.starts_with('/') {
                return Some(icono);
            }
            let ruta = resolver_ruta_icono(&icono);
            if !ruta.is_empty() {
                return Some(ruta);
            }
            return Some(icono);
        }
    }
    None
}

fn resolver_desde_desktop(clase: &str) -> String {
    let home = env::var("HOME").unwrap_or_default();
    let dirs = [
        "/usr/share/applications".to_string(),
        "/usr/local/share/applications".to_string(),
        format!("{}/.local/share/applications", home),
        // Rutas de .desktop de Flatpak
        format!("{}/.local/share/flatpak/exports/share/applications", home),
        "/var/lib/flatpak/exports/share/applications".to_string(),
    ];

    // 1. Try exact filename match
    for dir in &dirs {
        for variante in &[clase, &clase.to_lowercase()] {
            let desktop_path = format!("{}/{}.desktop", dir, variante);
            if let Ok(content) = fs::read_to_string(&desktop_path) {
                if let Some(icono) = extraer_icono_desde_contenido(&content) {
                    return icono;
                }
            }
        }
    }

    // 2. Scan all .desktop files and match by StartupWMClass or file name
    let clase_lower = clase.to_lowercase();
    for dir in &dirs {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().and_then(|e| e.to_str()) != Some("desktop") {
                    continue;
                }
                if let Ok(content) = fs::read_to_string(&path) {
                    let tiene_wmclass = content.lines().any(|l| {
                        let t = l.trim().to_lowercase();
                        t.starts_with("startupwmclass=") && t.contains(&clase_lower)
                    });
                    if tiene_wmclass {
                        if let Some(icono) = extraer_icono_desde_contenido(&content) {
                            return icono;
                        }
                    }
                    let fname = path
                        .file_stem()
                        .and_then(|s| s.to_str())
                        .map(|s| s.to_lowercase())
                        .unwrap_or_default();
                    if fname.contains(&clase_lower) || clase_lower.contains(&fname) {
                        if let Some(icono) = extraer_icono_desde_contenido(&content) {
                            return icono;
                        }
                    }
                }
            }
        }
    }

    String::new()
}

pub fn resolver_icono(clase: &str) -> String {
    if clase.is_empty() {
        return String::new();
    }

    let cls = clase.to_lowercase().trim_start_matches('@').to_string();

    // 1. PRIMERO: Buscar en los archivos .desktop
    // Esto garantiza que aplicaciones de Flatpak (com.slack.Slack) o empaquetados no estándar (net.lutris.Lutris)
    // lean el nombre correcto del icono desde su archivo original.
    let icono_desktop = resolver_desde_desktop(&cls);
    if !icono_desktop.is_empty() && icono_desktop.starts_with('/') {
        return icono_desktop;
    }

    // 2. SEGUNDO: Usar la LUT como Fallback para las cosas rebeldes
    let lut: HashMap<&str, &str> = HashMap::from([
        ("firefox", "firefox"),
        ("firefox-esr", "firefox"),
        ("librewolf", "librewolf"),
        ("chromium", "chromium"),
        ("google-chrome", "google-chrome"),
        ("kitty", "kitty"),
        ("alacritty", "alacritty"),
        ("foot", "foot"),
        ("code", "code"),
        ("vscodium", "vscodium"),
        ("codium", "vscodium"),
        ("lutris", "net.lutris.Lutris"),
        ("net.lutris.lutris", "net.lutris.Lutris"),
        ("slack", "com.slack.Slack"),
        ("opencode", "opencode"),
        ("opencode-aidesktop", "opencode"),
        ("code-oss", "com.visualstudio.code.oss"),
        ("codeos", "com.visualstudio.code.oss"),
        ("thunar", "org.xfce.thunar"),
        ("nemo", "nemo"),
        ("dolphin", "org.kde.dolphin"),
        ("discord", "discord"),
        ("spotify", "spotify"),
        ("steam", "steam"),
        ("vlc", "vlc"),
        ("obsidian", "obsidian"),
        ("mailspring", "mailspring"),
    ]);

    // Búsqueda exacta en LUT
    if let Some(&icono) = lut.get(cls.as_str()) {
        let ruta = resolver_ruta_icono(icono);
        if !ruta.is_empty() {
            return ruta;
        }
        return icono.to_string();
    }

    // Búsqueda parcial en LUT
    for (key, icono) in &lut {
        if cls.contains(key) {
            let ruta = resolver_ruta_icono(icono);
            if !ruta.is_empty() {
                return ruta;
            }
            return icono.to_string();
        }
    }

    // 3. TERCERO: Fallback directo, por si el nombre de la clase ES el nombre del icono
    let ruta_directa = resolver_ruta_icono(&cls);
    if !ruta_directa.is_empty() {
        return ruta_directa;
    }

    // Devolver el string que sacamos del desktop, aunque QML falle al renderizarlo, activará el FontAwesome de respaldo
    icono_desktop
}
