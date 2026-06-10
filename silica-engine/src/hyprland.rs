use std::collections::{HashMap, HashSet};
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use std::env;
use std::process::Command;
use crate::icons;
use crate::state::{SilicaState, VentanaInfo};

fn parsear_config(path: &str, ids_por_monitor: &mut HashMap<String, Vec<i32>>, visitados: &mut HashSet<String>) {
    if !visitados.insert(path.to_string()) {
        return;
    }
    if let Ok(content) = std::fs::read_to_string(path) {
        for line in content.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }
            if let Some(rest) = trimmed.strip_prefix("source =") {
                let inc = rest.trim().trim_matches('"');
                let inc_path = if inc.starts_with('/') {
                    inc.to_string()
                } else if let Ok(home) = env::var("HOME") {
                    inc.replacen("~", &home, 1)
                } else {
                    continue;
                };
                parsear_config(&inc_path, ids_por_monitor, visitados);
            }
            if let Some(rest) = trimmed.strip_prefix("workspace =") {
                let parts: Vec<&str> = rest.split(',').collect();
                let mut monitor = String::new();
                let mut ws_id: Option<i32> = None;
                for part in &parts {
                    let p = part.trim();
                    if let Some(mon) = p.strip_prefix("monitor:") {
                        monitor = mon.trim().to_string();
                    } else if ws_id.is_none() {
                        if let Ok(id) = p.parse::<i32>() {
                            ws_id = Some(id);
                        }
                    }
                }
                if let Some(id) = ws_id {
                    if !monitor.is_empty() {
                        let ids = ids_por_monitor.entry(monitor).or_default();
                        if !ids.contains(&id) {
                            ids.push(id);
                        }
                    }
                }
            }
        }
    }
}

pub fn consultar_workspaces_activos() -> (String, HashMap<String, i32>) {
    let mut monitor_enfocado = String::new();
    let mut workspaces = HashMap::new();
    if let Ok(output) = Command::new("hyprctl").args(&["monitors", "-j"]).output() {
        if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
            if let Some(monitores) = json.as_array() {
                for mon in monitores {
                    let nombre = mon["name"].as_str().unwrap_or("").to_string();
                    if nombre.is_empty() { continue; }
                    if monitor_enfocado.is_empty() || mon["focused"].as_bool().unwrap_or(false) {
                        monitor_enfocado = nombre.clone();
                    }
                    let ws_id = mon["activeWorkspace"]["id"].as_i64().unwrap_or(1) as i32;
                    workspaces.insert(nombre, ws_id);
                }
            }
        }
    }
    (monitor_enfocado, workspaces)
}

pub fn consultar_workspaces_por_monitor() -> HashMap<String, Vec<i32>> {
    let mut ids_por_monitor = HashMap::new();
    let home = env::var("HOME").unwrap_or_default();
    let config_path = format!("{}/.config/hypr/hyprland.conf", home);
    let mut visitados = HashSet::new();
    parsear_config(&config_path, &mut ids_por_monitor, &mut visitados);
    for ids in ids_por_monitor.values_mut() {
        ids.sort();
    }
    ids_por_monitor
}

/// Consulta Hyprland mediante CLI para obtener la fuente de verdad absoluta
/// sobre qué ventanas están abiertas y en qué workspace están.
pub fn sincronizar_monitores(estado: &Arc<Mutex<SilicaState>>) {
    if let Ok(output) = Command::new("hyprctl").args(&["monitors", "-j"]).output() {
        if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
            if let Some(monitores) = json.as_array() {
                let mut s = estado.lock().unwrap();
                for mon in monitores {
                    let nombre = mon["name"].as_str().unwrap_or("").to_string();
                    if nombre.is_empty() { continue; }
                    if s.monitor_enfocado.is_empty() || mon["focused"].as_bool().unwrap_or(false) {
                        s.monitor_enfocado = nombre.clone();
                    }
                    let ws_id = mon["activeWorkspace"]["id"].as_i64().unwrap_or(1) as i32;
                    s.workspaces.insert(nombre, ws_id);
                }
            }
        }
    }
}

pub fn sincronizar_todo(estado: &Arc<Mutex<SilicaState>>) {
    sincronizar_monitores(estado);
    sincronizar_ventanas(estado);
}

pub fn sincronizar_ventanas(estado: &Arc<Mutex<SilicaState>>) {
    if let Ok(output) = Command::new("hyprctl").args(&["clients", "-j"]).output() {
        if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
            if let Some(clients) = json.as_array() {
                let mut ws_map: HashMap<i32, VentanaInfo> = HashMap::new();
                
                let mut clients_sorted = clients.to_vec();
                // Ordenar por focusHistoryID (0 es el más reciente). 
                // Así nos aseguramos de que el icono del workspace sea siempre el de la última ventana activa.
                clients_sorted.sort_by_key(|c| c["focusHistoryID"].as_i64().unwrap_or(999));

                for client in clients_sorted {
                    let ws_id = client["workspace"]["id"].as_i64().unwrap_or(-1) as i32;
                    
                    // Solo registrar si el workspace es válido y si aún no hemos registrado una ventana más reciente para él
                    if ws_id > 0 && !ws_map.contains_key(&ws_id) {
                        let clase = client["class"].as_str().unwrap_or("").to_string();
                        let titulo = client["title"].as_str().unwrap_or("").to_string();
                        let icono = icons::resolver_icono(&clase);
                        ws_map.insert(ws_id, VentanaInfo { clase, titulo, icono });
                    }
                }

                let mut s = estado.lock().unwrap();
                s.ventanas_por_workspace = ws_map;
            }
        }
    }
}

fn inicializar_estado(estado: &Arc<Mutex<SilicaState>>) {
    let inicial_workspaces = consultar_workspaces_por_monitor();
    for intento in 0..15 {
        let (mon_enfocado, ws_activos) = consultar_workspaces_activos();
        sincronizar_ventanas(estado);
        {
            let mut s = estado.lock().unwrap();
            s.workspaces_por_monitor = inicial_workspaces.clone();
            if !mon_enfocado.is_empty() {
                s.monitor_enfocado = mon_enfocado;
            }
            for (monitor, ws_ids) in &inicial_workspaces {
                if let Some(&ws) = ws_activos.get(monitor) {
                    s.workspaces.insert(monitor.clone(), ws);
                } else if !s.workspaces.contains_key(monitor) {
                    if let Some(&primer_id) = ws_ids.first() {
                        s.workspaces.insert(monitor.clone(), primer_id);
                    }
                }
            }
            if !s.ventanas_por_workspace.is_empty() {
                return;
            }
        }
        if intento < 14 {
            thread::sleep(Duration::from_millis(200));
        }
    }
}

pub fn iniciar_escucha_eventos(estado: Arc<Mutex<SilicaState>>) {
    inicializar_estado(&estado);

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

                        if line_str.starts_with("focusedmonv2>>")
                               || line_str.starts_with("workspacev2>>")
                               || line_str.starts_with("openwindow>>")
                               || line_str.starts_with("closewindow>>")
                               || line_str.starts_with("movewindow>>")
                               || line_str.starts_with("activewindow>>") {
                            sincronizar_todo(&estado);
                        }

                        if line_str.starts_with("activewindow>>") {
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
                        }
                    }
                }
            }
        }
    });
}