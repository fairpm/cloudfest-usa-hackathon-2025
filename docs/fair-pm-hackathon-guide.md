# **FAIR Package Manager: Developer Integration Guide**

**CloudFest USA – November 4, 2025**
📍 *Miami Marriott Biscayne Bay*
👥 *20–25 Selected Participants*
🔗 [https://www.cloudfest.com/usa/hackathon/](https://www.cloudfest.com/usa/hackathon/)
💰Thanks to the exclusive Hackathon sponsor, **Patchstack!**

---

## **📋 Overview**

FAIR (Federated And Independent Repositories) uses decentralized identifiers (DIDs) and Ed25519 cryptography to enable secure, federated WordPress package distribution.

**Core components:**

* **DIDs** - Permanent package identity (e.g., `did:plc:deoui6ztyx6paqajconl67rz`)
* **Ed25519** - Package signature verification
* **JSON-LD** - Package metadata format
* **REST APIs** - Package distribution endpoints

---

## **⚠️ Code Signoff**

If committing code to any FAIR Github repository, note that, you need to sign off on your commits by adding this to your commit messages:

`Signed-off-by: Author Name <authoremail@example.com>`

This is *not* a cryptographic signature. If you are unfamiliar with code signoff, please see [these resources](https://github.com/fairpm/tsc/blob/main/contributing.md#code-signoff) or ask a fellow dev for help.

---

## **📚 Reference Links**

### **Core Repositories**

* **Protocol Spec:** [`https://github.com/fairpm/fair-protocol`](https://github.com/fairpm/fair-protocol)
* **Labelling (Moderation) Spec:** [`https://github.com/fairpm/fair-protocol/tree/main/docs/moderation`](https://github.com/fairpm/fair-protocol/tree/main/docs/moderation)
* **FAIR Plugin:** [`https://github.com/fairpm/fair-plugin`](https://github.com/fairpm/fair-plugin)
* **Mini-FAIR Repo:** [`https://github.com/fairpm/mini-fair-repo`](https://github.com/fairpm/mini-fair-repo)
* **AspireCloud:** [`https://github.com/aspirepress/AspireCloud`](https://github.com/aspirepress/AspireCloud)

### **Services**

* **FAIR Website:** [`https://fair.pm`](https://fair.pm)
* **PLC Directory:** [`https://plc.directory`](https://plc.directory)
* **AspireCloud Production API:** [`https://api.aspirecloud.net`](https://api.aspirecloud.net)
* **AspireCloud Staging API:** [`https://api.aspirecloud.io`](https://api.aspirecloud.io)

### **Documentation**

* **AspireCloud Docs:** [`https://docs.aspirepress.org/aspirecloud/`](https://docs.aspirepress.org/aspirecloud/)
* **W3C DID Core:** [`https://w3.org/TR/did-core/`](https://w3.org/TR/did-core/)
* **Ed25519:** [`https://ed25519.cr.yp.to`](https://ed25519.cr.yp.to)

---

## **🌐 AspireCloud API**

### **Quick Start Guide to AspireCloud**

[AspireCloud](https://github.com/aspirepress/AspireCloud) is an open source project that functions as a CDN and a set of API endpoints for distributing WordPress assets (themes, plugins, core).

[https://github.com/aspirepress/AspireCloud/blob/main/docs/readme.hackathon.md](https://github.com/aspirepress/AspireCloud/blob/main/docs/readme.hackathon.md)

**Base URL:** [`https://api.aspirecloud.net`](https://api.aspirecloud.net)

AspireCloud implements WordPress.org API specifications as a pull-through cache.

### **Key Endpoints**

```
POST /plugins/info/1.1/          # Plugin queries
GET /themes/info/1.1/            # Theme queries
GET /core/version-check/1.7/     # Core updates
GET /core/checksums/1.0/         # File integrity
```

**Actions:** `query_plugins`, `plugin_information`, `query_themes`

📚 **Full documentation:** [`https://docs.aspirepress.org/aspirecloud/`](https://docs.aspirepress.org/aspirecloud/)

---

## **🔌 FAIR Plugin**

The FAIR plugin reduces dependency on WordPress.org services and enables DID-based resolution for sourcing packages from federated repositories.

### **Package Headers**

**Plugin:**

```php
/**
 * Plugin Name: My Plugin
 * Plugin ID: did:plc:ia6vk5krwkcka2nwuzs6l6lq
 * Version: 1.0.0
 */
```

**Theme:**

```css
/*
Theme Name: My Theme
Theme ID: did:plc:abcd1234dcba
*/
```

### **WordPress Hooks**

```
site_transient_update_plugins    # Update detection
site_transient_update_themes     # Update detection
plugins_api                      # API interception
themes_api                       # API interception
plugins_api_result               # Response modification
```

📚 **Source code:** [`https://github.com/fairpm/fair-plugin`](https://github.com/fairpm/fair-plugin)

---

## **🆔 DID Resolution**

### **DID Format**

```
did:plc:deoui6ztyx6paqajconl67rz   # PLC method (recommended)
did:web:example.com:plugins:foo    # Web method (current default)
```

**Current state:** Most packages in AspireCloud use did:web (domain-based). Three packages currently use `did:plc`:

* Git Updater (`did:plc:afjf7gsjzsqmgc7dlhb553mv`)
* Handbook Callout Blocks (`did:plc:deoui6ztyx6paqajconl67rz`)
* Pods (`did:plc:e3rm6t7cspgpzaf47kn3nnsl`)

The community is working toward did:plc as the standard for true package portability.

**Active development:** AspireCloud is building tooling to generate PLC DIDs for packages. See [Issue #377](https://github.com/aspirepress/AspireCloud/issues/377) for the current implementation work. This will enable automatic PLC DID generation during package ingestion.

**Help wanted:** FAIR's own packages (fair-plugin, mini-fair-repo) need PLC DIDs! Contributing to the PLC DID generation tooling or migrating existing packages are great ways to get involved. See [Issue #236](https://github.com/fairpm/fair-plugin/issues/236) if you want to contribute.

### **Resolution Steps**

1. **GET** `https://plc.directory/{did}` → DID Document
2. **Extract** `service[].serviceEndpoint` where `type="FairPackageManagementRepo"`
3. **GET** `{serviceEndpoint}` → Package Metadata

### **DID Document Structure**

```json
{
  "@context": ["https://www.w3.org/ns/did/v1"],
  "id": "did:plc:deoui6ztyx6paqajconl67rz",
  "verificationMethod": [{
    "id": "#fairpm",
    "type": "Multikey",
    "publicKeyMultibase": "zQ3sh..."
  }],
  "service": [{
    "type": "FairPackageManagementRepo",
    "serviceEndpoint": "https://repo.example.com/packages/did:plc:..."
  }]
}
```

**Caching:** 24-hour maximum, then revalidate

📚 **PLC specification:** [`https://github.com/did-method-plc/did-method-plc`](https://github.com/did-method-plc/did-method-plc)

---

## **🔐 Signature Verification**

### **Ed25519 Details**

* **Algorithm:** Ed25519 (128-bit security)
* **Hash:** SHA-384 of package ZIP
* **Signature:** 64 bytes, base64-encoded
* **Public Key:** 32 bytes, multibase-encoded (prefix 'z' = base58btc)

### **Verification Flow**

1. Hash package file with SHA-384
2. Decode base64 signature from metadata
3. Decode multibase public key from DID document
4. Verify: sodium_crypto_sign_verify_detached(signature, hash, publicKey)

### **Example Values**

**Signature:**

AcKSOVp2EHQCSWBO5LZCDv4puOpvJILsovIynQkf-hc...

**Public Key:**

zQ3shjiQmfcvNg5ExJuCcX8Bfzaa77y3yxD9iPMYmeRYbk4Vf

**Critical:** Public keys MUST come from DID document, never from metadata

📚 **Implementation:** [`https://github.com/fairpm/fair-plugin`](https://github.com/fairpm/fair-plugin) (crypto namespace)

---

## **📄 Package Metadata**

### **Document Structure**

```json
{
  "@context": "https://fair.pm/ns/metadata/v1",
  "id": "did:plc:deoui6ztyx6paqajconl67rz",
  "type": "wp-plugin",
  "name": "My Plugin",
  "slug": "my-plugin",
  "filename": "my-plugin/plugin.php",
  "description": "Plugin description",
  "authors": [{"name": "Author", "url": "https://..."}],
  "license": "GPL-2.0-or-later",
  "releases": [...]
}
```

### **Release Object**

```json
{
  "version": "1.0.3",
  "requires": {
    "env:php": ">=7.4",
    "env:wp": ">=5.9"
  },
  "artifacts": {
    "package": [{
      "url": "https://example.com/package.zip",
      "content-type": "application/octet-stream",
      "signature": "base64-signature",
      "checksum": "sha256:hexvalue"
    }],
    "icon": [{
      "url": "https://example.com/icon.svg",
      "content-type": "image/svg+xml",
      "height": 256,
      "width": 256
    }]
  }
}
```

### **Required Fields**

**Top-level:** `@context`, `id`, `type`, `name`, `slug`, `filename`, `authors`, `license`, `releases`

**Package artifact:** `url`, `content-type`, `signature`, `checksum`

### **Version Format**

* Semantic versioning: `MAJOR.MINOR.PATCH`
* Pre-release: `1.0.0~rc1` (tilde)
* Build metadata: `1.0.0^20241029` (caret, ignored in comparisons)

📚 **Full schema:** [`https://github.com/fairpm/fair-protocol/blob/main/specification.md`](https://github.com/fairpm/fair-protocol/blob/main/specification.md)

---

## **🌐 Repository REST API**

### **Endpoint Pattern**

GET {serviceEndpoint}/packages/{did}

**Mini-FAIR WordPress:**

GET /wp-json/minifair/v1/packages/{did}

### **Response**

Complete metadata document (see Package Metadata section above)

### **Requirements**

* ✅ HTTPS/TLS required (except local dev)
* ✅ Support `Accept: application/json`
* ✅ Return `Content-Type: application/json`
* ✅ Validate DID in request matches served package

### **Optional Features**

**Authentication (private packages):**

```
Authorization: Bearer <token>
```

**HAL links:**

```json
{
  "_links": {
    "https://fair.pm/rel/repo": {"href": "https://repo.example.com"},
    "collection": {"href": "https://repo.example.com/packages"}
  }
}
```

📚 **Mini-FAIR repo:** [`https://github.com/fairpm/mini-fair-repo`](https://github.com/fairpm/mini-fair-repo)

---

## **💡 Quick Reference**

### **Common Test Packages**

```
wordpress-seo       # Yoast SEO
contact-form-7      # Contact Form 7
woocommerce         # WooCommerce
```

### **HTTP Status Codes**

```
200  Success
404  Package not found
401  Authentication required
403  Not authorized
500  Repository error
```

### **PHP Version Comparison**

```php
version_compare('1.0.2', '1.0.3', '<')  // true (update available)
version_compare('1.0.3', '1.0.3', '=')  // true (current)
```

---

**Questions?** Check documentation at [`https://fair.pm`](https://fair.pm) or GitHub repositories listed above.
