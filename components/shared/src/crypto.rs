//! Cryptographic utilities for the Academic Workflow Suite.
//!
//! This module provides secure cryptographic primitives following the
//! Hyperpolymath Crypto Standard (see CRYPTO-STANDARD.scm):
//!
//! ## Hashing
//! - BLAKE3 (primary): Fast, secure, parallel hashing
//! - SHA3-256/512 (secondary): NIST standard when BLAKE3 unavailable
//!
//! ## Password Hashing
//! - Argon2id: Memory-hard, side-channel resistant (replaces PBKDF2)
//!
//! ## Post-Quantum Cryptography
//! - Dilithium5 (ML-DSA-87): Post-quantum signatures, NIST Level 5
//! - Kyber-1024 (ML-KEM-1024): Post-quantum key exchange, NIST Level 5
//!
//! ## Classical Cryptography
//! - Ed25519: EdDSA signatures (Ed448 preferred when available)
//!
//! ## Other
//! - HMAC generation and verification
//! - Random ID generation (UUID v4, nanoid)
//! - Constant-time comparison
//!
//! All implementations use well-audited cryptographic libraries and follow
//! best practices for security. Deprecated algorithms (PBKDF2, MD5, SHA1)
//! are NOT supported.

use crate::errors::{Result, SharedError};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use argon2::password_hash::SaltString;
use hmac::{Hmac, Mac};
use sha3::{Digest, Sha3_256, Sha3_512};
use subtle::ConstantTimeEq;
use uuid::Uuid;
use zeroize::Zeroizing;

// Argon2id parameters per Hyperpolymath Crypto Standard
/// Memory cost: 64 MiB minimum
pub const ARGON2_MEMORY_COST: u32 = 65536; // 64 MiB in KiB
/// Time cost: 3 iterations minimum
pub const ARGON2_TIME_COST: u32 = 3;
/// Parallelism: 4 threads minimum
pub const ARGON2_PARALLELISM: u32 = 4;
/// Output length: 32 bytes minimum
pub const ARGON2_OUTPUT_LENGTH: usize = 32;

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

// ============================================================================
// BLAKE3 Hashing (Primary - Hyperpolymath Crypto Standard)
// ============================================================================

/// Compute BLAKE3 hash of input data (256-bit output).
///
/// BLAKE3 is the primary hashing algorithm per Hyperpolymath Crypto Standard.
/// It is faster than SHA-256/SHA-3 while providing equivalent security.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::blake3_hash;
///
/// let hash = blake3_hash(b"Hello, World!");
/// assert_eq!(hash.len(), 32);
/// ```
pub fn blake3_hash(data: &[u8]) -> Vec<u8> {
    blake3::hash(data).as_bytes().to_vec()
}

/// Compute BLAKE3 hash and return as hex string.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::blake3_hash_hex;
///
/// let hash = blake3_hash_hex(b"Hello, World!");
/// assert_eq!(hash.len(), 64); // 32 bytes = 64 hex chars
/// ```
pub fn blake3_hash_hex(data: &[u8]) -> String {
    hex::encode(blake3_hash(data))
}

/// Compute BLAKE3 hash with variable output length (XOF mode).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::blake3_hash_xof;
///
/// let hash = blake3_hash_xof(b"data", 64);
/// assert_eq!(hash.len(), 64);
/// ```
pub fn blake3_hash_xof(data: &[u8], output_len: usize) -> Vec<u8> {
    let mut hasher = blake3::Hasher::new();
    hasher.update(data);
    let mut output = vec![0u8; output_len];
    hasher.finalize_xof().fill(&mut output);
    output
}

/// Compute BLAKE3 keyed hash (MAC).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::blake3_keyed_hash;
///
/// let key = [0u8; 32]; // Must be exactly 32 bytes
/// let mac = blake3_keyed_hash(&key, b"message");
/// assert_eq!(mac.len(), 32);
/// ```
pub fn blake3_keyed_hash(key: &[u8; 32], data: &[u8]) -> Vec<u8> {
    blake3::keyed_hash(key, data).as_bytes().to_vec()
}

/// Derive a key using BLAKE3-KDF.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::blake3_derive_key;
///
/// let key = blake3_derive_key("my-context", b"input-key-material", 32);
/// assert_eq!(key.len(), 32);
/// ```
pub fn blake3_derive_key(context: &str, ikm: &[u8], output_len: usize) -> Vec<u8> {
    let mut hasher = blake3::Hasher::new_derive_key(context);
    hasher.update(ikm);
    let mut output = vec![0u8; output_len];
    hasher.finalize_xof().fill(&mut output);
    output
}

