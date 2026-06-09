use std::process::Command;
use crate::state::BrilloInfo;

fn leer_brillo_sysfs() -> Vec<BrilloInfo> {
    let mut brillos = Vec::new();
    if let Ok(entries) = std::fs::read_dir("/sys/class/backlight") {
        for entry in entries.flatten() {
            let dir = entry.path();
            let nombre = entry.file_name().to_string_lossy().to_string();
            let actual = std::fs::read_to_string(dir.join("actual_brightness"))
                .or_else(|_| std::fs::read_to_string(dir.join("brightness")))
                .ok()
                .and_then(|s| s.trim().parse().ok())
                .unwrap_or(0);
            let maximo = std::fs::read_to_string(dir.join("max_brightness"))
                .ok()
                .and_then(|s| s.trim().parse().ok())
                .unwrap_or(1);
            brillos.push(BrilloInfo { nombre, actual, maximo, display_num: 0 });
        }
    }
    brillos
}

fn leer_brillo_ddcutil() -> Vec<BrilloInfo> {
    let mut brillos = Vec::new();
    let output = match Command::new("ddcutil")
        .args(["detect", "--brief"])
        .output()
    {
        Ok(o) if o.status.success() => o,
        _ => return brillos,
    };
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut display_num: Option<u32> = None;
    let mut connector = String::new();
    for line in stdout.lines() {
        let line = line.trim();
        if let Some(rest) = line.strip_prefix("Display ") {
            if let Some(num_str) = rest.split_whitespace().next() {
                display_num = num_str.parse().ok();
            }
        } else if let Some(rest) = line.strip_prefix("DRM connector:") {
            connector = rest.trim().to_string();
        } else if line.starts_with("Monitor:") && display_num.is_some() {
            let num = display_num.take().unwrap();
            let out = Command::new("ddcutil")
                .args(["getvcp", "10", "--brief", "--display", &num.to_string()])
                .output();
            if let Ok(o) = out {
                let s = String::from_utf8_lossy(&o.stdout);
                let parts: Vec<&str> = s.split_whitespace().collect();
                if parts.len() >= 5 {
                    if let (Ok(actual), Ok(maximo)) = (parts[3].parse(), parts[4].parse()) {
                        let short_name = connector.splitn(2, '-').nth(1).unwrap_or(&connector);
                        brillos.push(BrilloInfo {
                            nombre: short_name.to_string(),
                            display_num: num,
                            actual,
                            maximo,
                        });
                    }
                }
            }
        }
    }
    brillos
}

pub fn leer_brillo() -> Vec<BrilloInfo> {
    let mut brillos = leer_brillo_sysfs();
    if brillos.is_empty() {
        brillos = leer_brillo_ddcutil();
    }
    brillos
}
