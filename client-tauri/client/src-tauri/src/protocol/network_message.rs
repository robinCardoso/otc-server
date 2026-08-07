//! Tibia network message buffer (TFS 8.60).

use crate::tibia::binary::BinaryWriter;

pub struct NetworkMessage {
    writer: BinaryWriter,
}

impl NetworkMessage {
    pub fn new() -> Self {
        Self {
            writer: BinaryWriter::new(),
        }
    }

    pub fn write_u8(&mut self, value: u8) {
        self.writer.write_u8(value);
    }

    pub fn write_u16(&mut self, value: u16) {
        self.writer.write_u16_le(value);
    }

    pub fn write_u32(&mut self, value: u32) {
        self.writer.write_u32_le(value);
    }

    pub fn as_bytes(&self) -> &[u8] {
        self.writer.as_bytes()
    }
}