// ============================================================================
// SHA3 Hashing (Secondary - for compatibility)
// ============================================================================

/// Compute SHA3-256 hash of input data.
///
/// Note: Prefer `blake3_hash` for new code per Hyperpolymath Crypto Standard.
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

// ============================================================================
// Password Hashing (Argon2id - Hyperpolymath Crypto Standard)
// ============================================================================

/// Hash a password using Argon2id.
///
/// Uses memory-hard, side-channel resistant Argon2id as per Hyperpolymath
/// Crypto Standard. Parameters: 64 MiB memory, 3 iterations, 4 threads.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::hash_password;
///
/// let hash = hash_password(b"secure-password").unwrap();
/// assert!(hash.starts_with("$argon2id$"));
/// ```
pub fn hash_password(password: &[u8]) -> Result<String> {
    let salt = SaltString::generate(&mut rand::thread_rng());
    let params = argon2::Params::new(
        ARGON2_MEMORY_COST,
        ARGON2_TIME_COST,
        ARGON2_PARALLELISM,
        Some(ARGON2_OUTPUT_LENGTH),
    ).map_err(|e| SharedError::Crypto(format!("Invalid Argon2 params: {}", e)))?;

    let argon2 = Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);
    let hash = argon2.hash_password(password, &salt)
        .map_err(|e| SharedError::Crypto(format!("Password hashing failed: {}", e)))?;

    Ok(hash.to_string())
}

/// Verify a password against an Argon2id hash.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{hash_password, verify_password};
///
/// let hash = hash_password(b"secure-password").unwrap();
/// assert!(verify_password(b"secure-password", &hash).unwrap());
/// assert!(!verify_password(b"wrong-password", &hash).unwrap());
/// ```
pub fn verify_password(password: &[u8], hash: &str) -> Result<bool> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| SharedError::Crypto(format!("Invalid hash format: {}", e)))?;

    Ok(Argon2::default().verify_password(password, &parsed_hash).is_ok())
}

/// Derive a key from a password using Argon2id.
///
/// # Security
///
/// - Uses Argon2id (memory-hard, side-channel resistant)
/// - 64 MiB memory, 3 iterations, 4 threads
/// - Requires a unique salt for each password
/// - Output length should be at least 32 bytes
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{derive_key, DEFAULT_KEY_LENGTH};
///
/// let password = b"secure-password";
/// let salt = b"unique-salt-per-user-16b"; // Should be 16+ bytes
/// let key = derive_key(password, salt, DEFAULT_KEY_LENGTH).unwrap();
/// assert_eq!(key.len(), DEFAULT_KEY_LENGTH);
/// ```
pub fn derive_key(password: &[u8], salt: &[u8], output_length: usize) -> Result<Zeroizing<Vec<u8>>> {
    let params = argon2::Params::new(
        ARGON2_MEMORY_COST,
        ARGON2_TIME_COST,
        ARGON2_PARALLELISM,
        Some(output_length),
    ).map_err(|e| SharedError::Crypto(format!("Invalid Argon2 params: {}", e)))?;

    let argon2 = Argon2::new(argon2::Algorithm::Argon2id, argon2::Version::V0x13, params);
    let mut output = Zeroizing::new(vec![0u8; output_length]);
    argon2.hash_password_into(password, salt, &mut output)
        .map_err(|e| SharedError::Crypto(format!("Key derivation failed: {}", e)))?;

    Ok(output)
}

