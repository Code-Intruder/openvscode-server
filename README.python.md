# OpenVSCode Server con Python

Esta imagen extiende la imagen base de OpenVSCode Server y agrega:
- **Python 3** (última versión disponible en Debian)
- **pip** (gestor de paquetes de Python)
- **Extensión de Python** para VSCode (ms-python.python)
- **Pylance** (language server de Python)
- **Debugpy** (debugger de Python)

## 🏗️ Construcción

### 1. Construir la imagen base primero
```bash
docker build -t ghcr.io/code-intruder/openvscode-server:latest -f Dockerfile .
```

### 2. Construir la imagen con Python
```bash
docker build -t ghcr.io/code-intruder/openvscode-server:python -f Dockerfile.python .
```

## 🚀 Uso

### Ejecución básica
```bash
docker run -d \
  --name openvscode-python \
  -p 3000:3000 \
  -v $(pwd)/workspace:/home/openvscode/workspace \
  ghcr.io/code-intruder/openvscode-server:python
```

### Con Docker Compose
```bash
docker-compose -f docker-compose.python.yml up -d
```

### Acceder al servidor
Abre tu navegador en: `http://localhost:3000`

## 📦 Software Pre-instalado

La imagen incluye:
- `python3` - Intérprete de Python 3
- `pip3` - Gestor de paquetes
- `python3-venv` - Soporte para entornos virtuales
- `python3-dev` - Headers de desarrollo
- `build-essential` - Compiladores para paquetes nativos

## 🔌 Extensión de Python Pre-instalada

La extensión de Python (**ms-python.python**) viene **pre-instalada** en la imagen, lista para usar:

✅ IntelliSense y autocompletado
✅ Debugging integrado
✅ Linting y formateo
✅ Soporte para entornos virtuales

No necesitas instalar nada adicional para empezar a desarrollar en Python.

## 🔧 Instalar paquetes Python adicionales

### Desde el terminal integrado de VSCode
```bash
pip install pandas numpy matplotlib scikit-learn
```

### Con requirements.txt
```bash
pip install -r requirements.txt
```

### Con entorno virtual (recomendado)
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 🎯 Características

✅ Python 3 instalado y configurado
✅ pip y entornos virtuales
✅ Compiladores para paquetes nativos
✅ **Extensión de Python pre-instalada**
✅ IntelliSense y autocompletado
✅ Debugging integrado
✅ Linting y formateo de código
✅ Soporte para Jupyter Notebooks (instala extensión adicional si lo necesitas)

## 📝 Ejemplos de uso

### 1. Crear un script Python
```python
# hello.py
def greet(name):
    return f"¡Hola, {name}!"

if __name__ == "__main__":
    print(greet("Mundo"))
```

### 2. Ejecutar el script
Desde el terminal integrado:
```bash
python hello.py
```

### 3. Debugging
- Coloca un breakpoint en tu código (click en el margen izquierdo)
- Presiona F5 o usa el panel de Debug
- Selecciona "Python File" como configuración

## 🔐 Seguridad

### Producción con token
```bash
docker run -d \
  --name openvscode-python \
  -p 3000:3000 \
  -e CONNECTION_TOKEN="tu-token-secreto-aqui" \
  -v $(pwd)/workspace:/home/openvscode/workspace \
  ghcr.io/code-intruder/openvscode-server:python \
  node /opt/openvscode-server/out/server-main.js \
    --host 0.0.0.0 \
    --port 3000 \
    --connection-token "tu-token-secreto-aqui"
```

## 🐛 Troubleshooting

### La extensión de Python no aparece
```bash
# Verificar que la extensión está instalada
docker exec openvscode-python ls /home/openvscode/.openvscode-server/extensions/
```

### Python no se encuentra
```bash
# Verificar versión de Python
docker exec openvscode-python python --version
docker exec openvscode-python pip --version
```

### Reinstalar la extensión
```bash
docker exec -u openvscode openvscode-python \
  /opt/openvscode-server/bin/openvscode-server \
  --install-extension ms-python.python \
  --extensions-dir /home/openvscode/.openvscode-server/extensions
```

## 📚 Recursos adicionales

- [Documentación oficial de Python](https://docs.python.org/3/)
- [Extensión de Python para VSCode](https://marketplace.visualstudio.com/items?itemName=ms-python.python)
- [OpenVSCode Server](https://github.com/gitpod-io/openvscode-server)

