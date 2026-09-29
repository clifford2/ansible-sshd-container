# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

FROM docker.io/library/alpine:3.24.1

RUN apk update && apk add --no-cache bash openssh rsync augeas shadow sudo acl python3

# rssh package:
#   Restricted shell for use with OpenSSH, allowing only scp, sftp, and/or rsync
#   Not available in Alpine > 3.22
# RUN apk update && apk add --no-cache rssh

# Fix CVE-2026-14456
# RUN apk add --no-cache libcrypto3=3.5.8-r0
# Fix CVE-2026-76956 & CVE-2026-76957
# RUN apk add --no-cache libexpat=2.8.4-r0
# Fix CVE-2026-14456
# RUN apk add --no-cache libssl3=3.5.8-r0
# Fix CVE-2026-60002, CVE-2026-59999 & CVE-2026-60000
# RUN apk add --no-cache openssh=10.3_p1-r1 openssh-client-common=10.3_p1-r1 openssh-client-default=10.3_p1-r1 openssh-keygen=10.3_p1-r1 openssh-server=10.3_p1-r1 openssh-server-common=10.3_p1-r1 openssh-sftp-server=10.3_p1-r1
# Fix numerous CVEs
# RUN apk add --no-cache rsync=3.5.0-r0
# Fix CVE-2026-11940, CVE-2026-15308 & CVE-2026-7210
# RUN apk add --no-cache pyc=3.14.7-r1 python3=3.14.7-r1 python3-pyc=3.14.7-r1 python3-pycache-pyc0=3.14.7-r1
# Optimize execution
RUN apk add --no-cache libcrypto3=3.5.8-r0 libexpat=2.8.4-r0 libssl3=3.5.8-r0 openssh=10.3_p1-r1 openssh-client-common=10.3_p1-r1 openssh-client-default=10.3_p1-r1 openssh-keygen=10.3_p1-r1 openssh-server=10.3_p1-r1 openssh-server-common=10.3_p1-r1 openssh-sftp-server=10.3_p1-r1 rsync=3.5.0-r0 pyc=3.14.7-r1 python3=3.14.7-r1 python3-pyc=3.14.7-r1 python3-pycache-pyc0=3.14.7-r1

RUN echo 'LogLevel VERBOSE' >> /etc/ssh/sshd_config

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
