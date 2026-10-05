# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Vulnerability Reporting

### Osborne 1 Security Context

**Important Security Notice:**

This software runs on the Osborne 1 personal computer, manufactured in 1981. Due to the hardware's inherent design limitations, we can confidently state the following:

#### Network Security
- **No Network Connectivity**: The Osborne 1 predates the internet and has no networking capabilities
- **No Remote Code Execution**: Attackers cannot remotely execute code on a machine that doesn't have a network interface
- **No Wireless Vulnerabilities**: No WiFi, Bluetooth, or cellular connectivity means no wireless attack vectors
- **No Cloud Integration**: The only "cloud" this machine encounters is the one outside your window

#### Physical Security
- **Air Gap Protection**: The Osborne 1 provides natural air gap security by design (especially with the keyboard clipped shut!)
- **No USB Ports**: No USB means no malicious flash drives (though we do have 5.25" floppy drives, in an oddball format that is a serious pain to work with)
- **No External Storage**: Besides floppy disks, which require physical access and a working drive from 1981, but that's a tempting little project isn't it... IEEE-488 Hard Drive based on a rPi Pico?

### Reporting Vulnerabilities

If you discover a security vulnerability in this software, please report it by:

1. Writing it on a piece of paper
2. Placing it in an envelope
3. Mailing it via postal service to the maintainer
4. Waiting 3-5 business days for delivery

**Note**: Email reporting is not recommended as the Osborne 1 predates commonly available consumer Internet email by approximately 15 years.

### Known Security Considerations

#### Floppy Disk Security
- **Virus Protection**: The only "viruses" this machine encounters are biological ones, please wash your hands before touching the keyboard
- **Malware Defense**: Um... yeah. Naw. We don't have this for modern computers, why would we have it for 45 year old machines? 
- **Data Encryption**: All data is stored in plain text or really easy to reverse binary formats on 91 or 182KB floppy disks

#### Hardware Security
- **Memory Protection**: The 64KB of RAM is too small for any serious security exploits
- **Processor Security**: The Z80 processor has no known vulnerabilities (it's too old to be interesting)
- **Boot Security**: The machine boots directly into CP/M 2.2 with no secure boot requirements

### Security Best Practices

For maximum security when using this software:

1. **Keep your floppy disks in a dry place** - moisture is the real threat
2. **Store the machine away from magnetic fields** - your data is magnetic, after all
3. **Use a surge protector** - vintage electronics are delicate
4. **Back up your presentations** - not because of hackers, but because floppy disks degrade over time
5. **Keep the machine clean** - dust is more dangerous than any cyber threat
6. **RIFA = BAD** - You did replace the RIFA caps in the power supply - right?

### Incident Response

In the unlikely event of a security incident:

1. **Power down the machine** - this solves most problems
2. **Remove all floppy disks** - isolate the "threat"
3. **Wait 30 seconds** - then power back on
4. **Contact technical support** - via telephone or in person (no remote support available)

### Security Testing

We do not perform regular security audits because:
- There are no automated security scanning tools for CP/M 2.2
- The machine's age provides natural security through obscurity
- Any potential attacker would need to be physically present with a working Osborne 1

### Compliance

This software is compliant with all relevant security standards from 1981, including:
- **CP/M 2.2 Security Guidelines** (the only standard that existed)
- **Z80 Processor Security Best Practices**
- **5.25" Floppy Disk Security Protocols**

(Note: None of these exist, but can represent a fun creative writing project - submit a PR!)

## Contact

For security-related inquiries, please contact us using one of the following methods:

- **Postal Mail**: Oh Hell No.
- **Telephone**: I no longer answer the phone, too many years of CISO life.
- **In Person**: Hi, I'm Jamie - we met at a security conference - right?
- **Carrier Pigeon**: RFC1149 formatted messages only please

**Note**: We do not accept security reports via email, social media, or any electronic means, as the target platform predates these technologies.

---

*This security policy is intentionally humorous and reflects the reality that a 45-year-old computer with no networking capabilities poses minimal security risks in the modern threat landscape.*
