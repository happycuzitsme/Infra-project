#!/usr/bin/env python3
"""
Simple HTTP Health Service for Infrastructure Assignment
Responds with 200 OK on /health endpoint
"""
import os
import sys
from http.server import HTTPServer,BaseHTTPRequestHandler

#Read configuration from environment file
PORT= int(os.getenv('PORT',8080))
LOG_DIR= os.getenv('LOG_DIR','/var/log/infra-demo')

class HealthHandler(BaseHTTPRequestHandler):
    """Handle HTTP requests -only respond to /health"""
    def log_message(self,format,*args):
        """Override to use our log directory"""
        with open(f"{LOG_DIR}/access.log","a")as f:
            f.write(f"{self.address_string()}-{format%args}\n")

    def do_GET(self):
        if self.path=='/health':
            self.send_response(200)
            self.send_header('Content-type','text/plain')
            self.send_header('X-Service',"infra-demo")
            self.end_headers()
            self.wfile.write(b'OK')
            print(f"Health check OK from {self.client_address[0]}")
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')

    def do_HEAD(self):
        """Support HEAD requests for health checks"""
        if self.path=='/health':
            self.send_response(200)
            self.send_header('Content-type','text/plain')
            self.end_headers()
def main():
    """Start the HTTP Server"""
    print(f"Starting Health Service on port{PORT}")
    print(f"Logs directory:{LOG_DIR}")
    print(f"Health endpoint: http://localhost:{PORT}/health")

    server=HTTPServer(('0.0.0.0',PORT),HealthHandler)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down gracefully...")
        server.shutdown()
        sys.exit(0)

if __name__=='__main__':
    main()
