use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;
use std::sync::{Arc, Mutex};
use std::thread;
use std::env;
use crate::icons;
use crate::state::SilicaState;

pub fn iniciar_escucha_eventos(estado: Arc<Mutex<SilicaState>>) {
    thread::spawn(move || {
        if let (Ok(xdg), Ok(instance)) = (
            env::var("XDG_RUNTIME_DIR"),
            env::var("HYPRLAND_INSTANCE_SIGNATURE"),
        ) {
            let hypr_socket = format!("{}/hypr/{}/.socket2.sock", xdg, instance);

            if let Ok(stream) = UnixStream::connect(&hypr_socket) {
                let reader = BufReader::new(stream);

                for line in reader.lines() {
                    if let Ok(line_str) = line {

                        if line_str.starts_with("focusedmonv2>>") {
                            if let Some(data) = line_str.strip_prefix("focusedmonv2>>") {
                                let parts: Vec<&str> = data.splitn(2, ',').collect();
                                if parts.len() == 2 {
                                    let monitor = parts[0].to_string();
                                    let mut s = estado.lock().unwrap();
                                    s.monitor_enfocado = monitor.clone();
                                    if let Ok(ws_id) = parts[1].trim().parse::<i32>() {
                                        s.workspaces.insert(monitor, ws_id);
                                    }
                                }
                            }

                        } else if line_str.starts_with("workspacev2>>") {
                            if let Some(data) = line_str.strip_prefix("workspacev2>>") {
                                if let Some(id_str) = data.split(',').next() {
                                    if let Ok(ws_id) = id_str.trim().parse::<i32>() {
                                        let mut s = estado.lock().unwrap();
                                        let monitor = s.monitor_enfocado.clone();
                                        if !monitor.is_empty() {
                                            s.workspaces.insert(monitor, ws_id);
                                        }
                                    }
                                }
                            }

                        } else if line_str.starts_with("activewindow>>") {
                            if let Some(data) = line_str.strip_prefix("activewindow>>") {
                                let parts: Vec<&str> = data.splitn(2, ',').collect();
                                let clase  = parts.get(0).unwrap_or(&"").trim().to_string();
                                let titulo = parts.get(1).unwrap_or(&"").trim().to_string();
                                let icono = icons::resolver_icono(&clase);
                                let mut s = estado.lock().unwrap();
                                s.ventana_clase  = clase;
                                s.ventana_titulo = titulo;
                                s.ventana_icono  = icono;
                            }

                        } else if line_str.starts_with("closewindow>>") {
                            let mut s = estado.lock().unwrap();
                            s.ventana_clase  = String::new();
                            s.ventana_titulo = String::new();
                            s.ventana_icono  = String::new();
                        }
                    }
                }
            }
        }
    });
}
