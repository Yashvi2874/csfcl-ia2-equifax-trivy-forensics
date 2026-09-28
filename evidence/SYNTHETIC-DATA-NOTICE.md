# Synthetic data notice

Everything under acis-portal/ except the Struts library is invented for
coursework.

- lib/struts2-core-2.5.10.jar is the genuine Apache release from Maven Central.
  Its SHA-1, 070e02e901924a40097b847cff4066c15d3a684b, matches the one Maven
  Central publishes.
- Every password, key, token and host name in config/ and the Dockerfile is made
  up. The AWS keys in config/aws-credentials follow the real format but belong to
  no account. The key in the Dockerfile is Amazon's own documentation example,
  AKIAIOSFODNN7EXAMPLE.
- pom.xml lists libraries at versions released before March 2017.
- There is no exploit code anywhere in this repository, and nothing in the
  evidence is ever run.

No real Equifax system, customer record or credential appears here. The setup
follows the failures described in GAO-18-559 and in the US House Committee on
Oversight and Government Reform report on the Equifax breach, December 2018.
