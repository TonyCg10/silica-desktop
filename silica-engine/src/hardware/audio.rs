use std::process::Command;
use crate::state::AudioDevice;

fn _default_device_name(kind: &str) -> String {
    let output = Command::new("pactl")
        .args(["info"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default();

    let key = match kind {
        "sink" => "Default Sink:",
        "source" => "Default Source:",
        _ => return String::new(),
    };

    for line in output.lines() {
        if let Some(val) = line.strip_prefix(key) {
            return val.trim().to_string();
        }
    }
    String::new()
}

fn _es_virtual(nombre: &str, descripcion: &str) -> bool {
    let n = nombre.to_lowercase();
    let d = descripcion.to_lowercase();
    n.contains(".monitor")
        || n.contains("easyeffects")
        || d.contains("monitor of")
        || d.contains("easy effects")
}

fn _parse_pactl_list(kind: &str) -> Vec<AudioDevice> {
    let mut devices: Vec<AudioDevice> = Vec::new();

    let output = Command::new("pactl")
        .args(["list", kind])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default();

    let mut current_name = String::new();
    let mut current_desc = String::new();
    let mut current_node_id: u32 = 0;
    let mut current_vol: f64 = 1.0;
    let mut current_mute: bool = false;
    let mut in_entry = false;

    for line in output.lines() {
        if line.starts_with("Sink #") || line.starts_with("Source #") {
            if in_entry && !current_name.is_empty() && !_es_virtual(&current_name, &current_desc) {
                devices.push(AudioDevice {
                    nombre: current_name.clone(),
                    descripcion: current_desc.clone(),
                    volumen: current_vol,
                    mute: current_mute,
                    predeterminado: false,
                    node_id: current_node_id,
                });
            }
            current_name.clear();
            current_desc.clear();
            current_vol = 1.0;
            current_mute = false;
            let rest = if line.starts_with("Sink #") { &line[6..] } else if line.starts_with("Source #") { &line[8..] } else { "" };
            current_node_id = rest.split_whitespace().next().and_then(|s| s.parse().ok()).unwrap_or(0);
            in_entry = true;
        } else if in_entry {
            let trimmed = line.trim();
            if let Some(val) = trimmed.strip_prefix("Name:") {
                current_name = val.trim().to_string();
            } else if let Some(val) = trimmed.strip_prefix("Description:") {
                current_desc = val.trim().to_string();
            } else if let Some(val) = trimmed.strip_prefix("Mute:") {
                current_mute = val.trim() == "yes";
            } else if let Some(val) = trimmed.strip_prefix("Volume:") {
                if let Some(pct_pos) = val.find('%') {
                    let mut start = pct_pos;
                    while start > 0 {
                        let prev_char = val.chars().nth(start - 1).unwrap();
                        if prev_char.is_ascii_digit() || prev_char == ' ' {
                            start -= 1;
                        } else {
                            break;
                        }
                    }
                    let num_str = val[start..pct_pos].trim();
                    if let Ok(pct) = num_str.parse::<u32>() {
                        current_vol = (pct as f64) / 100.0;
                    }
                }
            }
        }
    }

    if in_entry && !current_name.is_empty() && !_es_virtual(&current_name, &current_desc) {
        devices.push(AudioDevice {
            nombre: current_name.clone(),
            descripcion: current_desc.clone(),
            volumen: current_vol,
            mute: current_mute,
            predeterminado: false,
            node_id: current_node_id,
        });
    }

    devices
}

pub fn leer_audio() -> (Vec<AudioDevice>, Vec<AudioDevice>, f64, bool) {
    let default_sink = _default_device_name("sink");
    let default_source = _default_device_name("source");

    let mut salidas = _parse_pactl_list("sinks");
    let mut entradas = _parse_pactl_list("sources");

    for dev in &mut salidas {
        dev.predeterminado = dev.nombre == default_sink;
    }
    for dev in &mut entradas {
        dev.predeterminado = dev.nombre == default_source;
    }
    salidas.sort_by(|a, _| if a.predeterminado { std::cmp::Ordering::Less } else { std::cmp::Ordering::Greater });
    entradas.sort_by(|a, _| if a.predeterminado { std::cmp::Ordering::Less } else { std::cmp::Ordering::Greater });

    let volumen_actual = salidas.iter().find(|d| d.predeterminado).map(|d| d.volumen).unwrap_or(1.0);
    let volumen_mute = salidas.iter().find(|d| d.predeterminado).map(|d| d.mute).unwrap_or(false);

    (salidas, entradas, volumen_actual, volumen_mute)
}
