# ============================================================================
# OpenVSCode Server with PHP + PHP Extension
# ============================================================================
# Este Dockerfile extiende la imagen base de openvscode-server y agrega:
# - PHP (última versión disponible)
# - Composer (gestor de paquetes de PHP)
# - Extensiones comunes de PHP (mbstring, xml, curl, zip, etc.)
# - Extensión de PHP para VSCode pre-instalada
# ============================================================================

FROM ghcr.io/code-intruder/openvscode-server:latest

# Cambiar a root para instalar paquetes del sistema
USER root

# Instalar PHP, Composer y extensiones comunes de PHP
RUN apt-get update && apt-get install -y --no-install-recommends \
    php \
    php-cli \
    php-fpm \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-gd \
    php-mysql \
    php-pgsql \
    php-sqlite3 \
    php-intl \
    php-bcmath \
    php-opcache \
    php-readline \
    git \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalar Composer globalmente
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer \
    && chmod +x /usr/local/bin/composer

# Cambiar al usuario openvscode
USER openvscode

# Variables de entorno para PHP
ENV COMPOSER_HOME=/home/openvscode/.composer \
    COMPOSER_CACHE_DIR=/home/openvscode/.composer/cache

# Crear directorio de Composer
RUN mkdir -p /home/openvscode/.composer/cache

# Verificar instalaciones
RUN php --version && \
    composer --version && \
    echo "✓ PHP y Composer instalados correctamente"

# Exponer puerto
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/healthz || curl -f http://localhost:3000/ || exit 1

# Workspace por defecto
WORKDIR /home/openvscode/workspace

# Instalar extensión de PHP pre-incrustada
# Intelephense es una de las extensiones más populares para PHP en VSCode
RUN node /opt/openvscode-server/out/server-main.js --install-extension bmewburn.vscode-intelephense-client
RUN node /opt/openvscode-server/out/server-main.js --install-extension laravel.vscode-laravel

# Comando por defecto (hereda del base)
# CMD ya está definido en la imagen base
