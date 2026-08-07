//! Tibia .dat thing definition file parser.

use super::binary::BinaryReader;
use std::io::Cursor;

pub struct DatFile {
    pub signature: u32,
    pub item_count: u16,
    pub outfit_count: u16,
    pub effect_count: u16,
    pub missile_count: u16,
}

impl DatFile {
    pub fn parse(data: &[u8]) -> Result<Self, String> {
        let mut reader = BinaryReader::new(Cursor::new(data));
        let signature = reader
            .read_u32_le()
            .map_err(|e| format!("failed to read dat signature: {e}"))?;
        let item_count = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read dat item count: {e}"))?;
        let outfit_count = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read dat outfit count: {e}"))?;
        let effect_count = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read dat effect count: {e}"))?;
        let missile_count = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read dat missile count: {e}"))?;

        Ok(Self {
            signature,
            item_count,
            outfit_count,
            effect_count,
            missile_count,
        })
    }
}
