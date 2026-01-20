# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please email the maintainers or create a private security advisory on GitHub (preferred).

**Please do not create public issues for security vulnerabilities.**

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | ✅        |
| Older   | ❌        |

## Security Considerations

### Solution 1 (Native Chrome)

**Secure by design:**
- Chrome runs with `--no-sandbox` (required for WSL, safe in this context)
- Remote debugging bound to `localhost` only (127.0.0.1)
- No network exposure
- All scripts are auditable bash

**Potential risks:**
- If malware is already in your WSL, it can access CDP port
- **Mitigation:** Standard WSL security practices

### Solution 2 (Windows Bridge)

**Secure by design:**
- Python proxy binds to `0.0.0.0` (required for WSL access)
- Still only accessible from WSL (Windows firewall protects from external)
- No data logging or external connections
- Fully auditable Python code

**Potential risks:**
- Port 9223 technically accessible from LAN if firewall disabled
- **Mitigation:** Keep Windows Firewall enabled

## Best Practices

1. **Don't expose :9222 to the network**
   - Both solutions bind to localhost/WSL only
   - Don't forward ports externally

2. **Keep Chrome updated**
   ```bash
   sudo apt update && sudo apt upgrade google-chrome-stable
   ```

3. **Audit the code**
   - All scripts are plain text
   - Review before running
   - Check for updates regularly

4. **Use in development only**
   - Not designed for production environments
   - Use cloud browser automation for production

5. **Monitor processes**
   ```bash
   # Check what's running
   ps aux | grep chrome
   ps aux | grep python
   ps aux | grep socat
   ```

## Known Limitations

- CDP access allows full browser control (by design)
- No authentication on :9222 (standard for local development)
- Chrome profile accessible to any WSL process

These are **intentional** for local development use cases.

## Response Timeline

- **Critical vulnerabilities:** 24-48 hours
- **High severity:** 1 week
- **Medium/Low:** Best effort

## Updates

Security updates will be released as soon as possible and announced via:
- GitHub Releases
- Security Advisories
- README updates

---

**Remember:** This is a **development tool**. Don't use in production or expose to untrusted networks.
