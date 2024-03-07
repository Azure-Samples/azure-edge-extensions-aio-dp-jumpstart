from http.server import SimpleHTTPRequestHandler
from socketserver import TCPServer
import json

class JSONFileServer(SimpleHTTPRequestHandler):
    def do_GET(self):
        # Specify the JSON file you want to read
        json_file_path = 'reference-data.json'
        
        try:
            # Open the JSON file and parse its content
            with open(json_file_path, 'r') as json_file:
                json_content = json.load(json_file)
            
            # Send a response header
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            # Send the JSON content as the response
            self.wfile.write(json.dumps(json_content).encode('utf-8'))
        
        except FileNotFoundError:
            # If the file is not found, send a 404 error
            self.send_error(404, 'File Not Found: {}'.format(json_file_path))

if __name__ == '__main__':
    # Specify the server address and port
    server_address = ('', 8001)
    
    # Create and run the HTTP server
    with TCPServer(server_address, JSONFileServer) as httpd:
        print('Server listening on port 8001...')
        httpd.serve_forever()
