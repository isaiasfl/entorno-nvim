"""Verifica la pausa interactiva sin iniciar descargas ni instalaciones."""
import os
import pty
import select
import subprocess
import time
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text().strip().encode()
for script, args in [("instalar.sh", []), ("instalar-alumno.sh", ["--perfil", "dwec"])]:
    master, slave = pty.openpty()
    proc = subprocess.Popen(["sh", str(root / "scripts" / script), *args],
                            stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output = b""
    try:
        deadline = time.monotonic() + 5
        while b"Pulse Enter" not in output and time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                output += os.read(master, 65536)
        assert b"Pulse Enter" in output, (script, output)
        assert b"v" + version in output, (script, output)
        assert b"ANTES DE COMENZAR" in output
        assert b"--sistema" in output
        assert b"MODO LOCAL" in output
        assert b"no autoriza sudo" in output
        os.write(master, b"cancelar\n")
        assert proc.wait(timeout=5) == 0
    finally:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=5)
        os.close(master)
    print("OK: versión, plan y pausa; cancelación sin instalar:", script)
