from flask import Flask, jsonify, request
import random
import time

app = Flask(__name__)

# Global variable to control chaos endpoint behavior
IsChaosEnabled = False

@app.route('/', methods=['GET'])
def index():
    """Standard application response."""
    return jsonify({"message": "Hello from world!"})

@app.route('/chaos', methods=['GET'])
def chaos():
    """Endpoint to trigger a health-check failure scenario."""
    global IsChaosEnabled
    IsChaosEnabled = not IsChaosEnabled  # Toggle the chaos state

    if IsChaosEnabled:
        return jsonify({"message": "Chaos mode activated!"}), 500  # Simulate failure
    else:
        return jsonify({"message": "Chaos mode deactivated!"})

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint. Return 200 if healthy, 500 if chaotic."""
    if IsChaosEnabled:
        return jsonify({"status": "unhealthy"}), 500
    else:
        return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)