"""Prueba consentimiento y repetición del PATH en hogares temporales."""
import os
import pty
import select
import subprocess
import tempfile
import time
from pathlib import Path
script = Path(__file__).resolve().parents[1] / 'scripts/configurar-path.sh'

def run(home, shell, answer):
    master, slave = pty.openpty()
    env = dict(os.environ, HOME=str(home), SHELL=shell)
    env.pop('ZDOTDIR', None)
    env.pop('XDG_CONFIG_HOME', None)
    proc = subprocess.Popen(['sh', str(script)], env=env, stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    output = b''
    try:
        until = time.monotonic() + 5
        while proc.poll() is None and time.monotonic() < until:
            if select.select([master], [], [], .1)[0]:
                try: output += os.read(master, 65536)
                except OSError: break
            if b'> ' in output and answer is not None:
                os.write(master, answer.encode() + b'\n')
                answer = None
        assert proc.wait(timeout=5) == 0, output
    finally:
        if proc.poll() is None: proc.kill(); proc.wait()
        os.close(master)
    return output

with tempfile.TemporaryDirectory(prefix='entorno-path-') as tmp:
    for shell, name in [('/bin/bash','.bashrc'),('/bin/zsh','.zshrc'),('/bin/fish','.config/fish/conf.d/entorno-dev-path.fish')]:
        home = Path(tmp) / Path(shell).name
        home.mkdir()
        target = home / name
        run(home, shell, 'n')
        assert not target.exists()
        run(home, shell, 's')
        text = target.read_text()
        assert '# entorno-nvim:' in text
        run(home, shell, None)
        assert target.read_text() == text
        print('OK: consentimiento y sin duplicados:', shell)
