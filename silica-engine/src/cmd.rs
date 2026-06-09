use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::process::Command;
use std::thread;

const CMD_SOCKET: &str = "/tmp/silica_cmd.sock";

// ─── PARTE 1: EL CLIENTE CLI ───
// Esto se ejecuta cuando llamas al binario desde la terminal o QML
pub fn enviar_comando(args: &[String]) {
    if let Ok(mut stream) = UnixStream::connect(CMD_SOCKET) {
        let cmd = args.join(" ");
        let _ = writeln!(stream, "{}", cmd);
    } else {
        println!("❌ El daemon de Silica no está corriendo.");
    }
}

// ─── PARTE 2: EL SERVIDOR DE COMANDOS (DAEMON) ───
// Esto corre en un hilo de fondo escuchando órdenes
pub fn iniciar_listener_comandos() {
    let _ = std::fs::remove_file(CMD_SOCKET);
    let listener = UnixListener::bind(CMD_SOCKET).expect("No se pudo crear el socket de comandos");
    
    println!("⚔️  Silica Command Listener activo en {} ...", CMD_SOCKET);

    thread::spawn(move || {
        for stream in listener.incoming().flatten() {
            let reader = BufReader::new(stream);
            for line in reader.lines().flatten() {
                procesar_comando(&line);
            }
        }
    });
}

// ─── PARTE 3: EL CEREBRO EJECUTOR ───
fn procesar_comando(cmd: &str) {
    let parts: Vec<&str> = cmd.split_whitespace().collect();
    if parts.is_empty() { return; }

    match parts[0] {
        "set-brillo" => {
            if let Some(val) = parts.get(1) {
                // Llama a brightnessctl de CachyOS
                let _ = Command::new("brightnessctl")
                    .args(["set", &format!("{}%", val)])
                    .output();
            }
        },
        "set-audio" => {
            if let Some(val) = parts.get(1) {
                // Llama a wpctl (Pipewire)
                let _ = Command::new("wpctl")
                    .args(["set-volume", "@DEFAULT_AUDIO_SINK@", val])
                    .output();
            }
        },
        _ => println!("⚠️ Comando desconocido: {}", cmd),
    }
}