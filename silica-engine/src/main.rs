use std::sync::{Arc, Mutex};
use std::env;

mod state;
mod hyprland;
mod server;
mod icons;
mod cmd;
mod wifi;
mod hardware;

fn main() {
    let args: Vec<String> = env::args().collect();

    // Si pasamos argumentos (ej: ./silica-engine set-brillo 50)
    // actuamos como cliente CLI y salimos.
    if args.len() > 1 {
        cmd::enviar_comando(&args[1..]);
        return;
    }

    // Si no hay argumentos, levantamos el DAEMON completo
    let estado_global = Arc::new(Mutex::new(state::SilicaState::new()));

    // 1. Lector de Hyprland
    hyprland::iniciar_escucha_eventos(Arc::clone(&estado_global));

    // 2. Servidor de Comandos de Entrada (El que acabamos de crear)
    cmd::iniciar_listener_comandos();

    // 3. Servidor de Datos de Salida (Hacia QML)
    let socket_path = "/tmp/silica.sock";
    server::iniciar_servidor_ipc(socket_path, estado_global);
}