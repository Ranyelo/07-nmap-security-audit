#!/bin/bash

# Script de automatizacion para escaneo de puertos con Nmap
# Genera reportes en HTML para auditoria perimetral

TARGETS_FILE="targets/servidores.txt"
REPORTS_DIR="reports"

# Verificar que exista el archivo de objetivos
if [ ! -f "$TARGETS_FILE" ]; then
    echo "[-] Error: El archivo de objetivos '$TARGETS_FILE' no existe."
    exit 1
fi

# Verificar instalacion de Nmap
if ! command -v nmap &> /dev/null; then
    echo "[-] Error: Nmap no esta instalado en este sistema."
    exit 1
fi

mkdir -p "$REPORTS_DIR"

mostrar_ayuda() {
    echo "Uso: $0 [tcp|udp]"
    echo "  tcp : Ejecuta escaneo TCP rapido con deteccion de versiones y genera reporte"
    echo "  udp : Ejecuta escaneo UDP de puertos comunes y genera reporte"
    exit 1
}

if [ -z "$1" ]; then
    mostrar_ayuda
fi

MODO=$1
TEMP_XML="$REPORTS_DIR/temp_scan.xml"

if [ "$MODO" == "tcp" ]; then
    echo "[+] Iniciando escaneo TCP de puertos comunes..."
    nmap -sV -F -oX "$TEMP_XML" -iL "$TARGETS_FILE"
    OUTPUT_HTML="$REPORTS_DIR/reporte-10-servidores.html"
elif [ "$MODO" == "udp" ]; then
    echo "[+] Iniciando escaneo UDP (Puertos mas comunes)..."
    # Escaneo UDP requiere privilegios de root/administrador
    sudo nmap -sU -F -oX "$TEMP_XML" -iL "$TARGETS_FILE"
    OUTPUT_HTML="$REPORTS_DIR/escaneo-udp.html"
else
    mostrar_ayuda
fi

if [ $? -ne 0 ]; then
    echo "[-] Fallo la ejecucion del comando Nmap."
    exit 1
fi

# Convertir el XML temporal a HTML si xsltproc esta disponible
if command -v xsltproc &> /dev/null; then
    echo "[+] Convirtiendo resultados a reporte HTML..."
    xsltproc "$TEMP_XML" -o "$OUTPUT_HTML"
    echo "[+] Reporte final generado en: $OUTPUT_HTML"
    rm -f "$TEMP_XML"
else
    echo "[!] Advertencia: xsltproc no esta instalado. Resultados guardados en: $TEMP_XML"
fi
