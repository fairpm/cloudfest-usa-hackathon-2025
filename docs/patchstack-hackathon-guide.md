# 🧩 Patchstack Hackathon API Guide

**CloudFest USA – November 4, 2025**
📍 Miami Marriott Biscayne Bay
👥 20–25 Selected Participants
🔗 https://www.cloudfest.com/usa/hackathon/

## 🎯 Overview

Welcome to the Inaugural Cloudfest Hackathon in Miami sponsored by Patchstack!

This guide explains how to access and test the Vulnerability Import API using a temporary Sysadmin API token.
You'll use this API to import or test WordPress plugin and theme vulnerabilities directly via Postman or cURL.

## ⚙️ Purpose

This temporary API token lets you fetch plugin vulnerability data during the hackathon. No Patchstack developer account or credit card required.
The endpoint is sandboxed, rate-limited, and will be disabled after the conference.

## 🔐 Postman
Postman File to Download
You can download the above Postman collection to use the API straight away. It includes an example payload. Edit the Body tab to edit the payload.
All attendees will use a shared temporary Sysadmin API Token with limited scope and rate limits.

## 🪄 How to Use the Token

Open your API tool (e.g. Postman, Insomnia, or cURL).
Set the base URL to:

```
https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon
```

In your headers, include:

| Header | Value |
|--------|-------|
| Content-Type | application/json |
| Accept | application/json |
| Authorization | Bearer <your provided API token> |

Provide a JSON payload in the request body (see below).
If in doubt, use the Postman File above.

## 💻 Example Request (cURL)

```bash
curl --location 'https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header 'Authorization: Bearer aapi_CN2ZAQdQBC72RXBKqpO5BnAscEGuDyBqxrd0icqlO3NkWfENSlkk1sGv4xq9kbBv' \
--header 'Cookie: XSRF-TOKEN=eyJpdiI6IjFHNnRNaStSQ1dWV3VnaWJoaHU4RFE9PSIsInZhbHVlIjoiY3BxZXVrWXhrajBvQnhpS3VVZHZWc1czSUl1dnpUWG4xN2RjZ21HbkZERHQ5MHc5akZjcWV5b3BnVDFWVllZR0hwUlQ0Qkx0NW9KamlSS1dNUUhoWk0vSWFpQkQ1QzVwK2k2djU3K2IrSk0rc1VUY0srWGt3cURrQXNLS3QvSlEiLCJtYWMiOiJlMTU2MDU2ZGFmMTliNjNmNzQ2MjhhN2NhMGFlMmIxMzlhNTUyZjVhODliMDE2MWNkNGMwZTRmNjAxYWJhYjRhIiwidGFnIjoiIn0%3D; hub_session=eyJpdiI6IkpYY2hZUHowU3FpdUpULzZYaml1Qnc9PSIsInZhbHVlIjoiUS95ZE1HT3ZrcnBhYzRvVHF6cHErVE92N3BKWDA2TWRVbC9JRS9PUE54SlAycFFqU2ZRaVZKTHBUOHdEc0J6SFNicmNXSU9ZOVhJK3BmN056WXc1cE4zbi8wdEJQWStnSjFiRkhDKytNUitGMUpDUTM1eTkzWnF3c3djak8ycWciLCJtYWMiOiIwMDQ3NTU3MGUyYTM4NGEyMGY0NTlkNzdiMGFjZWU3OGQ5YzUwMjk3ZjE3ZDAwMWVjOGMzOWJiMmE4YWZlODA1IiwidGFnIjoiIn0%3D' \
--data '[
  {
    "type": "plugin",
    "name": "woocommerce",
    "version": "1.0.0",
    "exists": false
  },
  {
    "type": "plugin",
    "name": "fmoblog",
    "version": "1.0.0",
    "exists": false
  }
]'
```

## 📬 Response (condensed, developer-friendly)

The full response lists vulnerabilities grouped by product slug. Below is a trimmed example showing the most useful fields for each item.

