//! Tibia game protocol (TFS 8.60).

use super::network_message::NetworkMessage;

pub struct GameMessage {
    pub opcode: u8,
    pub payload: Vec<u8>,
}

impl GameMessage {
    pub fn encode(&self) -> Vec<u8> {
        let mut msg = NetworkMessage::new();
        msg.write_u8(self.opcode);
        msg.as_bytes()
            .iter()
            .chain(self.payload.iter())
            .copied()
            .collect()
    }
}
