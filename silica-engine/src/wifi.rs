use std::process::Command;
use crate::state::RedInfo;

pub fn escanear_redes() -> Vec<RedInfo> {
    let conectada = _red_conectada();

    let _ = Command::new("nmcli")
        .args(["device", "wifi", "rescan"])
        .output();

    std::thread::sleep(std::time::Duration::from_millis(300));

    let mut redes: Vec<RedInfo> = Vec::new();

    if let Ok(output) = Command::new("nmcli")
        .args(["-t", "-f", "SSID,SIGNAL,SECURITY", "device", "wifi", "list"])
        .output()
    {
        if let Ok(stdout) = String::from_utf8(output.stdout) {
            for line in stdout.lines() {
                let parts: Vec<&str> = line.splitn(3, ':').collect();
                if parts.is_empty() { continue; }
                let ssid = parts[0].trim().to_string();
                if ssid.is_empty() || ssid == "--" { continue; }
                let intensidad = parts.get(1).and_then(|s| s.parse().ok()).unwrap_or(0);
                let protegida = parts.get(2).map_or(false, |s| !s.is_empty() && s.trim() != "--");
                let is_connected = conectada.as_deref() == Some(&ssid);
                redes.push(RedInfo { ssid, intensidad, protegida, conectada: is_connected });
            }
        }
    }

    redes.sort_by(|a, b| b.intensidad.cmp(&a.intensidad));
    redes.truncate(30);
    redes
}

fn _red_conectada() -> Option<String> {
    if let Ok(output) = Command::new("nmcli")
        .args(["-t", "-f", "NAME,DEVICE,TYPE", "connection", "show", "--active"])
        .output()
    {
        if let Ok(stdout) = String::from_utf8(output.stdout) {
            for line in stdout.lines() {
                let parts: Vec<&str> = line.splitn(3, ':').collect();
                if parts.len() >= 3 && parts[2] == "wifi" {
                    return Some(parts[0].trim().to_string());
                }
            }
        }
    }
    None
}
