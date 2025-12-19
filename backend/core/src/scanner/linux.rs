//! Linux port scanner implementation using ss or netstat.
//!
//! This module provides Linux-specific port scanning functionality.
//! It uses the `ss` command (preferred) or falls back to `netstat`.

use crate::error::{Error, Result};
use crate::models::PortInfo;

use super::Scanner;

/// Linux-specific port scanner.
pub struct LinuxScanner;

impl LinuxScanner {
    /// Create a new Linux scanner.
    pub fn new() -> Self {
        Self
    }
}

impl Default for LinuxScanner {
    fn default() -> Self {
        Self::new()
    }
}

impl Scanner for LinuxScanner {
    /// Scan all listening TCP ports.
    ///
    /// Uses `ss -tlnp` command on Linux.
    async fn scan(&self) -> Result<Vec<PortInfo>> {
        // TODO: Implement Linux-specific scanning using ss or netstat
        Err(Error::UnsupportedPlatform(
            "Linux scanner not yet implemented".to_string(),
        ))
    }
}
