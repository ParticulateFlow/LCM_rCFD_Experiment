import socket

def getDataFromStream(host: str, port: int) -> dict:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, port))
        header,data = s.recv(1024).decode().split(';')
        header = header.split(',')
        data = data.split(',')

        entry = dict(zip(header, data))

        # data type conversion
        for k,v in entry.items():
            try:
                if k == 'stirrerRPM': entry[k] = int(v)
                elif k == 'stirrerState' or k=='byPass': entry[k] = bool(int(v))
                else: entry[k] = float(v)
            except:
                entry[k] = v

        return entry
    
if __name__ == '__main__':
    HOST = "127.0.0.1"  # The server's hostname or IP address
    PORT = 4000  # The port used by the server
    data = getDataFromStream(host=HOST, port=PORT)
    print(data)


