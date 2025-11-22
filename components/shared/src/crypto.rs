//! Cryptographic utilities for the Academic Workflow Suite.
//!
//! This module provides secure cryptographic primitives including:
//! - SHA3-256 and SHA3-512 hashing
//! - HMAC generation and verification
//! - Random ID generation (UUID v4, nanoid)
//! - Constant-time comparison
//! - Key derivation (PBKDF2)
//!
//! All implementations use well-audited cryptographic libraries and follow
//! best practices for security.

use crate::errors::{Result, SharedError};
use hmac::{Hmac, Mac};
use pbkdf2::pbkdf2_hmac;
use sha3::{Digest, Sha3_256, Sha3_512};
use subtle::ConstantTimeEq;
use uuid::Uuid;

/// Default number of iterations for PBKDF2
pub const DEFAULT_PBKDF2_ITERATIONS: u32 = 100_000;

/// Default length for derived keys (32 bytes = 256 bits)
pub const DEFAULT_KEY_LENGTH: usize = 32;

/// Default alphabet for nanoid generation
const NANOID_ALPHABET: &[char] = &[
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
    'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
    'y', 'z',
];

/// Compute SHA3-256 hash of input data.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::sha3_256;
///
/// let hash = sha3_256(b"Hello, World!");
/// assert_eq!(hash.len(), 32);
/// ```
pub fn sha3_256(data: &[u8]) -> Vec<u8> {
    let mut hasher = Sha3_256::new();
    hasher.update(data);
    hasher.finalize().to_vec()
}

/// Compute SHA3-256 hash and return as hex string.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::sha3_256_hex;
///
/// let hash = sha3_256_hex(b"Hello, World!");
/// assert_eq!(hash.len(), 64); // 32 bytes = 64 hex chars
/// ```
pub fn sha3_256_hex(data: &[u8]) -> String {
    hex::encode(sha3_256(data))
}

/// Compute SHA3-512 hash of input data.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::sha3_512;
///
/// let hash = sha3_512(b"Hello, World!");
/// assert_eq!(hash.len(), 64);
/// ```
pub fn sha3_512(data: &[u8]) -> Vec<u8> {
    let mut hasher = Sha3_512::new();
    hasher.update(data);
    hasher.finalize().to_vec()
}

/// Compute SHA3-512 hash and return as hex string.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::sha3_512_hex;
///
/// let hash = sha3_512_hex(b"Hello, World!");
/// assert_eq!(hash.len(), 128); // 64 bytes = 128 hex chars
/// ```
pub fn sha3_512_hex(data: &[u8]) -> String {
    hex::encode(sha3_512(data))
}

/// Generate HMAC-SHA3-256 for given data and key.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::hmac_sha3_256;
///
/// let key = b"secret-key";
/// let data = b"message";
/// let mac = hmac_sha3_256(key, data).unwrap();
/// assert_eq!(mac.len(), 32);
/// ```
pub fn hmac_sha3_256(key: &[u8], data: &[u8]) -> Result<Vec<u8>> {
    type HmacSha3_256 = Hmac<Sha3_256>;

    let mut mac = HmacSha3_256::new_from_slice(key)
        .map_err(|e| SharedError::Crypto(format!("Invalid key length: {}", e)))?;

    mac.update(data);
    Ok(mac.finalize().into_bytes().to_vec())
}

/// Generate HMAC-SHA3-256 and return as hex string.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::hmac_sha3_256_hex;
///
/// let key = b"secret-key";
/// let data = b"message";
/// let mac = hmac_sha3_256_hex(key, data).unwrap();
/// assert_eq!(mac.len(), 64);
/// ```
pub fn hmac_sha3_256_hex(key: &[u8], data: &[u8]) -> Result<String> {
    hmac_sha3_256(key, data).map(|bytes| hex::encode(bytes))
}

/// Verify HMAC-SHA3-256 in constant time.
///
/// # Security
///
/// This function uses constant-time comparison to prevent timing attacks.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{hmac_sha3_256, verify_hmac_sha3_256};
///
/// let key = b"secret-key";
/// let data = b"message";
/// let mac = hmac_sha3_256(key, data).unwrap();
///
/// assert!(verify_hmac_sha3_256(key, data, &mac).unwrap());
/// assert!(!verify_hmac_sha3_256(key, b"wrong", &mac).unwrap());
/// ```
pub fn verify_hmac_sha3_256(key: &[u8], data: &[u8], expected_mac: &[u8]) -> Result<bool> {
    let computed_mac = hmac_sha3_256(key, data)?;
    Ok(constant_time_compare(&computed_mac, expected_mac))
}

