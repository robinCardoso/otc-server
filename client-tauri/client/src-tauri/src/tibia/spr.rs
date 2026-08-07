//! Tibia .spr sprite file parser.

use super::binary::BinaryReader;
use std::io::Cursor;

pub struct SpriteFile {
    pub signature: u32,
    pub sprite_count: u16,
}

impl SpriteFile {
    pub fn parse(data: &[u8]) -> Result<Self, String> {
        let mut reader = BinaryReader::new(Cursor::new(data));
        let signature = reader
            .read_u32_le()
            .map_err(|e| format!("failed to read spr signature: {e}"))?;
        let sprite_count = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read spr sprite count: {e}"))?;

        Ok(Self {
            signature,
            sprite_count,
        })
    }
}
