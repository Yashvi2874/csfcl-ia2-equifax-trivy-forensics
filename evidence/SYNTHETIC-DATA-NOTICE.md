# Synthetic Data Notice

Every credential, key, hostname and log entry in `evidence/` is **fabricated for
academic use**. Specifically:

- AWS keys use Amazon's own published documentation examples, which are
  non-functional by design.
- Database passwords, tokens and private keys are invented strings.
- Log entries are synthesised to model the documented Equifax attack pattern.
- No real Equifax system, customer record or credential appears anywhere here.

The exploit payload in `logs/access.log` is **defanged** - the command portion is
redacted so the file cannot be copied and used as a working attack.

This directory models the failures described in the US Government Accountability
Office report GAO-18-559 and the US House Committee on Oversight and Government
Reform report on the Equifax breach (December 2018).
