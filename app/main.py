"""
Entrypoint for example python API application.
"""
import socket
from fastapi import FastAPI

app = FastAPI()


@app.get("/-/health")
async def health():
    """
    Healthcheck endpoint, serves status as well as some diagnostics (debug) data.
    :return:
    """

    def get_debug_info():
        hostname = socket.gethostname()
        return {
            "hostname": hostname,
            "ip": socket.gethostbyname(hostname),
        }

    return {"status": "ok", "debug": get_debug_info()}


@app.get("/api/echo")
async def echo(text: str):
    """
    Echo endpoint. Returns back whatever is sent.
    :param text: Text that is echoed back.
    :return:
    """
    return {"text": text}
