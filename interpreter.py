"""
MIT License

Copyright (c) 2021 Tobias Enderle

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
"""

from code import InteractiveInterpreter, compile_command
import traceback
from io import StringIO
from contextlib import redirect_stdout, redirect_stderr
import socketserver
import json
import textwrap
from collections import defaultdict

class Interpreter(InteractiveInterpreter):
    def execute(self, code):
        with StringIO() as out, redirect_stdout(out), redirect_stderr(out):
            self.success = True
            try:
                code_obj = compile_command(code, symbol='exec')
                if code_obj is None:
                    print('Incomplete Python code:\n' + code)
                    self.success = False
                else:
                    self.runcode(code_obj)
            except:
                traceback.print_exc()
                self.success = False
            return self.success, out.getvalue()

    def showtraceback(self):
        super().showtraceback()
        self.success = False

class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        interpreters = defaultdict(Interpreter)
        while True:
            data = self.rfile.readline().decode('utf-8')
            if len(data) == 0:
                return

            data = json.loads(data)
            interpreter = interpreters[data['session']]
            success, output = interpreter.execute(textwrap.dedent(data['code']))
            response = { 'success': success, 'output': output }
            self.wfile.write((json.dumps(response) + '\n').encode('utf-8'))

if __name__ == '__main__':
    with socketserver.TCPServer(('localhost', 0), Handler) as server:
        print(server.server_address[1], end='\n', flush=True)  # publish port
        server.handle_request()
