use serde::Serialize;
use std::collections::HashMap;

#[derive(Serialize, Clone, Default)]
pub struct RedInfo {
    pub ssid: String,
    pub intensidad: u8,
    pub conectada: bool,
    pub protegida: bool,
}

#[derive(Serialize, Clone, Default)]
pub struct BrilloInfo {
    pub nombre: String,
    pub actual: u32,
    pub maximo: u32,
    pub display_num: u32,
}

#[derive(Serialize, Clone)]
pub struct AudioDevice {
    pub nombre: String,
    pub descripcion: String,
    pub volumen: f64,
    pub mute: bool,
    pub predeterminado: bool,
    pub node_id: u32,
}

#[derive(Serialize, Clone, Default)]
pub struct BtDevice {
    pub mac: String,
    pub name: String,
    pub connected: bool,
    pub paired: bool,
}

#[derive(Serialize)]
pub struct SilicaEvent {
    pub hora: String,
    pub bateria: i32,
    pub workspaces: HashMap<String, i32>,
    pub ventana_titulo: String,
    pub ventana_clase: String,
    pub ventana_icono: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub redes: Option<Vec<RedInfo>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brillo: Option<Vec<BrilloInfo>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub audio_salidas: Option<Vec<AudioDevice>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub audio_entradas: Option<Vec<AudioDevice>>,
    pub volumen_actual: f64,
    pub volumen_mute: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bluetooth_devices: Option<Vec<BtDevice>>,
    pub bt_power_on: bool,
}

pub struct SilicaState {
    pub workspaces: HashMap<String, i32>,
    pub monitor_enfocado: String,
    pub ventana_titulo: String,
    pub ventana_clase: String,
    pub ventana_icono: String,
    pub redes: Vec<RedInfo>,
    pub redes_gen: u64,
    pub brillo: Vec<BrilloInfo>,
    pub brillo_gen: u64,
    pub audio_salidas: Vec<AudioDevice>,
    pub audio_entradas: Vec<AudioDevice>,
    pub volumen_actual: f64,
    pub volumen_mute: bool,
    pub audio_gen: u64,
    pub bateria: i32,
    pub bateria_gen: u64,
    pub bluetooth_devices: Vec<BtDevice>,
    pub bt_power_on: bool,
    pub bluetooth_gen: u64,
}

impl SilicaState {
    pub fn new() -> Self {
        Self {
            workspaces: HashMap::new(),
            monitor_enfocado: String::new(),
            ventana_titulo: String::new(),
            ventana_clase: String::new(),
            ventana_icono: String::new(),
            redes: Vec::new(),
            redes_gen: 0,
            brillo: Vec::new(),
            brillo_gen: 0,
            audio_salidas: Vec::new(),
            audio_entradas: Vec::new(),
            volumen_actual: 0.0,
            volumen_mute: false,
            audio_gen: 0,
            bateria: 100,
            bateria_gen: 0,
            bluetooth_devices: Vec::new(),
            bt_power_on: false,
            bluetooth_gen: 0,
        }
    }
}
