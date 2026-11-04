#!/bin/bash
dnf update -y
dnf install httpd -y

mkdir -p /var/www/html

cat <<'EOF' > /var/www/html/index.html
${index_content}
EOF

Apply SELinux contexts for Apache (httpd_sys_content_t)
restorecon -Rv /var/www/html

systemctl enable --now httpd