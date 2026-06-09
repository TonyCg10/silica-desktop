use std::process::Command;
use crate::state::BtDevice;

pub fn leer_bluetooth() -> (bool, Vec<BtDevice>) {
    // 1. Check if powered
    let mut powered = false;
    if let Ok(output) = Command::new("bluetoothctl")
        .args(["show"])
        .output()
    {
        if let Ok(stdout) = String::from_utf8(output.stdout) {
            for line in stdout.lines() {
                if line.trim().starts_with("Powered: yes") {
                    powered = true;
                    break;
                }
            }
        }
    }

    let mut devices = Vec::new();
    if !powered {
        return (false, devices);
    }

    // 2. Get devices
    if let Ok(output) = Command::new("bluetoothctl")
        .args(["devices"])
        .output()
    {
        if let Ok(stdout) = String::from_utf8(output.stdout) {
            for line in stdout.lines() {
                // Format: Device 5C:D3:3D:49:38:BD Buds4 Pro de Antonio
                let parts: Vec<&str> = line.splitn(3, ' ').collect();
                if parts.len() >= 3 && parts[0] == "Device" {
                    let mac = parts[1].to_string();
                    let name = parts[2].to_string();
                    let mut connected = false;
                    let mut paired = false;

                    // Query info
                    if let Ok(info_out) = Command::new("bluetoothctl")
                        .args(["info", &mac])
                        .output()
                    {
                        if let Ok(info_str) = String::from_utf8(info_out.stdout) {
                            for info_line in info_str.lines() {
                                let trimmed = info_line.trim();
                                if trimmed.starts_with("Paired: yes") {
                                    paired = true;
                                } else if trimmed.starts_with("Connected: yes") {
                                    connected = true;
                                }
                            }
                        }
                    }

                    devices.push(BtDevice {
                        mac,
                        name,
                        connected,
                        paired,
                    });
                }
            }
        }
    }

    (powered, devices)
}