/// Derive a key and return as hex string.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{derive_key_hex, DEFAULT_KEY_LENGTH};
///
/// let password = b"secure-password";
/// let salt = b"unique-salt-16bytes!";
/// let key = derive_key_hex(password, salt, DEFAULT_KEY_LENGTH).unwrap();
/// assert_eq!(key.len(), DEFAULT_KEY_LENGTH * 2); // hex encoding doubles length
/// ```
pub fn derive_key_hex(password: &[u8], salt: &[u8], output_length: usize) -> Result<String> {
    derive_key(password, salt, output_length).map(|key| hex::encode(&*key))
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

// ============================================================================
// Post-Quantum Signatures (Dilithium5/ML-DSA-87 - NIST Level 5)
// ============================================================================

/// Generate a Dilithium5 (ML-DSA-87) keypair.
///
/// Dilithium5 provides NIST Level 5 post-quantum security for digital signatures.
/// This is required by the Hyperpolymath Crypto Standard.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::dilithium_keypair;
///
/// let (public_key, secret_key) = dilithium_keypair();
/// ```
pub fn dilithium_keypair() -> (Vec<u8>, Vec<u8>) {
    use pqcrypto_dilithium::dilithium5;
    let (pk, sk) = dilithium5::keypair();
    (pk.as_bytes().to_vec(), sk.as_bytes().to_vec())
}

/// Sign a message using Dilithium5 (ML-DSA-87).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{dilithium_keypair, dilithium_sign};
///
/// let (_, secret_key) = dilithium_keypair();
/// let signature = dilithium_sign(b"message", &secret_key).unwrap();
/// ```
pub fn dilithium_sign(message: &[u8], secret_key: &[u8]) -> Result<Vec<u8>> {
    use pqcrypto_dilithium::dilithium5;
    use pqcrypto_traits::sign::SecretKey;

    let sk = dilithium5::SecretKey::from_bytes(secret_key)
        .map_err(|_| SharedError::Crypto("Invalid Dilithium5 secret key".to_string()))?;
    let sig = dilithium5::detached_sign(message, &sk);
    Ok(sig.as_bytes().to_vec())
}

/// Verify a Dilithium5 (ML-DSA-87) signature.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{dilithium_keypair, dilithium_sign, dilithium_verify};
///
/// let (public_key, secret_key) = dilithium_keypair();
/// let signature = dilithium_sign(b"message", &secret_key).unwrap();
/// assert!(dilithium_verify(b"message", &signature, &public_key).unwrap());
/// ```
pub fn dilithium_verify(message: &[u8], signature: &[u8], public_key: &[u8]) -> Result<bool> {
    use pqcrypto_dilithium::dilithium5;
    use pqcrypto_traits::sign::{PublicKey, DetachedSignature};

    let pk = dilithium5::PublicKey::from_bytes(public_key)
        .map_err(|_| SharedError::Crypto("Invalid Dilithium5 public key".to_string()))?;
    let sig = dilithium5::DetachedSignature::from_bytes(signature)
        .map_err(|_| SharedError::Crypto("Invalid Dilithium5 signature".to_string()))?;

    Ok(dilithium5::verify_detached_signature(&sig, message, &pk).is_ok())
}

// ============================================================================
// Post-Quantum Key Exchange (Kyber-1024/ML-KEM-1024 - NIST Level 5)
// ============================================================================

/// Generate a Kyber-1024 (ML-KEM-1024) keypair.
///
/// Kyber-1024 provides NIST Level 5 post-quantum security for key encapsulation.
/// This is required by the Hyperpolymath Crypto Standard.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::kyber_keypair;
///
/// let (public_key, secret_key) = kyber_keypair();
/// ```
pub fn kyber_keypair() -> (Vec<u8>, Vec<u8>) {
    use pqcrypto_kyber::kyber1024;
    let (pk, sk) = kyber1024::keypair();
    (pk.as_bytes().to_vec(), sk.as_bytes().to_vec())
}

/// Encapsulate a shared secret using Kyber-1024.
///
/// Returns (ciphertext, shared_secret).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{kyber_keypair, kyber_encapsulate};
///
/// let (public_key, _) = kyber_keypair();
/// let (ciphertext, shared_secret) = kyber_encapsulate(&public_key).unwrap();
/// ```
pub fn kyber_encapsulate(public_key: &[u8]) -> Result<(Vec<u8>, Vec<u8>)> {
    use pqcrypto_kyber::kyber1024;
    use pqcrypto_traits::kem::PublicKey;

    let pk = kyber1024::PublicKey::from_bytes(public_key)
        .map_err(|_| SharedError::Crypto("Invalid Kyber-1024 public key".to_string()))?;
    let (ss, ct) = kyber1024::encapsulate(&pk);
    Ok((ct.as_bytes().to_vec(), ss.as_bytes().to_vec()))
}

/// Decapsulate a shared secret using Kyber-1024.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{kyber_keypair, kyber_encapsulate, kyber_decapsulate};
///
/// let (public_key, secret_key) = kyber_keypair();
/// let (ciphertext, shared_secret1) = kyber_encapsulate(&public_key).unwrap();
/// let shared_secret2 = kyber_decapsulate(&ciphertext, &secret_key).unwrap();
/// assert_eq!(shared_secret1, shared_secret2);
/// ```
pub fn kyber_decapsulate(ciphertext: &[u8], secret_key: &[u8]) -> Result<Vec<u8>> {
    use pqcrypto_kyber::kyber1024;
    use pqcrypto_traits::kem::{SecretKey, Ciphertext};

    let sk = kyber1024::SecretKey::from_bytes(secret_key)
        .map_err(|_| SharedError::Crypto("Invalid Kyber-1024 secret key".to_string()))?;
    let ct = kyber1024::Ciphertext::from_bytes(ciphertext)
        .map_err(|_| SharedError::Crypto("Invalid Kyber-1024 ciphertext".to_string()))?;
    let ss = kyber1024::decapsulate(&ct, &sk);
    Ok(ss.as_bytes().to_vec())
}

// ============================================================================
// Classical Signatures (Ed25519 - fallback when Ed448 unavailable)
// ============================================================================

/// Generate an Ed25519 keypair.
///
/// Note: Ed448 is preferred per Hyperpolymath Crypto Standard, but Ed25519
/// is acceptable when Ed448 is not available (e.g., SSH keys).
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::ed25519_keypair;
///
/// let (public_key, secret_key) = ed25519_keypair();
/// ```
pub fn ed25519_keypair() -> (Vec<u8>, Vec<u8>) {
    use ed25519_dalek::{SigningKey, VerifyingKey};
    use rand::rngs::OsRng;

    let signing_key = SigningKey::generate(&mut OsRng);
    let verifying_key: VerifyingKey = (&signing_key).into();
    (verifying_key.as_bytes().to_vec(), signing_key.to_bytes().to_vec())
}

/// Sign a message using Ed25519.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{ed25519_keypair, ed25519_sign};
///
/// let (_, secret_key) = ed25519_keypair();
/// let signature = ed25519_sign(b"message", &secret_key).unwrap();
/// ```
pub fn ed25519_sign(message: &[u8], secret_key: &[u8]) -> Result<Vec<u8>> {
    use ed25519_dalek::{Signature, Signer, SigningKey};

    let sk_bytes: [u8; 32] = secret_key.try_into()
        .map_err(|_| SharedError::Crypto("Invalid Ed25519 secret key length".to_string()))?;
    let signing_key = SigningKey::from_bytes(&sk_bytes);
    let signature: Signature = signing_key.sign(message);
    Ok(signature.to_bytes().to_vec())
}

/// Verify an Ed25519 signature.
///
/// # Examples
///
/// ```
/// use academic_shared::crypto::{ed25519_keypair, ed25519_sign, ed25519_verify};
///
/// let (public_key, secret_key) = ed25519_keypair();
/// let signature = ed25519_sign(b"message", &secret_key).unwrap();
/// assert!(ed25519_verify(b"message", &signature, &public_key).unwrap());
/// ```
pub fn ed25519_verify(message: &[u8], signature: &[u8], public_key: &[u8]) -> Result<bool> {
    use ed25519_dalek::{Signature, Verifier, VerifyingKey};

    let pk_bytes: [u8; 32] = public_key.try_into()
        .map_err(|_| SharedError::Crypto("Invalid Ed25519 public key length".to_string()))?;
    let sig_bytes: [u8; 64] = signature.try_into()
        .map_err(|_| SharedError::Crypto("Invalid Ed25519 signature length".to_string()))?;

    let verifying_key = VerifyingKey::from_bytes(&pk_bytes)
        .map_err(|_| SharedError::Crypto("Invalid Ed25519 public key".to_string()))?;
    let sig = Signature::from_bytes(&sig_bytes);

    Ok(verifying_key.verify(message, &sig).is_ok())
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

    // ====== BLAKE3 Tests ======

    #[test]
    fn test_blake3_hash() {
        let hash = blake3_hash(b"test");
        assert_eq!(hash.len(), 32);

        // Test deterministic
        let hash2 = blake3_hash(b"test");
        assert_eq!(hash, hash2);

        // Different input produces different hash
        let hash3 = blake3_hash(b"different");
        assert_ne!(hash, hash3);
    }

    #[test]
    fn test_blake3_hash_hex() {
        let hash = blake3_hash_hex(b"test");
        assert_eq!(hash.len(), 64);
        assert!(hash.chars().all(|c| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_blake3_hash_xof() {
        let hash = blake3_hash_xof(b"test", 64);
        assert_eq!(hash.len(), 64);

        let hash2 = blake3_hash_xof(b"test", 128);
        assert_eq!(hash2.len(), 128);
    }

    #[test]
    fn test_blake3_keyed_hash() {
        let key = [0u8; 32];
        let mac = blake3_keyed_hash(&key, b"message");
        assert_eq!(mac.len(), 32);

        // Different key produces different MAC
        let key2 = [1u8; 32];
        let mac2 = blake3_keyed_hash(&key2, b"message");
        assert_ne!(mac, mac2);
    }

    #[test]
    fn test_blake3_derive_key() {
        let key = blake3_derive_key("context", b"ikm", 32);
        assert_eq!(key.len(), 32);

        // Same context and ikm produces same key
        let key2 = blake3_derive_key("context", b"ikm", 32);
        assert_eq!(key, key2);

        // Different context produces different key
        let key3 = blake3_derive_key("different", b"ikm", 32);
        assert_ne!(key, key3);
    }

    // ====== Argon2id Tests ======

    #[test]
    fn test_hash_password() {
        let hash = hash_password(b"secure-password").unwrap();
        assert!(hash.starts_with("$argon2id$"));
    }

    #[test]
    fn test_verify_password() {
        let hash = hash_password(b"secure-password").unwrap();
        assert!(verify_password(b"secure-password", &hash).unwrap());
        assert!(!verify_password(b"wrong-password", &hash).unwrap());
    }

    #[test]
    fn test_derive_key() {
        let password = b"my-password";
        let salt = b"unique-salt-16bytes!"; // Salt should be 16+ bytes
        let key = derive_key(password, salt, 32).unwrap();

        assert_eq!(key.len(), 32);

        // Test deterministic
        let key2 = derive_key(password, salt, 32).unwrap();
        assert_eq!(&*key, &*key2);

        // Different password produces different key
        let key3 = derive_key(b"different", salt, 32).unwrap();
        assert_ne!(&*key, &*key3);

        // Different salt produces different key
        let key4 = derive_key(password, b"different-salt-16by!", 32).unwrap();
        assert_ne!(&*key, &*key4);
    }

    #[test]
    fn test_derive_key_hex() {
        let key = derive_key_hex(b"password", b"salt-16-bytes!!!", 32).unwrap();
        assert_eq!(key.len(), 64); // 32 bytes = 64 hex chars
        assert!(key.chars().all(|c| c.is_ascii_hexdigit()));
    }

    // ====== Salt Generation Tests ======

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

    // ====== Post-Quantum Crypto Tests ======

    #[test]
    fn test_dilithium_keypair() {
        let (pk, sk) = dilithium_keypair();
        assert!(!pk.is_empty());
        assert!(!sk.is_empty());
    }

    #[test]
    fn test_dilithium_sign_verify() {
        let (pk, sk) = dilithium_keypair();
        let message = b"test message";

        let signature = dilithium_sign(message, &sk).unwrap();
        assert!(dilithium_verify(message, &signature, &pk).unwrap());
        assert!(!dilithium_verify(b"wrong message", &signature, &pk).unwrap());
    }

    #[test]
    fn test_kyber_keypair() {
        let (pk, sk) = kyber_keypair();
        assert!(!pk.is_empty());
        assert!(!sk.is_empty());
    }

    #[test]
    fn test_kyber_encapsulate_decapsulate() {
        let (pk, sk) = kyber_keypair();
        let (ct, ss1) = kyber_encapsulate(&pk).unwrap();
        let ss2 = kyber_decapsulate(&ct, &sk).unwrap();
        assert_eq!(ss1, ss2);
    }

    // ====== Ed25519 Tests ======

    #[test]
    fn test_ed25519_keypair() {
        let (pk, sk) = ed25519_keypair();
        assert_eq!(pk.len(), 32);
        assert_eq!(sk.len(), 32);
    }

    #[test]
    fn test_ed25519_sign_verify() {
        let (pk, sk) = ed25519_keypair();
        let message = b"test message";

        let signature = ed25519_sign(message, &sk).unwrap();
        assert_eq!(signature.len(), 64);
        assert!(ed25519_verify(message, &signature, &pk).unwrap());
        assert!(!ed25519_verify(b"wrong message", &signature, &pk).unwrap());
    }
}
