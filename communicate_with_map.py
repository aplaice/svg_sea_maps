#!/usr/bin/python3

import socketserver
import http.server
from http import HTTPStatus
import json

import signal
import sys

import datetime

# this avoids the noisy (and not really necessary) traceback

def signal_handler(signum, frame):
    server.server_close()
    sys.exit(0)
signal.signal(signal.SIGINT, signal_handler)

# https://docs.python.org/3.5/library/http.server.html
# https://docs.python.org/3.5/library/socketserver.html

map_data_filename = "map_data.json"

def round_widths_in_map_data(data, ndigits):
    for k in data:
        if "width" in data[k]:
            data[k]["width"] = round(data[k]["width"], ndigits)
    return data

class MyHandler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        if self.path == "/b4801f52-7f87-454a-9fd7-c6367b976fff/get_json":
            # could also just read the file as a bytestream ("rb") and
            # pass the contents directly to wfile, but it's nice to
            # make sure that the data is, indeed a dictionary, and
            # perhaps in the future I will want to do some processing
            # of the data.
            map_data_file = open(map_data_filename, "r")
            map_data = json.load(map_data_file)
            map_data_file.close()
            # print(self.headers)
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-type", "application/json")
            # https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS/Errors/CORSMissingAllowOrigin
            self.send_header("Access-Control-Allow-Origin", "null")
            reply = json.dumps(map_data).encode("utf-8")
            self.send_header("Content-Length", len(reply))
            self.end_headers()
            self.wfile.write(reply)

    def do_POST(self):
        if self.path == "/b4801f52-7f87-454a-9fd7-c6367b976fff/set_json":
            # print(self.headers)
            content_length = int(self.headers.get("Content-Length"))
            post_body = self.rfile.read(content_length)
            map_data = json.loads(post_body.decode("utf-8"))
            map_data = round_widths_in_map_data(map_data, 1)
            map_data_file = open(map_data_filename, "w")
            json.dump(map_data, map_data_file, sort_keys=True, indent=4)
            map_data_file.close()
            full_date = str(datetime.datetime.now()).replace(" ", "_")
            archive_filename = "old_map_data/" + full_date + ".json"
            archive_file = open(archive_filename, "w")
            # don't bother about pretty-printing
            json.dump(map_data, archive_file)
            archive_file.close()

# https://stackoverflow.com/questions/4465959/python-errno-98-address-already-in-use/4466035#4466035
socketserver.TCPServer.allow_reuse_address = True
server = socketserver.TCPServer(("localhost", 8123), MyHandler)


server.serve_forever()
server.server_close()
