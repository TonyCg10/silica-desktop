use std::fs;
use std::io::Write;
use std::os::unix::net::UnixListener;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;
use chrono::Local;
use crate::state::{SilicaEvent, SilicaState};
use crate::hardware;
use crate::wifi;
use crate::bluetooth;
use crate::hyprland;

pub fn iniciar_servidor_ipc(socket_path: &str, estado: Arc<Mutex<SilicaState>>) {
    let _ = fs::remove_file(socket_path);
    let listener = UnixListener::bind(socket_path).expect("No se pudo crear el socket");
    println!("💎 Silica Engine inicializado en {} ...", socket_path);

    {
        let estado_wifi = Arc::clone(&estado);
        thread::spawn(move || {
            loop {
                let redes = wifi::escanear_redes();
                if let Ok(mut s) = estado_wifi.lock() {
                    s.redes = redes;
                    s.redes_gen += 1;
                }
                thread::sleep(Duration::from_secs(10));
            }
        });
    }

    {
        let estado_brillo = Arc::clone(&estado);
        thread::spawn(move || {
            loop {
                let brillo = hardware::leer_brillo();
                if let Ok(mut s) = estado_brillo.lock() {
                    s.brillo = brillo;
                    s.brillo_gen += 1;
                }
                thread::sleep(Duration::from_secs(60));
            }
        });
    }

    {
        let estado_audio = Arc::clone(&estado);
        thread::spawn(move || {
            loop {
                let (salidas, entradas, volumen_actual, volumen_mute) = hardware::leer_audio();
                if let Ok(mut s) = estado_audio.lock() {
                    s.audio_salidas = salidas;
                    s.audio_entradas = entradas;
                    s.volumen_actual = volumen_actual;
                    s.volumen_mute = volumen_mute;
                    s.audio_gen += 1;
                }
                thread::sleep(Duration::from_millis(500));
            }
        });
    }

    {
        let estado_bateria = Arc::clone(&estado);
        thread::spawn(move || {
            loop {
                let bateria = hardware::leer_bateria();
                if let Ok(mut s) = estado_bateria.lock() {
                    s.bateria = bateria;
                    s.bateria_gen += 1;
                }
                thread::sleep(Duration::from_secs(10));
            }
        });
    }

    {
        let estado_bt = Arc::clone(&estado);
        thread::spawn(move || {
            loop {
                let (powered, devices) = bluetooth::leer_bluetooth();
                if let Ok(mut s) = estado_bt.lock() {
                    s.bt_power_on = powered;
                    s.bluetooth_devices = devices;
                    s.bluetooth_gen += 1;
                }
                thread::sleep(Duration::from_secs(20));
            }
        });
    }

    {
        let estado_ws = Arc::clone(&estado);
        thread::spawn(move || {
            loop {
                let ids = hyprland::consultar_workspaces_por_monitor();
                if let Ok(mut s) = estado_ws.lock() {
                    s.workspaces_por_monitor = ids;
                }
                thread::sleep(Duration::from_secs(5));
            }
        });
    }

    for stream in listener.incoming() {
        match stream {
            Ok(mut stream) => {
                println!("📺 Silica Bar conectada.");
                let estado_client = Arc::clone(&estado);

                thread::spawn(move || {
                    let mut ult_redes_gen: u64 = 0;
                    let mut ult_brillo_gen: u64 = 0;
                    let mut ult_audio_gen: u64 = 0;
                    let mut ult_bluetooth_gen: u64 = 0;

                    loop {
                        let (
                            workspaces_por_monitor,
                            workspaces_snapshot,
                            ventanas_por_workspace,
                            titulo,
                            clase,
                            icono,
                            redes,
                            redes_gen,
                            brillo,
                            brillo_gen,
                            audio_salidas,
                            audio_entradas,
                            volumen_actual,
                            volumen_mute,
                            audio_gen,
                            bateria,
                            bluetooth_devices,
                            bluetooth_gen,
                            bt_power_on,
                        ) = {
                            let s = estado_client.lock().unwrap();
                            (
                                s.workspaces_por_monitor.clone(),
                                s.workspaces.clone(),
                                s.ventanas_por_workspace.clone(),
                                s.ventana_titulo.clone(),
                                s.ventana_clase.clone(),
                                s.ventana_icono.clone(),
                                s.redes.clone(),
                                s.redes_gen,
                                s.brillo.clone(),
                                s.brillo_gen,
                                s.audio_salidas.clone(),
                                s.audio_entradas.clone(),
                                s.volumen_actual,
                                s.volumen_mute,
                                s.audio_gen,
                                s.bateria,
                                s.bluetooth_devices.clone(),
                                s.bluetooth_gen,
                                s.bt_power_on,
                            )
                        };

                        let datos = SilicaEvent {
                            hora: Local::now().format("%H:%M:%S").to_string(),
                            bateria,
                            workspaces_por_monitor,
                            workspaces: workspaces_snapshot,
                            ventanas_por_workspace,
                            ventana_titulo: titulo,
                            ventana_clase: clase,
                            ventana_icono: icono,
                            redes: if redes_gen != ult_redes_gen { Some(redes) } else { None },
                            brillo: if brillo_gen != ult_brillo_gen { Some(brillo) } else { None },
                            audio_salidas: if audio_gen != ult_audio_gen { Some(audio_salidas) } else { None },
                            audio_entradas: if audio_gen != ult_audio_gen { Some(audio_entradas) } else { None },
                            volumen_actual,
                            volumen_mute,
                            bluetooth_devices: if bluetooth_gen != ult_bluetooth_gen { Some(bluetooth_devices) } else { None },
                            bt_power_on,
                        };

                        ult_redes_gen = redes_gen;
                        ult_brillo_gen = brillo_gen;
                        ult_audio_gen = audio_gen;
                        ult_bluetooth_gen = bluetooth_gen;

                        if let Ok(json_string) = serde_json::to_string(&datos) {
                            if writeln!(stream, "{}", json_string).is_err() {
                                println!("❌ Conexión cerrada con el frontend.");
                                break;
                            }
                        }
                        thread::sleep(Duration::from_millis(100));
                    }
                });
            }
            Err(err) => println!("Error de conexión entrante: {}", err),
        }
    }
}
