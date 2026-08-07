//! Tibia .otbm (Open Tibia Binary Map) parser.

use super::binary::BinaryReader;
use std::io::Cursor;

pub struct OtbmFile {
    pub version: u16,
    pub width: u16,
    pub height: u16,
}

impl OtbmFile {
    pub fn parse(data: &[u8]) -> Result<Self, String> {
        let mut reader = BinaryReader::new(Cursor::new(data));
        let version = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read otbm version: {e}"))?;
        let width = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read otbm width: {e}"))?;
        let height = reader
            .read_u16_le()
            .map_err(|e| format!("failed to read otbm height: {e}"))?;

        Ok(Self {
            version,
            width,
            height,
        })
    }
}
