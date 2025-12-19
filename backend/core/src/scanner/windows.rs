//! Windows port scanner implementation using netstat.
//!
//! This module provides Windows-specific port scanning functionality.
//! It uses the `netstat` command.

use crate::error::{Error, Result};
use crate::models::PortInfo;

use super::Scanner;

/// Windows-specific port scanner.
pub struct WindowsScanner;

impl WindowsScanner {
    /// Create a new Windows scanner.
    pub fn new() -> Self {
        Self
    }
}

impl Default for WindowsScanner {
    fn default() -> Self {
        Self::new()
    }
}

impl Scanner for WindowsScanner {
    /// Scan all listening TCP ports.
    ///
    /// Uses `netstat -ano` command on Windows.
    async fn scan(&self) -> Result<Vec<PortInfo>> {
        // TODO: Implement Windows-specific scanning using netstat
        Err(Error::UnsupportedPlatform(
            "Windows scanner not yet implemented".to_string(),
        ))
    }
}