/// Compare two byte slices in constant time.
///
/// # Security
///
/// This function prevents timing attacks by ensuring that comparison
/// time does not depend on where the difference occurs.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::constant_time_compare;
///
/// assert!(constant_time_compare(b"hello", b"hello"));
/// assert!(!constant_time_compare(b"hello", b"world"));
/// assert!(!constant_time_compare(b"hello", b"hi"));
/// ```
pub fn constant_time_compare(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.ct_eq(b).into()
}

/// Generate a random UUID v4.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::generate_uuid;
///
/// let id = generate_uuid();
/// assert_eq!(id.len(), 36); // UUID string format
/// ```
pub fn generate_uuid() -> String {
    Uuid::new_v4().to_string()
}

/// Generate a random nanoid with default settings (21 characters).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::generate_nanoid;
///
/// let id = generate_nanoid();
/// assert_eq!(id.len(), 21);
/// ```
pub fn generate_nanoid() -> String {
    nanoid::nanoid!()
}

/// Generate a random nanoid with custom length.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::generate_nanoid_with_length;
///
/// let id = generate_nanoid_with_length(10);
/// assert_eq!(id.len(), 10);
/// ```
pub fn generate_nanoid_with_length(length: usize) -> String {
    nanoid::nanoid!(length)
}

/// Generate a random nanoid with custom alphabet and length.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::generate_nanoid_custom;
///
/// let alphabet = &['A', 'B', 'C', 'D', 'E', 'F'];
/// let id = generate_nanoid_custom(alphabet, 8);
/// assert_eq!(id.len(), 8);
/// assert!(id.chars().all(|c| alphabet.contains(&c)));
/// ```
pub fn generate_nanoid_custom(alphabet: &[char], length: usize) -> String {
    nanoid::nanoid!(length, alphabet)
}

/// Generate a URL-safe random ID (using alphanumeric characters).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::generate_url_safe_id;
///
/// let id = generate_url_safe_id(16);
/// assert_eq!(id.len(), 16);
/// ```
pub fn generate_url_safe_id(length: usize) -> String {
    generate_nanoid_custom(NANOID_ALPHABET, length)
}

/// Derive a key from a password using PBKDF2-HMAC-SHA256.
///
/// # Security
///
/// - Uses a minimum of 100,000 iterations by default
/// - Requires a unique salt for each password
/// - Output length should be at least 32 bytes
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{derive_key, DEFAULT_PBKDF2_ITERATIONS, DEFAULT_KEY_LENGTH};
///
/// let password = b"secure-password";
/// let salt = b"unique-salt-per-user";
/// let key = derive_key(password, salt, DEFAULT_PBKDF2_ITERATIONS, DEFAULT_KEY_LENGTH);
/// assert_eq!(key.len(), DEFAULT_KEY_LENGTH);
/// ```
pub fn derive_key(password: &[u8], salt: &[u8], iterations: u32, output_length: usize) -> Vec<u8> {
    let mut output = vec![0u8; output_length];
    pbkdf2_hmac::<sha3::Sha3_256>(password, salt, iterations, &mut output);
    output
}

/// Derive a key and return as hex string.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{derive_key_hex, DEFAULT_PBKDF2_ITERATIONS, DEFAULT_KEY_LENGTH};
///
/// let password = b"secure-password";
/// let salt = b"unique-salt";
/// let key = derive_key_hex(password, salt, DEFAULT_PBKDF2_ITERATIONS, DEFAULT_KEY_LENGTH);
/// assert_eq!(key.len(), DEFAULT_KEY_LENGTH * 2); // hex encoding doubles length
/// ```
pub fn derive_key_hex(password: &[u8], salt: &[u8], iterations: u32, output_length: usize) -> String {
    hex::encode(derive_key(password, salt, iterations, output_length))
}

