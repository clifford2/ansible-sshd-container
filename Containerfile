# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

FROM docker.io/library/alpine:3.24.3

RUN apk update && apk add --no-cache bash openssh rsync augeas shadow sudo acl python3

# rssh package:
#   Restricted shell for use with OpenSSH, allowing only scp, sftp, and/or rsync
#   Not available in Alpine > 3.22
# RUN apk update && apk add --no-cache rssh

RUN echo 'LogLevel VERBOSE' > /etc/ssh/sshd_config.d/00-loglevel.conf
# 2026-11-05: mitigate openssh-server password authentication bypass
# https://alpinelinux.org/posts/2026-11-05-openssh-password-authentication-bypass/
RUN echo 'PasswordAuthentication no' > /etc/ssh/sshd_config.d/01-passwordauth.conf

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
