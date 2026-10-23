#!/usr/bin/env python3
"""Download a file over several ranged connections, resuming each chunk after drops.

Usage: fetch.py URL DEST
Partial chunks live in DEST.parts/ until every chunk is complete.
"""
import os, sys, threading, time, urllib.request

CHUNK = 16 << 20
CONNECTIONS = 8


def size_of(url):
    # Retried like the chunks: proxies in Iran fail some requests at random.
    for attempt in range(20):
        try:
            req = urllib.request.Request(url, method="HEAD")
            with urllib.request.urlopen(req, timeout=30) as r:
                return int(r.headers["Content-Length"])
        except OSError:
            time.sleep(2)
    sys.exit(f"could not reach {url}")


def get_chunk(url, path, start, end):
    # ponytail: retries forever; a dead server keeps retrying until Ctrl-C.
    while True:
        have = os.path.getsize(path) if os.path.exists(path) else 0
        if start + have > end:
            return
        req = urllib.request.Request(url, headers={"Range": f"bytes={start + have}-{end}"})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                if r.status != 206:  # a server ignoring Range would fill every chunk with the whole file
                    sys.exit(f"{url} does not support ranged downloads")
                with open(path, "ab") as f:
                    while block := r.read(1 << 16):
                        f.write(block)
        except OSError:
            time.sleep(2)


def main(url, dest):
    total = size_of(url)
    parts = dest + ".parts"
    os.makedirs(parts, exist_ok=True)
    ranges = [(i, min(i + CHUNK, total) - 1) for i in range(0, total, CHUNK)]
    # Daemon threads so Ctrl-C stops the download; at most CONNECTIONS chunks run at once.
    slots = threading.Semaphore(CONNECTIONS)

    def worker(start, end):
        with slots:
            get_chunk(url, f"{parts}/{start:012d}", start, end)

    threads = [threading.Thread(target=worker, args=r, daemon=True) for r in ranges]
    for t in threads:
        t.start()
    while any(t.is_alive() for t in threads):
        done = sum(os.path.getsize(os.path.join(parts, p)) for p in os.listdir(parts))
        print(f"\r{done >> 20}/{total >> 20} MB", end="", flush=True)
        time.sleep(5)
    with open(dest, "wb") as out:
        for s, _ in ranges:
            with open(f"{parts}/{s:012d}", "rb") as f:
                out.write(f.read())
    for p in os.listdir(parts):
        os.remove(os.path.join(parts, p))
    os.rmdir(parts)
    print(f"\r{total >> 20}/{total >> 20} MB")


if __name__ == "__main__":
    main(*sys.argv[1:3])
