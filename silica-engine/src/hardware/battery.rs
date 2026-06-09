use std::fs;

pub fn leer_bateria() -> i32 {
    let battery_paths = [
        "/sys/class/power_supply/BAT0/capacity",
        "/sys/class/power_supply/BAT1/capacity",
    ];

    for path in &battery_paths {
        if let Ok(content) = fs::read_to_string(path) {
            if let Ok(pct) = content.trim().parse::<i32>() {
                return pct.clamp(0, 100);
            }
        }
    }
    100
}