```json
{
	"vulnerabilities": {
		"woocommerce": [
			{
				"title": "Absolute Path Traversal",
				"vuln_type": "Local File Inclusion",
				"affected_in": "<= 1.3",
				"fixed_in": "1.4",
				"cvss_score": 5.3,
				"cve": ["2015-5065"],
				"disclosed_at": "2015-06-24T00:00:00Z",
				"is_exploited": false,
				"direct_url": "https://vdp-api.patchstack.com/vulnerability/woocommerce/wordpress-woocommerce-plugin-1-3-absolute-path-traversal?_a_id=u"
			},
			{
				"title": "XSS",
				"vuln_type": "Cross Site Scripting (XSS)",
				"affected_in": "<= 2.2.10",
				"fixed_in": "2.2.11",
				"cvss_score": 6.1,
				"cve": ["2015-2069"],
				"disclosed_at": "2015-02-24T00:00:00Z",
				"is_exploited": false,
				"direct_url": "https://vdp-api.patchstack.com/vulnerability/woocommerce/wordpress-woocommerce-plugin-2-2-10-xss?_a_id=u"
			},
			{
				"title": "SQL Injection",
				"vuln_type": "SQL Injection",
				"affected_in": "<= 5.5.0",
				"fixed_in": "5.5.1",
				"cvss_score": 8.2,
				"cve": [],
				"disclosed_at": "2021-07-15T00:00:00Z",
				"is_exploited": true,
				"direct_url": "https://vdp-api.patchstack.com/vulnerability/woocommerce/wordpress-woocommerce-plugin-5-5-0-sql-injection-sqli-vulnerability?_a_id=u"
			}
			// ...more entries
		],
		"fmoblog": [
			{
				"title": "SQL Injection",
				"vuln_type": "SQL Injection",
				"affected_in": "<= 2.1",
				"fixed_in": "2.2",
				"cvss_score": 9.3,
				"cve": ["2009-0968"],
				"disclosed_at": "2009-03-17T00:00:00Z",
				"is_exploited": false,
				"direct_url": "https://vdp-api.patchstack.com/vulnerability/fmoblog/wordpress-plugin-fmoblog-2-1-sql-injection-vulnerability?_a_id=u"
			}
		]
	}
}
```

The above is representative—the real response may include many more items. Keep the structure but trim fields for readability in the docs.

## 📦 Example Response Schema

```typescript
interface VulnerabilityItem {
	title: string; // Human-readable name
	vuln_type: string; // Category (XSS, SQLi, LFI, etc.)
	affected_in: string; // Version range affected
	fixed_in: string | null; // First fixed version (if available)
	cvss_score: number | null; // CVSS base score
	cve: string[]; // CVE identifiers (may be empty)
	disclosed_at: string; // ISO date of public disclosure
	is_exploited: boolean; // Known exploitation in the wild
	direct_url: string; // Deep link to Patchstack advisory
}

interface ApiResponse {
	vulnerabilities: Record<string /* product_slug */, VulnerabilityItem[]>;
}
```

## 📦 Required JSON Fields

| Field | Type | Description |
|-------|------|-------------|
| type | string | "plugin" or "theme" |
| name | string | The name of the WordPress component |
| version | string | Version string (e.g. "1.0.0") |
| exists | boolean | Set to false if the component doesn't exist yet |

## 🧪 Example Request (Postman)

*example response also provided at the end of the document

Step-by-step:

1. Create a new POST request.
2. Enter this URL:

```
https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon
```

3. Under Headers, add:
   - Content-Type: application/json
   - Accept: application/json
   - Authorization: Bearer <your provided API token>

4. In the Body, choose raw → JSON and paste:

```json
[
  {
    "type": "plugin",
    "name": "my-sample-plugin",
    "version": "1.2.3",
    "exists": false
  }
]
```

5. Click Send and verify that you receive a success response.

Example Response

## 🧱 API Notes

* You can submit multiple entries in a single request (array of objects).
* The endpoint automatically creates vulnerability records in a sandbox environment.
* API not rate limited for the hackathon - please cache and do not abuse the API.
* The token will be revoked post-conference.
* We will review api options internally at Patchstack for post-hackathon based on feedback.

## 🧩 Need Help?

* Check the example video (Screen Recording 2025-10-27 at 14.19.54.mov) if you need a visual walkthrough.
* Ask event facilitators for assistance during the session.

## 🧭 After the Hackathon

After CloudFest, we'll disable the temporary token and review participant feedback.
The long-term goal is to introduce a simple key-request endpoint allowing temporary API access via email.

## Thank You for Participating!

Your contributions help improve the open-source security ecosystem and strengthen the FAIR (Free and Independent Researchers) community.

— Patchstack Team

