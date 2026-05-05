import argparse
import queue
import threading
import tkinter as tk

import serial


WIDTH = 128
HEIGHT = 64
HEADER = b"\x55\xAA\x80\x40"
FRAME_SIZE = 1024


def read_exact(port, size):
    buf = bytearray()
    while len(buf) < size:
        chunk = port.read(size - len(buf))
        if not chunk:
            return None
        buf.extend(chunk)
    return bytes(buf)


def serial_reader(port_name, baud_rate, frame_queue, status_queue, stop_event):
    try:
        with serial.Serial(port_name, baud_rate, timeout=1) as port:
            status_queue.put(f"Connected: {port_name} @ {baud_rate}")
            match_index = 0
            frame_count = 0
            while not stop_event.is_set():
                byte = port.read(1)
                if not byte:
                    continue

                if byte[0] == HEADER[match_index]:
                    match_index += 1
                    if match_index == len(HEADER):
                        frame = read_exact(port, FRAME_SIZE)
                        match_index = 0
                        if frame is not None:
                            frame_count += 1
                            if frame_queue.full():
                                try:
                                    frame_queue.get_nowait()
                                except queue.Empty:
                                    pass
                            frame_queue.put(frame)
                            status_queue.put(f"Connected: {port_name} @ {baud_rate} | frames: {frame_count}")
                else:
                    match_index = 1 if byte[0] == HEADER[0] else 0
    except Exception as exc:
        status_queue.put(f"Serial error: {exc}")


def draw_frame(canvas, frame, scale):
    canvas.delete("all")
    for y in range(HEIGHT):
        page = (y >> 3) * WIDTH
        mask = 1 << (y & 7)
        y0 = y * scale
        y1 = y0 + scale
        for x in range(WIDTH):
            if frame[page + x] & mask:
                x0 = x * scale
                x1 = x0 + scale
                canvas.create_rectangle(x0, y0, x1, y1, outline="", fill="white")


def main():
    parser = argparse.ArgumentParser(description="Basys 3 Lode Runner UART viewer")
    parser.add_argument("--port", required=True, help="Serial port, for example COM5")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate")
    parser.add_argument("--scale", type=int, default=4, help="Window scale")
    args = parser.parse_args()

    root = tk.Tk()
    root.title(f"Lode Runner UART Viewer - {args.port}")
    root.configure(bg="black")

    status_var = tk.StringVar(value="Connecting...")
    status_label = tk.Label(root, textvariable=status_var, anchor="w", bg="black", fg="white")
    status_label.pack(fill="x")

    canvas = tk.Canvas(
        root,
        width=WIDTH * args.scale,
        height=HEIGHT * args.scale,
        bg="black",
        bd=0,
        highlightthickness=0,
    )
    canvas.pack()

    frame_queue = queue.Queue(maxsize=1)
    status_queue = queue.Queue()
    stop_event = threading.Event()

    worker = threading.Thread(
        target=serial_reader,
        args=(args.port, args.baud, frame_queue, status_queue, stop_event),
        daemon=True,
    )
    worker.start()

    def poll():
        try:
            while True:
                status_var.set(status_queue.get_nowait())
        except queue.Empty:
            pass

        try:
            frame = frame_queue.get_nowait()
            draw_frame(canvas, frame, args.scale)
        except queue.Empty:
            pass

        root.after(15, poll)

    def on_close():
        stop_event.set()
        root.destroy()

    root.protocol("WM_DELETE_WINDOW", on_close)
    root.after(15, poll)
    root.mainloop()


if __name__ == "__main__":
    main()
