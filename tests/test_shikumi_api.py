import asyncio
import os
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "app"))
import shikumi_api  # noqa: E402
import loadgen  # noqa: E402

APP = Path(__file__).resolve().parents[1] / "app" / "shikumi_api.py"


def stop(proc):
    if proc.poll() is None:
        proc.kill()
    proc.wait()
    proc.stdout.close()


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class RouteTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        Path(self.tmp.name, "hello.txt").write_text("hello\n")
        args = shikumi_api.parse_args(["--data-dir", self.tmp.name,
                                       "--cache-dir", self.tmp.name + "/cache"])
        self.app = shikumi_api.App(args)

    def tearDown(self):
        self.tmp.cleanup()
        while shikumi_api.HELD_FILES:
            shikumi_api.HELD_FILES.pop().close()

    def route(self, path, query=""):
        return asyncio.run(self.app.route(path, query))

    def test_healthz(self):
        self.assertEqual(self.route("/healthz")[0], 200)

    def test_unknown_path(self):
        self.assertEqual(self.route("/nope")[0], 404)

    def test_data_reads_file(self):
        status, body = self.route("/data", "name=hello.txt")
        self.assertEqual((status, body["content"]), (200, "hello\n"))

    def test_data_rejects_traversal(self):
        self.assertEqual(self.route("/data", "name=../../etc/passwd")[0], 400)

    def test_data_cache_writes_file(self):
        self.app.args.cache = True
        self.route("/data", "name=hello.txt")
        self.assertTrue(Path(self.tmp.name, "cache", "hello.txt.cache").exists())

    def test_files_holds_descriptors(self):
        before = len(shikumi_api.HELD_FILES)
        self.route("/files", "n=3")
        self.assertEqual(len(shikumi_api.HELD_FILES), before + 3)

    def test_checksums_agree(self):
        data = os.urandom(4096)
        self.assertEqual(shikumi_api.slow_checksum(data), shikumi_api.fast_checksum(data))


class ServerTests(unittest.TestCase):
    """Run the real script, talk to it over TCP, then stop it with SIGTERM."""

    def start(self, *extra):
        port = free_port()
        proc = subprocess.Popen([sys.executable, str(APP), "--port", str(port),
                                 "--data-dir", tempfile.gettempdir(), *extra],
                                stdout=subprocess.PIPE, text=True)
        self.assertIn("listening", proc.stdout.readline())
        self.addCleanup(stop, proc)
        return proc, f"http://127.0.0.1:{port}"

    def get(self, url, timeout=5):
        return asyncio.run(loadgen.get(url, timeout))

    def test_healthz_over_tcp(self):
        _, base = self.start()
        status, body = self.get(base + "/healthz")
        self.assertEqual(status, 200)
        self.assertIn(b'"status": "ok"', body)

    def test_bad_query_returns_400(self):
        _, base = self.start()
        self.assertEqual(self.get(base + "/slow?ms=abc")[0], 400)

    def test_sigterm_lets_in_flight_request_finish(self):
        proc, base = self.start()

        async def scenario():
            task = asyncio.create_task(loadgen.get(base + "/slow?ms=700", 5))
            await asyncio.sleep(0.2)
            proc.send_signal(signal.SIGTERM)
            return await task

        status, _ = asyncio.run(scenario())
        self.assertEqual(status, 200)
        self.assertEqual(proc.wait(timeout=5), 0)

    def test_reuseport_allows_two_listeners(self):
        port = free_port()
        procs = []
        for _ in range(2):
            p = subprocess.Popen([sys.executable, str(APP), "--port", str(port), "--reuseport"],
                                 stdout=subprocess.PIPE, text=True)
            self.addCleanup(stop, p)
            self.assertIn("listening", p.stdout.readline())
            procs.append(p)
        time.sleep(0.1)
        self.assertTrue(all(p.poll() is None for p in procs))


if __name__ == "__main__":
    unittest.main()
