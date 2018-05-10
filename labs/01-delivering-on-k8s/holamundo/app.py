#!/usr/bin/python

import os, math
from flask import Flask, request
app = Flask(__name__)

@app.route('/hola')
def hello():
    version = os.environ.get('SERVICE_VERSION')

    # do some cpu intensive computation
    x = 0.0001
    for i in range(0, 1000000):
	    x = x + math.sqrt(x)

    return 'HolaMundo microservice version: %s, instancia: %s\n' % (version, os.environ.get('HOSTNAME'))

@app.route('/salud')
def health():
    return 'HolaMundo microservice es operativo', 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', threaded=True)
