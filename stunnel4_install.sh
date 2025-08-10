# Instalar e configurar STunnel
echo "Instalando STunnel..."
apt install -y stunnel4 openssl || { echo "Falha ao instalar stunnel4 e openssl"; exit 1; }

echo "Gerando certificados autoassinados..."
mkdir -p /etc/stunnel
if [ ! -f /etc/stunnel/cert.pem ] || [ ! -f /etc/stunnel/key.pem ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/stunnel/key.pem -out /etc/stunnel/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost" || { echo "Erro ao gerar certificados"; exit 1; }
    chmod 600 /etc/stunnel/cert.pem /etc/stunnel/key.pem
else
    echo "Certificados já existem, pulando geração..."
fi

echo "Criando configuração do STunnel..."
cat > /etc/stunnel/stunnel.conf << 'EOF'
cert = /etc/stunnel/cert.pem
key = /etc/stunnel/key.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
sslVersion = all

[stunnel Port 443]
connect = 0.0.0.0:22
accept = 443
EOF

chmod 600 /etc/stunnel/stunnel.conf

# Habilitar e iniciar o serviço
if [ -f /etc/default/stunnel4 ]; then
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
else
    echo "Arquivo /etc/default/stunnel4 não encontrado"; exit 1
fi

systemctl enable stunnel4
systemctl restart stunnel4

if ! systemctl is-active --quiet stunnel4; then
    echo "Erro: STunnel não está ativo. Verifique com: journalctl -u stunnel4"; exit 1
fi

echo "STunnel instalado e configurado com sucesso."
