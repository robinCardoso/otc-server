//! Tibia login protocol (TFS 8.60).

use super::network_message::NetworkMessage;

pub const CLIENT_VERSION: u16 = 860;

pub struct LoginRequest {
    pub account: String,
    pub password: String,
}

impl LoginRequest {
    pub fn encode(&self) -> Vec<u8> {
        let mut msg = NetworkMessage::new();
        msg.write_u16(CLIENT_VERSION);
        msg.as_bytes().to_vec()
    }
}
