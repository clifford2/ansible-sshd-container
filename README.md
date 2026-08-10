# Container Image with SSHD

## About

A very basic container image, running SSHD.

This was created for an Ansible Automation Platform (AAP) demonstration, to
use as quick / lightweight Ansible managed systems, where multiple managed
systems where required to test various inventory & RBAC scenarios.

This image is built on [Alpine Linux](https://www.alpinelinux.org/),
and runs SSHD in PID 1.

A version that is built on CentOS Stream 10, which runs systemd, is
available in the `centos` directory, but it doesn't support `sudo` yet.

For **local** testing (without AAP), the
[Molecule](https://docs.ansible.com/projects/molecule/) testing
framework offers more flexibility.
See <https://github.com/clifford2/molecule-containers> for examples.

## Build

Build with:

```sh
make build
```

## Configuration

The container can be configured by passing the following environment variables:

- `USER_NAME`: user name (default: `ansible`)
- `PUID`: User UID (default: 1000)
- `PGID`: User GID (default: 1000)
- `SUDO_ACCESS="true"`: enable `sudo` access for `$USER_NAME`
- `USER_PASSWORD_FILE`: file containing password
- `USER_PASSWORD`: plain text password (default: random)
- `SSH_LISTEN_PORT`: Port for SSHD to listen on (default: 2222)
- `SFTP_UMASK`: umask for SFTP (default: 022)
- `SSH_PASSWORD_ACCESS="true"`: Allow PasswordAuthentication
- `SSH_PUBLIC_KEY`: Add this SSH public key to `authorized_keys`
- `SSH_PUBLIC_KEY_URL`: Add SSH public key from this URL to `authorized_keys`
- `SSH_PUBLIC_KEY_FILE`: Add SSH public key from this file to `authorized_keys`
- `SSH_PUBLIC_KEY_DIR`: Add all files from this directory to SSH `authorized_keys`

## Run

Run with:

```sh
podman run --rm -d --replace \
  --name aap-demo-sshd \
  --hostname aap-demo-sshd \
  -e TZ=Africa/Johannesburg \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  -e SUDO_ACCESS=true \
  -e SSH_LISTEN_PORT=2943 \
  --network=host \
  localhost/aap-demo-sshd:$(cat .version)
```

Test with:

```sh
# ssh client
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2943 ansible@127.0.0.1
# ansible
ansible -i localhost, -e ansible_ssh_port=2943 -e ansible_user=ansible all -a id -b
```

## Ansible Example

The [`examples/`](examples) directory contains some sample code, including:

- `create-containers-playbook.yml`: A playbook for creating some containers
- `vars/managed-systems.yml`: A list of containers to create
- `inventory.yml`: An Ansible inventory for targeting those containers
	- Test with: `ansible -i inventory.yml democontainers -m ping`


## License & Disclaimer

This code is shared under the MIT No Attribution License.
It is provided *AS IS*, without warranty of any kind.
See [`LICENSES/MIT-0.txt`](LICENSES/MIT-0.txt) for the full license text and disclaimer.
