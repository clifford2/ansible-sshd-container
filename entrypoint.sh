#!/usr/bin/env bash
# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>                                                                                 
# SPDX-License-Identifier: MIT-0

set -x

# Create user account
USER_NAME=${USER_NAME:-ansible}
echo "User name is set to $USER_NAME"
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create user on Alpine 3.22 / CentOS
# groupadd --gid $PGID $USER_NAME
# useradd --gid $PGID --create-home $USER_NAME
# Create user on Alpine 3.24
addgroup -g $PGID $USER_NAME
adduser -G $USER_NAME -u $PUID -D $USER_NAME

# Configure sudo
if [[ "$SUDO_ACCESS" == "true" ]]; then
	if [[ -n "$USER_PASSWORD" || (-n "$USER_PASSWORD_FILE" && -f "$USER_PASSWORD_FILE") ]]; then
		echo "${USER_NAME} ALL=(ALL) ALL" >> /etc/sudoers.d/${USER_NAME}
		echo "sudo is enabled with password."
	else
		echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${USER_NAME}
		echo "sudo is enabled without password."
	fi
else
	echo "sudo is disabled."
fi

# Set user password
if [[ -n "$USER_PASSWORD_FILE" ]] && [[ -f "$USER_PASSWORD_FILE" ]]; then
	USER_PASSWORD=$(cat "$USER_PASSWORD_FILE")
	echo "User password is retrieved from file."
fi
USER_PASSWORD=${USER_PASSWORD:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"${1:-8}";echo;)}
echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd
echo "User password set to ${USER_PASSWORD}"

# Configure SSHD
/usr/bin/ssh-keygen -A
SSH_LISTEN_PORT=${SSH_LISTEN_PORT:-2222}
sed -i "s/^#Port [[:digit:]]\+/Port ${SSH_LISTEN_PORT}"/ /etc/ssh/sshd_config
sed -i "s/^Port [[:digit:]]\+/Port ${SSH_LISTEN_PORT}"/ /etc/ssh/sshd_config
echo "sshd is listening on port ${SSH_LISTEN_PORT}"

# Password access
if [[ "$SSH_PASSWORD_ACCESS" == "true" ]]; then
	sed -i '/^#PasswordAuthentication/c\PasswordAuthentication yes' /etc/ssh/sshd_config
	sed -i '/^PasswordAuthentication/c\PasswordAuthentication yes' /etc/ssh/sshd_config
	chown root:"${USER_NAME}" /etc/shadow
	echo "User/password ssh access is enabled."
else
	sed -i '/^PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
	chown root:root /etc/shadow
	echo "User/password ssh access is disabled."
fi

# Set umask for sftp
SFTP_UMASK=${SFTP_UMASK:-022}
sed -i "s|/usr/lib/ssh/sftp-server$|/usr/lib/ssh/sftp-server -u ${SFTP_UMASK}|g" /etc/ssh/sshd_config

# Set key auth in file
test -d /home/${USER_NAME}/.ssh || mkdir -p /home/${USER_NAME}/.ssh
if [[ ! -f /home/${USER_NAME}/.ssh/authorized_keys ]]; then
	touch /home/${USER_NAME}/.ssh/authorized_keys
fi

echo "SSH_PUBLIC_KEY=[${SSH_PUBLIC_KEY}]"
if [[ -n "$SSH_PUBLIC_KEY" ]]; then
	if ! grep -q "${SSH_PUBLIC_KEY}" /home/${USER_NAME}/.ssh/authorized_keys; then
		echo "$SSH_PUBLIC_KEY" >> /home/${USER_NAME}/.ssh/authorized_keys
		echo "Public key from env variable added"
	fi
fi

if [[ -n "$SSH_PUBLIC_KEY_URL" ]]; then
	SSH_PUBLIC_KEY_DOWNLOADED=$(curl -Ls "$SSH_PUBLIC_KEY_URL")
	if ! grep -q "$SSH_PUBLIC_KEY_DOWNLOADED" /home/${USER_NAME}/.ssh/authorized_keys; then
		echo "$SSH_PUBLIC_KEY_DOWNLOADED" >> /home/${USER_NAME}/.ssh/authorized_keys
		echo "Public key downloaded from '$SSH_PUBLIC_KEY_URL' added"
	fi
fi

if [[ -n "$SSH_PUBLIC_KEY_FILE" ]] && [[ -f "$SSH_PUBLIC_KEY_FILE" ]]; then
	SSH_PUBLIC_KEY2=$(cat "$SSH_PUBLIC_KEY_FILE")
	if ! grep -q "$SSH_PUBLIC_KEY2" /home/${USER_NAME}/.ssh/authorized_keys; then
		echo "$SSH_PUBLIC_KEY2" >> /home/${USER_NAME}/.ssh/authorized_keys
		echo "Public key from file added"
	fi
fi

if [[ -d "$SSH_PUBLIC_KEY_DIR" ]]; then
	for F in "${SSH_PUBLIC_KEY_DIR}"/*; do
		SSH_PUBLIC_KEYN=$(cat "$F")
		if ! grep -q "$SSH_PUBLIC_KEYN" /home/${USER_NAME}/.ssh/authorized_keys; then
			echo "$SSH_PUBLIC_KEYN" >> /home/${USER_NAME}/.ssh/authorized_keys
			echo "Public key from file '$F' added"
		fi
	done
fi

# Permissions
chown -R "${USER_NAME}":"${USER_NAME}" /home/${USER_NAME}
chmod go-w /home/${USER_NAME}
chmod 700 /home/${USER_NAME}/.ssh
chmod 600 /home/${USER_NAME}/.ssh/authorized_keys

if [ $$ -eq 1 ]
then
	exec /usr/sbin/sshd -D
fi

exit 0
