//! Tibia .otb (Open Tibia Binary) item definitions parser.

use super::binary::BinaryReader;
use std::io::Cursor;

pub struct OtbFile {
    pub root_flags: u8,
}

impl OtbFile {
    pub fn parse(data: &[u8]) -> Result<Self, String> {
        if data.len() < 4 {
            return Err("otb file too short".into());
        }

        let mut reader = BinaryReader::new(Cursor::new(data));
        let root_flags = reader
            .read_u8()
            .map_err(|e| format!("failed to read otb root flags: {e}"))?;

        Ok(Self { root_flags })
    }
}
