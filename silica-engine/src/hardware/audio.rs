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
    let mut in_entry = false;

    for line in output.lines() {
        if line.starts_with("Sink #") || line.starts_with("Source #") {
            if in_entry && !current_name.is_empty() && !_es_virtual(&current_name, &current_desc) {
                devices.push(AudioDevice {
                    nombre: current_name.clone(),
                    descripcion: current_desc.clone(),
                    volumen: 1.0,
                    mute: false,
                    predeterminado: false,
                    node_id: current_node_id,
                });
            }
            current_name.clear();
            current_desc.clear();
            let rest = if line.starts_with("Sink #") { &line[6..] } else if line.starts_with("Source #") { &line[8..] } else { "" };
            current_node_id = rest.split_whitespace().next().and_then(|s| s.parse().ok()).unwrap_or(0);
            in_entry = true;
        } else if in_entry {
            if let Some(val) = line.trim().strip_prefix("Name:") {
                current_name = val.trim().to_string();
            } else if let Some(val) = line.trim().strip_prefix("Description:") {
                current_desc = val.trim().to_string();
            }
        }
    }

    if in_entry && !current_name.is_empty() && !_es_virtual(&current_name, &current_desc) {
        devices.push(AudioDevice {
            nombre: current_name.clone(),
            descripcion: current_desc.clone(),
            volumen: 1.0,
            mute: false,
            predeterminado: false,
            node_id: current_node_id,
        });
    }

    devices
}

fn _set_volumen_actual_mute(devices: &mut Vec<AudioDevice>) {
    for dev in devices {
        let output = Command::new("wpctl")
            .args(["get-volume", &dev.node_id.to_string()])
            .output()
            .ok()
            .and_then(|o| String::from_utf8(o.stdout).ok())
            .unwrap_or_default();
        let parts: Vec<&str> = output.split_whitespace().collect();
        if let Some(vol_str) = parts.get(1) {
            dev.volumen = vol_str.parse().unwrap_or(1.0);
        }
        dev.mute = output.contains("MUTED");
    }
}

pub fn leer_audio() -> (Vec<AudioDevice>, Vec<AudioDevice>, f64, bool) {
    let default_sink = _default_device_name("sink");
    let default_source = _default_device_name("source");

    let mut salidas = _parse_pactl_list("sinks");
    let mut entradas = _parse_pactl_list("sources");
    _set_volumen_actual_mute(&mut salidas);

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
