"""Verifica la pausa interactiva sin iniciar descargas ni instalaciones."""
import os
import pty
import select
import subprocess
import time
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text().strip().encode()
perfil_guardado = root / ".xdg" / "perfil-alumno"
perfil_previo = perfil_guardado.read_bytes() if perfil_guardado.exists() else None


def leer_hasta(master, output, marca):
    deadline = time.monotonic() + 5
    while marca not in output and time.monotonic() < deadline:
        if select.select([master], [], [], 0.1)[0]:
            output += os.read(master, 65536)
    assert marca in output, (marca, output)
    return output


def ejecutar(script, args, pasos):
    """pasos: lista de (marca esperada, texto a escribir)."""
    master, slave = pty.openpty()
    proc = subprocess.Popen(["sh", str(root / "scripts" / script), *args],
                            stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output = b""
    try:
        for marca, texto in pasos:
            output = leer_hasta(master, output, marca)
            os.write(master, texto)
        assert proc.wait(timeout=5) == 0, output
    finally:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=5)
        os.close(master)
    return output


output = ejecutar("instalar.sh", [], [(b"Pulse Enter", b"cancelar\n")])
assert b"v" + version in output
assert b"ANTES DE COMENZAR" in output
assert b"ELIJA LA FORMA DE INSTALAR" in output
assert b"CON --sistema" in output
assert b"Git, tmux" in output
assert b"MODO LOCAL" in output
assert b"no autoriza sudo" in output
print("OK: versión, plan y pausa; cancelación sin instalar: instalar.sh")

# Sin opciones: menú de perfil, respuesta no válida, elección y plan.
output = ejecutar("instalar-alumno.sh", [], [
    (b"Escribe 1 o 2", b"x\n"),
    (b"Respuesta no v", b"2\n"),
    (b"Pulsa Enter", b"cancelar\n"),
])
assert b"v" + version in output
assert b"1) DWEC" in output and b"2) SI" in output
assert b"Perfil: SI" in output
assert b"QU\xc3\x89 VA A PASAR" in output
assert b"se te preguntar\xc3\xa1 antes de instalarlo" in output
print("OK: menú de perfil y cancelación sin instalar: instalar-alumno.sh")

# Con --perfil no se pregunta.
output = ejecutar("instalar-alumno.sh", ["--perfil", "DWEC"], [(b"Pulsa Enter", b"cancelar\n")])
assert b"Escribe 1 o 2" not in output
assert b"Perfil: DWEC" in output
print("OK: --perfil evita el menú: instalar-alumno.sh")

# Cancelar no debe cambiar el perfil recordado.
actual = perfil_guardado.read_bytes() if perfil_guardado.exists() else None
assert actual == perfil_previo, "la cancelación modificó el perfil recordado"

# Opción desconocida: mensaje claro, sin el bloque genérico de error.
proc = subprocess.run(["sh", str(root / "scripts" / "instalar-alumno.sh"), "--perfl", "dwec"],
                      stdin=subprocess.DEVNULL, capture_output=True)
assert proc.returncode == 2
assert b"opci\xc3\xb3n desconocida: --perfl" in proc.stderr
assert b"./scripts/instalar-alumno.sh" in proc.stderr
assert b"INCOMPLETA" not in proc.stderr
print("OK: opción desconocida con mensaje claro: instalar-alumno.sh")
