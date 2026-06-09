use std::process::Command;
use crate::state::RedInfo;

pub fn escanear_redes() -> Vec<RedInfo> {
    let mut redes: Vec<RedInfo> = Vec::new();
    if let Some(ssid) = _red_conectada() {
        redes.push(RedInfo {
            ssid,
            intensidad: 100,
            conectada: true,
            protegida: false,
        });
    }
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
