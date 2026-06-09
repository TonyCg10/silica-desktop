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
                thread::sleep(Duration::from_secs(5));
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
                thread::sleep(Duration::from_secs(2));
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

                    loop {
                        let (workspaces_snapshot, titulo, clase, icono, redes, redes_gen, brillo, brillo_gen) = {
                            let s = estado_client.lock().unwrap();
                            (s.workspaces.clone(), s.ventana_titulo.clone(), s.ventana_clase.clone(), s.ventana_icono.clone(), s.redes.clone(), s.redes_gen, s.brillo.clone(), s.brillo_gen)
                        };

                        let (audio_salidas, audio_entradas, volumen_actual, volumen_mute) = hardware::leer_audio();

                        let datos = SilicaEvent {
                            hora: Local::now().format("%H:%M:%S").to_string(),
                            bateria: hardware::leer_bateria(),
                            workspaces: workspaces_snapshot,
                            ventana_titulo: titulo,
                            ventana_clase: clase,
                            ventana_icono: icono,
                            redes: if redes_gen != ult_redes_gen { redes } else { Vec::new() },
                            brillo: if brillo_gen != ult_brillo_gen { brillo } else { Vec::new() },
                            audio_salidas,
                            audio_entradas,
                            volumen_actual,
                            volumen_mute,
                        };

                        ult_redes_gen = redes_gen;
                        ult_brillo_gen = brillo_gen;

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