/// Generate a cryptographically secure random salt.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::generate_salt;
///
/// let salt = generate_salt(16);
/// assert_eq!(salt.len(), 16);
/// ```
pub fn generate_salt(length: usize) -> Vec<u8> {
    use uuid::Uuid;
    let mut salt = Vec::with_capacity(length);
    while salt.len() < length {
        let uuid_bytes = Uuid::new_v4().as_bytes().to_vec();
        salt.extend_from_slice(&uuid_bytes);
    }
    salt.truncate(length);
    salt
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha3_256() {
        let hash = sha3_256(b"test");
        assert_eq!(hash.len(), 32);

        // Test deterministic
        let hash2 = sha3_256(b"test");
        assert_eq!(hash, hash2);

        // Test different input produces different hash
        let hash3 = sha3_256(b"different");
        assert_ne!(hash, hash3);
    }

    #[test]
    fn test_sha3_256_hex() {
        let hash = sha3_256_hex(b"test");
        assert_eq!(hash.len(), 64);
        assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_sha3_512() {
        let hash = sha3_512(b"test");
        assert_eq!(hash.len(), 64);
    }

    #[test]
    fn test_sha3_512_hex() {
        let hash = sha3_512_hex(b"test");
        assert_eq!(hash.len(), 128);
        assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_hmac_sha3_256() {
        let key = b"secret-key";
        let data = b"message";
        let mac = hmac_sha3_256(key, data).unwrap();
        assert_eq!(mac.len(), 32);

        // Test deterministic
        let mac2 = hmac_sha3_256(key, data).unwrap();
        assert_eq!(mac, mac2);

        // Different key produces different MAC
        let mac3 = hmac_sha3_256(b"different-key", data).unwrap();
        assert_ne!(mac, mac3);
    }

    #[test]
    fn test_verify_hmac_sha3_256() {
        let key = b"secret-key";
        let data = b"message";
        let mac = hmac_sha3_256(key, data).unwrap();

        assert!(verify_hmac_sha3_256(key, data, &mac).unwrap());
        assert!(!verify_hmac_sha3_256(key, b"wrong", &mac).unwrap());
        assert!(!verify_hmac_sha3_256(b"wrong-key", data, &mac).unwrap());
    }

    #[test]
    fn test_constant_time_compare() {
        assert!(constant_time_compare(b"hello", b"hello"));
        assert!(!constant_time_compare(b"hello", b"world"));
        assert!(!constant_time_compare(b"hello", b"hello!"));
        assert!(!constant_time_compare(b"", b"x"));
    }

    #[test]
    fn test_generate_uuid() {
        let id1 = generate_uuid();
        let id2 = generate_uuid();

        assert_eq!(id1.len(), 36);
        assert_eq!(id2.len(), 36);
        assert_ne!(id1, id2); // UUIDs should be unique
    }

    #[test]
    fn test_generate_nanoid() {
        let id1 = generate_nanoid();
        let id2 = generate_nanoid();

        assert_eq!(id1.len(), 21);
        assert_eq!(id2.len(), 21);
        assert_ne!(id1, id2);
    }

    #[test]
    fn test_generate_nanoid_with_length() {
        let id = generate_nanoid_with_length(10);
        assert_eq!(id.len(), 10);
    }

    #[test]
    fn test_generate_nanoid_custom() {
        let alphabet = &['A', 'B', 'C'];
        let id = generate_nanoid_custom(alphabet, 8);
        assert_eq!(id.len(), 8);
        assert!(id.chars().all(|c| alphabet.contains(&c)));
    }

    #[test]
    fn test_generate_url_safe_id() {
        let id = generate_url_safe_id(16);
        assert_eq!(id.len(), 16);
        assert!(id.chars().all(|c| c.is_alphanumeric()));
    }

    #[test]
    fn test_derive_key() {
        let password = b"my-password";
        let salt = b"unique-salt";
        let key = derive_key(password, salt, 1000, 32);

        assert_eq!(key.len(), 32);

        // Test deterministic
        let key2 = derive_key(password, salt, 1000, 32);
        assert_eq!(key, key2);

        // Different password produces different key
        let key3 = derive_key(b"different", salt, 1000, 32);
        assert_ne!(key, key3);

        // Different salt produces different key
        let key4 = derive_key(password, b"different-salt", 1000, 32);
        assert_ne!(key, key4);
    }

    #[test]
    fn test_derive_key_hex() {
        let key = derive_key_hex(b"password", b"salt", 1000, 32);
        assert_eq!(key.len(), 64); // 32 bytes = 64 hex chars
        assert!(key.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_generate_salt() {
        let salt1 = generate_salt(16);
        let salt2 = generate_salt(16);

        assert_eq!(salt1.len(), 16);
        assert_eq!(salt2.len(), 16);
        assert_ne!(salt1, salt2); // Salts should be unique
    }

    #[test]
    fn test_generate_salt_various_lengths() {
        for len in &[8, 16, 32, 64, 100] {
            let salt = generate_salt(*len);
            assert_eq!(salt.len(), *len);
        }
    }
}
